import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerScreen({super.key, required this.onScan});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final bool _isSupported;
  MobileScannerController? _cameraController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _isSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (_isSupported) {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _cameraController = MobileScannerController();
      setState(() {});
    } else {
      // Handle denied permission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera permission is required for QR scanning')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    print('QR Detection triggered: ${capture.barcodes.length} barcodes');
    if (!_isScanning) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final String? code = barcode?.rawValue;

    print('Scanned code: $code');

    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });
      _cameraController?.stop();

      widget.onScan(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code scanned: $code')),
        );
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: Text('Scan QR Code')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[600]),
                SizedBox(height: 16),
                Text(
                  kIsWeb
                      ? 'On web, please enter the QR code manually:'
                      : 'QR scanning requires a camera and is not supported on this platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (kIsWeb) ...[
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter QR Code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        widget.onScan(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                ] else ...[
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Go Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
              });
              if (_isScanning) {
                _cameraController?.start();
              } else {
                _cameraController?.stop();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.flashlight_on),
            onPressed: () => _cameraController?.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () => _cameraController?.switchCamera(),
          ),
        ],
      ),
      body: _cameraController == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          MobileScanner(
            controller: _cameraController!,
            onDetect: _handleDetection,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Place QR code inside the box',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: EdgeInsets.all(16),
              child: Text(
                'Point your camera at the QR code. The scan will happen automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}