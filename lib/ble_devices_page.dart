import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'heart_rate_monitor_page.dart';

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  _BleScannerPageState createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartScan();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    final bluetoothScan = await Permission.bluetoothScan.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final location = await Permission.location.status;

    if (bluetoothScan.isDenied ||
        bluetoothConnect.isDenied ||
        location.isDenied) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();
    }

    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _devices = [];
      _isScanning = true;
    });

    _ble.scanForDevices(
      withServices: [], // Empty to scan for all devices initially
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        if (!_devices.any((d) => d.id == device.id)) {
          setState(() {
            _devices.add(device);
          });
        }
      },
      onError: (error) {
        print('Scanning error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning error: $error')),
        );
        setState(() {
          _isScanning = false;
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
      },
    );
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.pink[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isScanning
                        ? 'Scanning for devices...'
                        : 'Available devices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.pink[800],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Found ${_devices.length} devices',
                    style: TextStyle(color: Colors.pink[600]),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isScanning ? Icons.stop : Icons.refresh,
                  color: Colors.pink[800],
                ),
                onPressed: _isScanning ? _stopScanning : _startScanning,
              ),
            ],
          ),
        ),
        Expanded(
          child: _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching,
                          size: 48, color: Colors.pink[200]),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning
                            ? 'Searching for devices...'
                            : 'No devices found',
                        style: TextStyle(color: Colors.pink[800]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: Icon(Icons.bluetooth, color: Colors.pink[400]),
                        title: Text(
                          device.name.isEmpty ? 'Unknown Device' : device.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device.id),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[400],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HeartRateMonitorPage(device: device),
                              ),
                            );
                          },
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
