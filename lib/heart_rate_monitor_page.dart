import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class HeartRateMonitorPage extends StatefulWidget {
  final DiscoveredDevice device;
  const HeartRateMonitorPage({super.key, required this.device});

  @override
  State<HeartRateMonitorPage> createState() => _HeartRateMonitorPageState();
}

class _HeartRateMonitorPageState extends State<HeartRateMonitorPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;

  int? _heartRate;
  bool _isConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  void _connectToDevice() {
    _connectionSubscription = _ble.connectToDevice(id: widget.device.id).listen(
      (update) {
        setState(() {
          _isConnected =
              update.connectionState == DeviceConnectionState.connected;
          _isLoading = false;
        });
        if (_isConnected) _startHeartRateMonitoring();
      },
      onError: (error) => _showErrorDialog('Connection failed: $error'),
    );
  }

  void _startHeartRateMonitoring() {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("0000180D-0000-1000-8000-00805F9B34FB"),
      characteristicId: Uuid.parse("00002A37-0000-1000-8000-00805F9B34FB"),
      deviceId: widget.device.id,
    );

    _heartRateSubscription =
        _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        if (data.isNotEmpty) {
          setState(() => _heartRate = data[1]);
        }
      },
      onError: (error) =>
          _showErrorDialog('Heart rate subscription error: $error'),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _heartRateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heart Rate Monitor')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _isConnected
                ? Text('Heart Rate: ${_heartRate ?? 'Waiting...'} bpm')
                : const Text('Not connected'),
      ),
    );
  }
}
