import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class HeartRateMonitorPage extends StatefulWidget {
  final DiscoveredDevice device;

  const HeartRateMonitorPage({super.key, required this.device});

  @override
  _HeartRateMonitorPageState createState() => _HeartRateMonitorPageState();
}

class _HeartRateMonitorPageState extends State<HeartRateMonitorPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;
  bool _isConnected = false;
  bool _isMonitoring = false;
  int? _heartRate;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    print('Attempting to connect to device: ${widget.device.id}');
    setState(() => _isConnected = false);

    _connectionSubscription = _ble
        .connectToDevice(
      id: widget.device.id,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen(
      (connectionState) {
        print('Connection state update: ${connectionState.connectionState}');
        setState(() {
          _isConnected = connectionState.connectionState ==
              DeviceConnectionState.connected;
        });

        if (_isConnected) {
          print('Connected successfully, discovering services...');
          _discoverServices();
        }
      },
      onError: (error) {
        print('Connection error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $error')),
        );
      },
    );
  }

  Future<void> _discoverServices() async {
    try {
      final services = await _ble.discoverServices(widget.device.id);
      print('Discovered ${services.length} services');

      for (var service in services) {
        print('Service UUID: ${service.serviceId}');

        // Add your ESP32's service UUID here
        if (service.serviceId.toString() ==
            "12345678-1234-1234-1234-123456789012") {
          print('Found matching service');

          for (var characteristic in service.characteristics) {
            print('Characteristic UUID: ${characteristic.characteristicId}');

            // Add your ESP32's characteristic UUID here
            if (characteristic.characteristicId.toString() ==
                "abcd1234-ab12-cd34-ef56-abcdef123456") {
              print('Found matching characteristic');
              _startHeartRateMonitoring(
                QualifiedCharacteristic(
                  serviceId: service.serviceId,
                  characteristicId: characteristic.characteristicId,
                  deviceId: widget.device.id,
                ),
              );
              return;
            }
          }
        }
      }

      print('Heart rate service not found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heart rate service not found')),
      );
    } catch (e) {
      print('Service discovery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service discovery error: $e')),
      );
    }
  }

  void _startHeartRateMonitoring(QualifiedCharacteristic characteristic) {
    print('Starting heart rate monitoring');
    setState(() => _isMonitoring = true);

    _heartRateSubscription =
        _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        print('Received data: $data');
        if (data.isNotEmpty) {
          // Try to parse the heart rate value based on the data format
          try {
            // If ESP32 sends the value as a single byte
            if (data.length == 1) {
              setState(() => _heartRate = data[0]);
            }
            // If ESP32 sends the value as a string
            else {
              String stringValue = String.fromCharCodes(data);
              print('Received string value: $stringValue');
              setState(() => _heartRate = int.tryParse(stringValue));
            }
          } catch (e) {
            print('Error parsing heart rate data: $e');
          }
        }
      },
      onError: (error) {
        print('Monitoring error: $error');
        setState(() => _isMonitoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Monitoring error: $error')),
        );
      },
    );
  }

  @override
  void dispose() {
    print('Disposing of page');
    _connectionSubscription?.cancel();
    _heartRateSubscription?.cancel();
    super.dispose();
  }

  // Rest of the build method remains the same
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        backgroundColor: Colors.pink[100],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 8,
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Device: ${widget.device.name.isEmpty ? 'Unknown Device' : widget.device.name}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                if (!_isConnected) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  const Text('Connecting to device...'),
                ] else if (!_isMonitoring) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  const Text('Starting heart rate monitoring...'),
                ] else ...[
                  const Text(
                    'Heart Rate',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: _heartRate != null && _heartRate! > 100
                            ? Colors.red
                            : Colors.pink,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _heartRate != null ? '$_heartRate BPM' : 'Waiting...',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_heartRate != null && _heartRate! > 100) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'High Heart Rate!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
