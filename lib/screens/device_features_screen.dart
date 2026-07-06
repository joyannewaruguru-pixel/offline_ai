import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceFeaturesScreen extends StatefulWidget {
  const DeviceFeaturesScreen({super.key});

  @override
  State<DeviceFeaturesScreen> createState() => _DeviceFeaturesState();
}

class _DeviceFeaturesState extends State<DeviceFeaturesScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const _green      = Color(0xFF1D9E75);
  static const _greenLight = Color(0xFFE1F5EE);
  static const _greenDark  = Color(0xFF0F6E56);
  static const _blue       = Color(0xFF1565C0);
  static const _blueLight  = Color(0xFFE3F2FD);
  static const _purple     = Color(0xFF6A1B9A);
  static const _purpleLight= Color(0xFFF3E5F5);
  static const _muted      = Color(0xFF6B7280);

  // ── Camera State ────────────────────────────────────────────────────────
  File? _image;
  final _picker = ImagePicker();

  // ── GPS State ───────────────────────────────────────────────────────────
  Position? _position;
  bool _loadingLocation = false;

  // ── Sensors State ───────────────────────────────────────────────────────
  AccelerometerEvent? _accel;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEventStream().listen((event) {
      setState(() => _accel = event);
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  // ── Camera Action ────────────────────────────────────────────────────────
  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) setState(() => _image = File(photo.path));
    } else {
      _showSnack('Camera permission denied');
    }
  }

  // ── GPS Action ───────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _position = pos);
      } else {
        _showSnack('Location permission denied');
      }
    } catch (e) {
      _showSnack('Error getting location: $e');
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Features'),
        backgroundColor: _green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── 1. CAMERA ─────────────────────────────────────────────────────
          _sectionHeader('1. Camera Integration', Icons.camera_alt_outlined, _green),
          const SizedBox(height: 12),
          Center(
            child: Column(children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _green.withValues(alpha: 0.2)),
                  image: _image != null 
                    ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                    : null,
                ),
                child: _image == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 48, color: _muted),
                        Text('No photo captured', style: TextStyle(color: _muted)),
                      ],
                    )
                  : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Capture Photo'),
                style: ElevatedButton.styleFrom(backgroundColor: _green),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── 2. GPS ────────────────────────────────────────────────────────
          _sectionHeader('2. GPS / Location', Icons.location_on_outlined, _blue),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blue.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              if (_loadingLocation)
                const CircularProgressIndicator()
              else if (_position != null)
                Column(children: [
                  _infoRow('Latitude', _position!.latitude.toStringAsFixed(6)),
                  _infoRow('Longitude', _position!.longitude.toStringAsFixed(6)),
                  _infoRow('Altitude', '${_position!.altitude.toStringAsFixed(1)} m'),
                ])
              else
                const Text('No location data obtained', style: TextStyle(color: _muted)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
                style: ElevatedButton.styleFrom(backgroundColor: _blue),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── 3. SENSORS ────────────────────────────────────────────────────
          _sectionHeader('3. Sensors (Accelerometer)', Icons.speed_outlined, _purple),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _purple.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              if (_accel != null)
                Column(children: [
                  _infoRow('X Axis', _accel!.x.toStringAsFixed(2)),
                  _infoRow('Y Axis', _accel!.y.toStringAsFixed(2)),
                  _infoRow('Z Axis', _accel!.z.toStringAsFixed(2)),
                ])
              else
                const Text('Waiting for sensor data...', style: TextStyle(color: _muted)),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
