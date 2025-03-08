import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  _LocationSharingScreenState createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  late final WebViewController _webViewController;
  bool _isSharingLocation = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _getLocationPermission();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { margin: 0; padding: 0; }
              #map-container { width: 100%; height: 100%; position: relative; }
              #user-location {
                position: absolute;
                bottom: 10px;
                left: 10px;
                background-color: white;
                padding: 8px;
                border-radius: 4px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.2);
                font-family: Arial, sans-serif;
              }
            </style>
          </head>
          <body>
            <div id="map-container">
              <iframe 
                src="https://www.google.com/maps/d/u/0/embed?mid=1AORRaGK7qbNgCQIExwbJWFdi4CBZUM4&ehbc=2E312F"
                width="100%" 
                height="100%" 
                style="border:0;" 
                allowfullscreen>
              </iframe>
              <div id="user-location">Location: Not shared</div>
            </div>
          </body>
        </html>
      ''');
  }

  Future<void> _getLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied, please enable them in settings'),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking location permission: $e'),
        ),
      );
    }
  }

  Future<void> _startSharingLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isSharingLocation = true;
      });

      await _updateLocationOnMap();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
        ),
      );
    }
  }

  void _stopSharingLocation() {
    setState(() {
      _isSharingLocation = false;
    });
    _webViewController.runJavaScript(
        "document.getElementById('user-location').innerText = 'Location: Not shared';");
  }

  Future<void> _updateLocationOnMap() async {
    if (_currentPosition != null) {
      try {
        await _webViewController.runJavaScript(
          "document.getElementById('user-location').innerText = "
          "'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, "
          "${_currentPosition!.longitude.toStringAsFixed(6)}';",
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating map: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & Location Sharing'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: WebViewWidget(controller: _webViewController),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSharingLocation
                        ? 'Sharing Location: ${_currentPosition?.latitude.toStringAsFixed(6)}, '
                            '${_currentPosition?.longitude.toStringAsFixed(6)}'
                        : 'Location not being shared',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _isSharingLocation ? null : _startSharingLocation,
                        child: const Text('Start Sharing'),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isSharingLocation ? _stopSharingLocation : null,
                        child: const Text('Stop Sharing'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
