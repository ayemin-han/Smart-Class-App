import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';
import 'qr_scanner_screen.dart';

class CheckinScreen extends StatefulWidget {
  @override
  _CheckinScreenState createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {

  String qrCode = "";
  Position? position;
  bool _isSaving = false;

  TextEditingController previousTopic = TextEditingController();
  TextEditingController expectedTopic = TextEditingController();

  int mood = 3;

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
        "type": "checkin",
        "latitude": position?.latitude.toString(),
        "longitude": position?.longitude.toString(),
        "qr": qrCode,
        "note": "Prev:${previousTopic.text}, Expect:${expectedTopic.text}, Mood:$mood"
      });

      _showMessage('Check-in saved successfully (id: $id)');

      // Optionally clear form
      setState(() {
        qrCode = "";
        previousTopic.clear();
        expectedTopic.clear();
        mood = 3;
      });
    } catch (e) {
      _showMessage('Failed to save check-in: $e', success: false);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Check-in")),

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
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: previousTopic,
                      decoration: InputDecoration(
                        labelText: "Previous class topic",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: expectedTopic,
                      decoration: InputDecoration(
                        labelText: "Expected topic today",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: mood,
                      decoration: InputDecoration(
                        labelText: 'Mood',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 1, child: Text("1 Very Negative")),
                        DropdownMenuItem(value: 2, child: Text("2 Negative")),
                        DropdownMenuItem(value: 3, child: Text("3 Neutral")),
                        DropdownMenuItem(value: 4, child: Text("4 Positive")),
                        DropdownMenuItem(value: 5, child: Text("5 Very Positive")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            mood = value;
                          });
                        }
                      },
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
                  : Text("Save Check-in"),
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