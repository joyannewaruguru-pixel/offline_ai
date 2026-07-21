import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../db_service.dart';
import 'db_service.dart';

class DocumentChunk {
  final String id;
  final String docId;
  final String docName;
  final int chunkIndex;
  final String text;
  final List<double> embedding;

  DocumentChunk({
    required this.id, required this.docId, required this.docName,
    required this.chunkIndex, required this.text, required this.embedding,
  });

  Map<String,dynamic> toMap() => {
    'id': id, 'doc_id': docId, 'doc_name': docName,
    'chunk_index': chunkIndex, 'text': text,
    'embedding': jsonEncode(embedding),
  };

  factory DocumentChunk.fromMap(Map<String,dynamic> m) => DocumentChunk(
    id: m['id'] as String, docId: m['doc_id'] as String,
    docName: m['doc_name'] as String, chunkIndex: m['chunk_index'] as int,
    text: m['text'] as String,
    embedding: (jsonDecode(m['embedding'] as String) as List)
        .map((e) => (e as num).toDouble()).toList(),
  );
}

class RagService {
  RagService._();
  static final RagService instance = RagService._();

  static const _apiKey   = 'YOUR_API_KEY_HERE';
  static const _chunkSize = 400;
  static const _overlap   = 80;
  static const _topK       = 3;

  List<String> splitIntoChunks(String text) {
    final words  = text.split(RegExp(r'\s+'));
    final chunks = <String>[];
    int i = 0;
    while (i < words.length) {
      final end   = min(i + _chunkSize, words.length);
      chunks.add(words.sublist(i, end).join(' '));
      i += _chunkSize - _overlap;
    }
    return chunks;
  }

  List<double> _localEmbedding(String text) {
    final bytes = utf8.encode(text.toLowerCase());
    final hash  = sha256.convert(bytes).bytes;
    final dim   = 64;
    return List.generate(dim, (i) {
      final val = ((hash[i % hash.length] + i * 7) % 256) / 255.0;
      return val - 0.5;
    });
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot   += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom == 0 ? 0 : dot / denom;
  }

  Future<String> ingestText(String docName, String text, String userEmail) async {
    final docId = md5.convert(utf8.encode('$docName${DateTime.now()}')).toString();
    final chunks = splitIntoChunks(text);

    await DBService.instance.insertRagDocument({
      'id': docId, 'name': docName, 'source': 'text',
      'chunk_count': chunks.length,
      'created_at': DateTime.now().toIso8601String(),
      'user_email': userEmail,
    });

    for (int i = 0; i < chunks.length; i++) {
      final chunkId = '$docId-$i';
      final emb = _localEmbedding(chunks[i]);
      await DBService.instance.insertRagChunk(DocumentChunk(
        id: chunkId, docId: docId, docName: docName,
        chunkIndex: i, text: chunks[i], embedding: emb,
      ).toMap());
    }
    await DBService.instance.logActivity(userEmail, 'RAG_INGEST',
        'Ingested $docName (${chunks.length} chunks)');
    return docId;
  }

  Future<List<DocumentChunk>> retrieveRelevant(String query, {String? docId}) async {
    final allRows = docId != null
        ? await DBService.instance.getRagChunks(docId)
        : await DBService.instance.getAllRagChunks();

    if (allRows.isEmpty) return [];
    final qEmb    = _localEmbedding(query);
    final scored  = allRows.map((r) {
      final chunk = DocumentChunk.fromMap(r);
      final score = _cosineSimilarity(qEmb, chunk.embedding);
      return (chunk, score);
    }).toList();
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(_topK).map((e) => e.$1).toList();
  }

  Future<String> generateAnswer(String query, List<DocumentChunk> chunks) async {
    final context = chunks.map((c) => c.text).join('\n\n---\n\n');
    final prompt  =
        'You are a helpful AI tutor for BIT4107 Mobile App Development.\n'
        'Answer the question using ONLY the context provided.\n'
        'If the answer is not in the context, say "I don\'t have that in my notes."\n\n'
        'Context:\n$context\n\nQuestion: $query\n\nAnswer:';
    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 600,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return jsonDecode(res.body)['content'][0]['text'] as String;
      }
      return _offlineAnswer(query, chunks);
    } catch (_) {
      return _offlineAnswer(query, chunks);
    }
  }

  String _offlineAnswer(String query, List<DocumentChunk> chunks) {
    if (chunks.isEmpty) return 'No relevant content found in your notes.';
    final q = query.toLowerCase();
    for (final c in chunks) {
      final sentences = c.text.split(RegExp(r'(?<=[.!?])\s+'));
      for (final s in sentences) {
        final words = q.split(' ').where((w) => w.length > 3);
        if (words.any((w) => s.toLowerCase().contains(w))) {
          return '[Offline] From your notes: ${s.trim()}';
        }
      }
    }
    return '[Offline] Most relevant excerpt:\n\n${chunks.first.text.substring(0, min(300, chunks.first.text.length))}...';
  }

  Future<String> askQuestion(String query, {String? docId, String email = ''}) async {
    final chunks = await retrieveRelevant(query, docId: docId);
    if (email.isNotEmpty) {
      await DBService.instance.logActivity(email, 'RAG_QUERY', query);
    }
    return generateAnswer(query, chunks);
  }
}