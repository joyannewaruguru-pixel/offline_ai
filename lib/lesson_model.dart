class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String aiSummary;
  final int readMinutes;
  final double progress;
  final QuizQuestion? quiz;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.aiSummary,
    required this.readMinutes,
    required this.progress,
    this.quiz,
  });

  /// Fallback used when no lesson is found in the database
  factory Lesson.sample() => const Lesson(
    id: 'week3_lesson2',
    title: 'Flutter Widgets',
    subtitle: 'Week 3 · Lesson 2',
    readMinutes: 3,
    progress: 0.6,
    aiSummary:
    'Think of StatelessWidget as a printed photo — it never changes. '
        'StatefulWidget is like a live video feed — it rebuilds whenever '
        'setState() is called.',
    content: '''
## Stateless vs Stateful Widgets

Every piece of UI in Flutter is a **widget**. There are two main types.

### StatelessWidget

A `StatelessWidget` builds once and never rebuilds on its own. Use it for
fixed content — labels, icons, profile pictures, or cards showing static data.

```dart
class GreetingCard extends StatelessWidget {
  final String name;
  const GreetingCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text('Hello, \$name!');
  }
}
```

### StatefulWidget

A `StatefulWidget` can call `setState()` to trigger a rebuild whenever
its data changes. Use it for forms, toggles, counters, or anything interactive.

```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => setState(() => _count++),
      child: Text('Tapped \$_count times'),
    );
  }
}
```

**Rule of thumb:** start with `StatelessWidget`. Only switch to
`StatefulWidget` when the widget needs to change after it is first drawn.
''',
    quiz: QuizQuestion(
      question:
      'Which widget would you use for a login button that shows a '
          'loading spinner while waiting for a server response?',
      options: [
        'StatelessWidget',
        'StatefulWidget',
        'InheritedWidget',
      ],
      correctIndex: 1,
      explanation:
      'The button needs to swap between "Sign In" text and a spinner, '
          'so it must call setState() — that requires a StatefulWidget.',
    ),
  );
}