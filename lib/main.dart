import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Camera',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isTorchOn = false;
  bool _isProcessing = false;
  double _lightLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _checkLightLevel();
  }

  void _checkLightLevel() {
    // 模拟光线检测
    setState(() {
      _lightLevel = 0.5; // 示例值
      _isTorchOn = _lightLevel < 0.3;
    });
  }

  void _takePicture() async {
    setState(() {
      _isProcessing = true;
    });

    // 模拟拍照过程
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Camera'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Camera Preview',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Light Level: ${(_lightLevel * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _takePicture,
                  icon: const Icon(Icons.camera),
                  label: Text(_isProcessing ? 'Processing...' : 'Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
