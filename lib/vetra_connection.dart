// vetra_connection.dart
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class VetraConnectionScreen extends StatefulWidget {
  const VetraConnectionScreen({Key? key}) : super(key: key);

  @override
  _VetraConnectionScreenState createState() => _VetraConnectionScreenState();
}

class _VetraConnectionScreenState extends State<VetraConnectionScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  // Scans for all nearby BLE devices by using an empty filter list.
  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });
    _ble.scanForDevices(
      withServices: [], // Scanning for all devices; adjust if you want a specific service
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    }, onError: (error) {
      print("Scan error: $error");
      setState(() {
        _isScanning = false;
      });
    });
    // Stop scanning after 10 seconds.
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        _isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    // Clean-up if necessary.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect to Vetra")),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : device.id),
                  subtitle: Text(device.id),
                  onTap: () {
                    // Return the selected device back to Home
                    Navigator.pop(context, device);
                  },
                );
              },
            ),
    );
  }
}
