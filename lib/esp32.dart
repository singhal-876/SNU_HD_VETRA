// ignore_for_file: unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class ESP32IntegrationPage extends StatefulWidget {
  const ESP32IntegrationPage({super.key});

  @override
  _ESP32IntegrationPageState createState() => _ESP32IntegrationPageState();
}

class _ESP32IntegrationPageState extends State<ESP32IntegrationPage> {
  final FlutterReactiveBle _ble =
      FlutterReactiveBle(); // Initialize Flutter Reactive BLE
  late DiscoveredDevice _connectedDevice;
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  bool _scanning = false;
  final List<DiscoveredDevice> _devices = [];

  // ESP32 UUIDs
  final Uuid _esp32ServiceUuid =
      Uuid.parse("12345678-1234-1234-1234-123456789012");
  final Uuid _esp32CharacteristicUuid =
      Uuid.parse("abcd1234-ab12-cd34-ef56-abcdef123456");

  @override
  void dispose() {
    _scanSubscription.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    // Request Bluetooth permissions if needed
    var status = await Permission.bluetooth.request();
    if (status.isGranted) {
      setState(() {
        _scanning = true;
        _devices.clear();
      });

      _scanSubscription = _ble.scanForDevices(
        withServices: [_esp32ServiceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        if (!_devices.any((d) => d.id == device.id)) {
          setState(() {
            _devices.add(device);
          });
        }
      }, onError: (error) {
        print('Scan error: $error');
      });

      // Stop scanning after 10 seconds
      await Future.delayed(const Duration(seconds: 10));
      _scanSubscription.cancel();
      setState(() {
        _scanning = false;
      });
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      // Connecting to the device
      _ble.connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {
          _esp32ServiceUuid: [_esp32CharacteristicUuid],
        },
      ).listen((connectionState) {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          setState(() {
            _connectedDevice = device;
          });
        }
      });
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ESP32 Integration"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _scanning
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _startScan,
                  child: const Text("Start Scan"),
                ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name.isNotEmpty
                      ? _devices[index].name
                      : _devices[index].id),
                  onTap: () => _connectToDevice(_devices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
