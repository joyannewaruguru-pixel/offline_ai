import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth_service.dart';
import '../db_service.dart';

class DeviceFeaturesScreen extends StatefulWidget {
  const DeviceFeaturesScreen({super.key});
  @override
  State<DeviceFeaturesScreen> createState() => _DeviceFeaturesState();
}

class _DeviceFeaturesState extends State<DeviceFeaturesScreen>
    with SingleTickerProviderStateMixin {
  static const _green       = Color(0xFF1D9E75);
  static const _greenLight  = Color(0xFFE1F5EE);
  static const _greenDark   = Color(0xFF0F6E56);
  static const _blue        = Color(0xFF1565C0);
  static const _blueLight   = Color(0xFFE3F2FD);
  static const _purple      = Color(0xFF6A1B9A);
  static const _purpleLight = Color(0xFFF3E5F5);
  static const _amber       = Color(0xFFEF9F27);
  static const _amberLight  = Color(0xFFFAEEDA);
  static const _error       = Color(0xFFE24B4A);
  static const _muted       = Color(0xFF6B7280);

  late TabController _tabs;
  final _picker = ImagePicker();

  File?   _capturedDoc;
  File?   _facePhoto;
  bool    _docLoading  = false;
  bool    _faceLoading = false;
  String? _docStatus;
  String? _faceStatus;
  bool    _docSaved  = false;
  bool    _faceSaved = false;

  List<Map<String,dynamic>> _savedDocs = [];

  double? _lat;
  double? _lng;
  double? _accuracy;
  bool    _gpsLoading = false;
  String? _gpsError;

  double _accelX = 0, _accelY = 0, _accelZ = 0;
  bool   _sensorsRead = false;
  bool   _sensorLoading = false;

  final Map<String,bool> _perms = {
    'CAMERA': false,
    'LOCATION': false,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _checkInitialPermissions();
    _loadSavedDocs();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _checkInitialPermissions() async {
    final cam = await Permission.camera.isGranted;
    final loc = await Permission.location.isGranted;
    if (mounted) setState(() { _perms['CAMERA'] = cam; _perms['LOCATION'] = loc; });
  }

  Future<void> _loadSavedDocs() async {
    final email = context.read<AuthService>().email;
    final docs = await DBService.instance.getCapturedDocuments(email);
    if (mounted) setState(() => _savedDocs = docs);
  }

  Future<void> _captureDocument() async {
    if (!await Permission.camera.request().isGranted) return;
    setState(() { _docLoading = true; _docStatus = null; _docSaved = false; });
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) { if (mounted) setState(() => _docLoading = false); return; }

      final dir      = await getApplicationDocumentsDirectory();
      final ts       = DateTime.now().millisecondsSinceEpoch;
      final savePath = '${dir.path}/doc_$ts.jpg';
      final saved    = await File(file.path).copy(savePath);

      final email = context.read<AuthService>().email;
      await DBService.instance.saveCapturedDocument(email, savePath, 'Document $ts', 'document');
      await DBService.instance.logActivity(email, 'CAMERA', 'Document photo captured');

      await _loadSavedDocs();
      if (mounted) {
        setState(() {
          _capturedDoc = saved;
          _docSaved    = true;
          _docStatus   = 'Saved to local storage';
          _docLoading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _docStatus = 'Error: $e'; _docLoading = false; });
    }
  }

  Future<void> _captureFaceId() async {
    if (!await Permission.camera.request().isGranted) return;
    setState(() { _faceLoading = true; _faceStatus = null; _faceSaved = false; });
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
      if (file == null) { if (mounted) setState(() => _faceLoading = false); return; }

      final dir      = await getApplicationDocumentsDirectory();
      final ts       = DateTime.now().millisecondsSinceEpoch;
      final savePath = '${dir.path}/face_$ts.jpg';
      final saved    = await File(file.path).copy(savePath);

      final email = context.read<AuthService>().email;
      await DBService.instance.saveFaceIdPath(email, savePath);
      await DBService.instance.saveCapturedDocument(email, savePath, 'Face ID $ts', 'face_id');
      await DBService.instance.logActivity(email, 'FACE_ID', 'Face ID captured');

      await _loadSavedDocs();
      if (mounted) {
        setState(() {
          _facePhoto   = saved;
          _faceSaved   = true;
          _faceStatus  = 'Saved to profile';
          _faceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _faceStatus = 'Error: $e'; _faceLoading = false; });
    }
  }

  Future<void> _getLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return;

    setState(() { _gpsLoading = true; _gpsError = null; });
    try {
      final pos = await Geolocator.getCurrentPosition();
      final email = context.read<AuthService>().email;
      await DBService.instance.logActivity(email, 'GPS', 'Location acquired');
      if (mounted) {
        setState(() {
          _lat = pos.latitude; _lng = pos.longitude; _accuracy = pos.accuracy;
          _gpsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _gpsError = 'GPS error: $e'; _gpsLoading = false; });
    }
  }

  Future<void> _readSensors() async {
    setState(() => _sensorLoading = true);
    final event = await accelerometerEventStream().first;
    final email = context.read<AuthService>().email;
    await DBService.instance.logActivity(email, 'SENSOR', 'Accelerometer read');
    if (mounted) {
      setState(() {
        _accelX = event.x; _accelY = event.y; _accelZ = event.z;
        _sensorsRead = true; _sensorLoading = false;
      });
    }
  }

  Future<void> _deleteDoc(int id, String path) async {
    await DBService.instance.deleteCapturedDocument(id);
    try { File(path).deleteSync(); } catch (_) {}
    _loadSavedDocs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Device Features', style: TextStyle(color: Colors.white, fontSize: 15)),
          Text('Camera, GPS & Sensors', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
        bottom: TabBar(controller: _tabs, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.lock_outline, size: 16), text: 'Perms'),
            Tab(icon: Icon(Icons.camera_alt_outlined, size: 16), text: 'Cam'),
            Tab(icon: Icon(Icons.location_on_outlined, size: 16), text: 'GPS'),
            Tab(icon: Icon(Icons.sensors_outlined, size: 16), text: 'Sens'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _permissionsTab(isDark),
        _cameraTab(isDark),
        _gpsTab(isDark),
        _sensorsTab(isDark),
      ]),
    );
  }

  Widget _permissionsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(icon: Icons.info_outline, title: 'Runtime Permissions', body: 'Grant permissions to use device features.', color: _amber, lightColor: _amberLight, isDark: isDark),
        const SizedBox(height: 14),
        _permTile('CAMERA', Icons.camera_alt_outlined, _blue, _blueLight, isDark),
        _permTile('LOCATION', Icons.location_on_outlined, _green, _greenLight, isDark),
      ],
    );
  }

  Widget _permTile(String key, IconData icon, Color color, Color light, bool isDark) {
    final granted = _perms[key] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: granted ? light : (isDark ? const Color(0xFF1C1F26) : Colors.white), borderRadius: BorderRadius.circular(14), border: Border.all(color: granted ? color : const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600))),
        Switch(value: granted, activeThumbColor: color, onChanged: (v) async {
          final status = key == 'CAMERA' ? await Permission.camera.request() : await Permission.location.request();
          setState(() => _perms[key] = status.isGranted);
        }),
      ]),
    );
  }

  Widget _cameraTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _ActionCard(icon: Icons.document_scanner_outlined, label: 'Scan Doc', sublabel: 'Rear', color: _blue, lightColor: _blueLight, isDark: isDark, loading: _docLoading, onTap: _captureDocument)),
          const SizedBox(width: 10),
          Expanded(child: _ActionCard(icon: Icons.face_outlined, label: 'Face ID', sublabel: 'Front', color: _purple, lightColor: _purpleLight, isDark: isDark, loading: _faceLoading, onTap: _captureFaceId)),
        ]),
        const SizedBox(height: 12),
        if (_capturedDoc != null || _facePhoto != null)
          Row(children: [
            if (_capturedDoc != null) Expanded(child: _PhotoPreview(file: _capturedDoc!, label: 'Doc', status: _docStatus, saved: _docSaved, color: _blue)),
            if (_facePhoto != null) Expanded(child: _PhotoPreview(file: _facePhoto!, label: 'Face', status: _faceStatus, saved: _faceSaved, color: _purple)),
          ]),
        const SizedBox(height: 14),
        ..._savedDocs.map((doc) => Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1F26) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(doc['image_path']), width: 50, height: 50, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(child: Text(doc['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            IconButton(icon: const Icon(Icons.delete_outline, color: _error), onPressed: () => _deleteDoc(doc['id'], doc['image_path'])),
          ]),
        )),
      ],
    );
  }

  Widget _gpsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1F26) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _lat != null ? _green : const Color(0xFFE5E7EB))),
          child: _gpsLoading ? const Center(child: CircularProgressIndicator()) : _lat != null ? Column(children: [
            _CoordRow('Lat', _lat!.toStringAsFixed(6)), _CoordRow('Lng', _lng!.toStringAsFixed(6)),
          ]) : const Center(child: Text('No location data')),
        ),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: _getLocation, child: const Text('Get Location')),
      ],
    );
  }

  Widget _sensorsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_sensorsRead) Column(children: [
          _SensorCard('Accel', _accelX, _accelY, _accelZ, _blue, _blueLight),
        ]) else const Center(child: Text('Tap to read')),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: _readSensors, child: const Text('Read Sensors')),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label, sublabel; final Color color, lightColor; final bool isDark, loading; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.sublabel, required this.color, required this.lightColor, required this.isDark, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1F26) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(children: [Icon(icon, color: color, size: 30), Text(label, style: const TextStyle(fontSize: 12))])));
}

class _PhotoPreview extends StatelessWidget {
  final File file; final String label; final String? status; final bool saved; final Color color;
  const _PhotoPreview({required this.file, required this.label, required this.status, required this.saved, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, height: 100, fit: BoxFit.cover)), Text(status ?? '')]);
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String title, body; final Color color, lightColor; final bool isDark;
  const _InfoCard({required this.icon, required this.title, required this.body, required this.color, required this.lightColor, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Text(body));
}

class _CoordRow extends StatelessWidget {
  final String label, value;
  const _CoordRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [Text(label), const Spacer(), Text(value)]);
}

class _SensorCard extends StatelessWidget {
  final String name; final double x, y, z; final Color color, light;
  const _SensorCard(this.name, this.x, this.y, this.z, this.color, this.light);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), child: Text('$name: $x, $y, $z'));
}
