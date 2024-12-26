import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  html.VideoElement? _videoElement;
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 请求相机权限
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment',
        },
        'audio': false,
      });

      if (stream != null) {
        _videoElement = html.VideoElement()
          ..srcObject = stream
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';

        // 等待视频元素加载
        await _videoElement!.onLoadedData.first;

        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Camera Error'),
          content: Text('Please allow camera access to use this app.\nError: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeCamera();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _videoElement == null) {
      return;
    }

    try {
      // 创建 canvas 来捕获视频帧
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      canvas.context2D.drawImage(_videoElement!, 0, 0);

      // 转换为图片
      final dataUrl = canvas.toDataUrl('image/png');
      
      // 创建下载链接
      final anchor = html.AnchorElement(href: dataUrl)
        ..download = 'photo_${DateTime.now().millisecondsSinceEpoch}.png'
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved!')),
      );
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  @override
  void dispose() {
    if (_videoElement?.srcObject != null) {
      _videoElement!.srcObject!.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
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
              setState(() => _isTorchOn = !_isTorchOn);
              // 在 web 中闪光灯控制可能不可用
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isCameraInitialized
                  ? HtmlElementView(
                      viewType: 'video-${DateTime.now().millisecondsSinceEpoch}',
                      onPlatformViewCreated: (_) {
                        // 将视频元素添加到 Flutter web 视图
                        html.document.querySelector('#flutter_video')?.children
                            .add(_videoElement!);
                      },
                    )
                  : Center(child: CircularProgressIndicator()),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isCameraInitialized ? _takePicture : null,
                  icon: const Icon(Icons.camera),
                  label: const Text('Take Photo'),
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
