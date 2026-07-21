import 'package:flutter/material.dart';

class GestureDemoScreen extends StatefulWidget {
  const GestureDemoScreen({super.key});
  @override
  State<GestureDemoScreen> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemoScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Demo')));
}
