import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置 web 路由策略
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
  bool _cameraPermissionGranted = false;
  html.VideoElement? _videoElement;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _requestCameraAccess();
  }

  Future<void> _requestCameraAccess() async {
    try {
      // 请求相机权限
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment',
        },
        'audio': false,
      });

      if (stream != null) {
        setState(() {
          _cameraPermissionGranted = true;
          _videoElement = html.VideoElement()
            ..srcObject = stream
            ..autoplay = true
            ..style.width = '100%'
            ..style.height = '100%';
        });

        // 将视频元素添加到 DOM
        html.document.body?.append(_videoElement!);
      }
    } catch (e) {
      print('Error accessing camera: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Camera Access Error'),
          content: Text('Please allow camera access to use this app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestCameraAccess();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraPermissionGranted || _videoElement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    try {
      // 创建 canvas 来捕获视频帧
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      canvas.context2D.drawImage(_videoElement!, 0, 0);

      // 转换为图片 URL
      final url = canvas.toDataUrl('image/png');

      // 创建下载链接
      final anchor = html.AnchorElement(href: url)
        ..download = 'photo_${DateTime.now().millisecondsSinceEpoch}.png'
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  @override
  void dispose() {
    _videoElement?.srcObject?.getTracks().forEach((track) => track.stop());
    _videoElement?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Camera'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              // 注意：Web 版本可能不支持闪光灯控制
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _cameraPermissionGranted
                  ? HtmlElementView(
                      viewType: 'video-element',
                      onPlatformViewCreated: (int id) {
                        // 视图创建完成后的回调
                      },
                    )
                  : CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _cameraPermissionGranted ? _takePicture : null,
                  icon: Icon(Icons.camera),
                  label: Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
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
