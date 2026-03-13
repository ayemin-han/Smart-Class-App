import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';
import 'qr_scanner_screen.dart';

class FinishScreen extends StatefulWidget {

  @override
  _FinishScreenState createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {

  String qrCode = "";
  Position? position;
  bool _isSaving = false;

  TextEditingController learned = TextEditingController();
  TextEditingController feedback = TextEditingController();

  void _showMessage(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission denied', success: false);
        return;
      }
    }

    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {});
      _showMessage('Location acquired');
    } catch (e) {
      _showMessage('Failed to get location: $e', success: false);
    }
  }

  Future<void> saveData() async {
    if (qrCode.isEmpty) {
      _showMessage('Please scan a QR code first', success: false);
      return;
    }

    if (position == null) {
      _showMessage('Please acquire GPS location first', success: false);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = DatabaseHelper();
      final id = await db.insertRecord({
        "type": "finish",
        "latitude": position?.latitude.toString(),
        "longitude": position?.longitude.toString(),
        "qr": qrCode,
        "note": "Learned:${learned.text}, Feedback:${feedback.text}"
      });

      _showMessage('Class finish saved successfully (id: $id)');

      setState(() {
        qrCode = "";
        learned.clear();
        feedback.clear();
      });
    } catch (e) {
      _showMessage('Failed to save finish: $e', success: false);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Finish Class")),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'QR Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            qrCode.isNotEmpty ? qrCode : 'No QR code scanned yet',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.qr_code_scanner),
                          label: Text('Scan'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QRScannerScreen(
                                  onScan: (code) {
                                    setState(() {
                                      qrCode = code;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Point the camera at the QR code. The scan will happen automatically.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            position != null
                                ? 'Lat: ${position!.latitude.toStringAsFixed(6)}, Lon: ${position!.longitude.toStringAsFixed(6)}'
                                : 'Location not acquired',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.location_on),
                          label: Text('Get'),
                          onPressed: getLocation,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Press "Get" and allow location access to record your position.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: learned,
                      decoration: InputDecoration(
                        labelText: "What did you learn today?",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: feedback,
                      decoration: InputDecoration(
                        labelText: "Feedback",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              child: _isSaving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text("Submit Finish"),
              onPressed: _isSaving ? null : saveData,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}