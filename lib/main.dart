import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  setUrlStrategy(PathUrlStrategy());
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Camera',
      theme: ThemeData.dark(),
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
  CameraController? controller;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  double _lightLevel = 0.0;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        imagePath = file.path;
        _isProcessing = false;
      });
      
      // 显示拍照成功提示
      if (mounted) {
        showInSnackBar('Picture saved to ${file.path}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showInSnackBar('Error taking picture: $e');
    }
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart Camera')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Camera'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              try {
                setState(() => _isTorchOn = !_isTorchOn);
                await controller!.setFlashMode(
                  _isTorchOn ? FlashMode.torch : FlashMode.off,
                );
              } catch (e) {
                showInSnackBar('Error toggling flash: $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: CameraPreview(controller!),
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
