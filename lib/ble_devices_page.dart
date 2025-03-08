import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  State<BleScannerPage> createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  bool _isScanning = false;

  void _startScan() {
    setState(() => _isScanning = true);

    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (!_devicesList.any((d) => d.id == device.id)) {
        setState(() => _devicesList.add(device));
      }
    }, onError: (error) {
      print('Scanning error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning error: $error')),
      );
      setState(() => _isScanning = false);
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available BLE Devices'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: _devicesList.isEmpty
          ? const Center(child: Text('No devices found. Scanning...'))
          : ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                final device = _devicesList[index];
                return ListTile(
                  title: Text(
                      device.name.isNotEmpty ? device.name : "Unnamed Device"),
                  subtitle: Text(device.id),
                  onTap: () => Navigator.pop(context, device),
                );
              },
            ),
    );
  }
}
