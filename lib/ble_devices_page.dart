import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';

/// ===============================
/// BLE Devices Page with Threat Detection Button
/// ===============================
class BleScannerPage extends StatefulWidget {
  const BleScannerPage({Key? key}) : super(key: key);

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
      body: Column(
        children: [
          // Button for Threat Detection integration.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: const Text('Threat Detection'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ThreatDetectionPage()),
                );
              },
            ),
          ),
          // Display BLE devices list below.
          Expanded(
            child: _devicesList.isEmpty
                ? const Center(child: Text('No devices found. Scanning...'))
                : ListView.builder(
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final device = _devicesList[index];
                      return ListTile(
                        title: Text(device.name.isNotEmpty
                            ? device.name
                            : "Unnamed Device"),
                        subtitle: Text(device.id),
                        onTap: () => Navigator.pop(context, device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Threat Detection Page
/// This page demonstrates loading and using the TFLite model.
/// ===============================
class ThreatDetectionPage extends StatefulWidget {
  const ThreatDetectionPage({Key? key}) : super(key: key);

  @override
  _ThreatDetectionPageState createState() => _ThreatDetectionPageState();
}

class _ThreatDetectionPageState extends State<ThreatDetectionPage> {
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _isRunningInference = false;
  double? _threatProbability;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  /// Loads the TFLite model from assets.
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/threat_model.tflite');
      setState(() {
        _modelLoaded = true;
      });
      print('TFLite model loaded successfully.');
    } catch (e) {
      print('Error loading TFLite model: $e');
    }
  }

  /// Run inference using dummy data.
  /// Replace the dummy data with actual sensor inputs as needed.
  Future<void> _runInference() async {
    if (_interpreter == null) {
      print('Model not loaded.');
      return;
    }
    setState(() {
      _isRunningInference = true;
      _threatProbability = null;
    });

    // Dummy inputs: adjust these arrays as per your model's input shape.
    // Example for heart rate branch: [Heart Rate, Feature_1, Feature_2]
    List<double> heartFeatures = [62.0, 0.62, 1.24];

    // Example for audio branch: assume 13 MFCC features.
    List<double> audioFeatures = List.filled(13, 0.5);
    int audioFeatureCount = audioFeatures.length;

    // Prepare inputs for inference.
    // Heart branch expects shape [1, num_features].
    var inputHeart = [heartFeatures];

    // Audio branch expects shape [1, audioFeatureCount, 1].
    var inputAudio = [
      List.generate(audioFeatureCount, (index) => [audioFeatures[index]])
    ];

    // Output buffer: shape [1, 1].
    var output = List.filled(1, 0.0).reshape([1, 1]);

    // Run inference.
    _interpreter!.runForMultipleInputs(
        [inputHeart, inputAudio], output as Map<int, Object>);
    double probability = output[0][0];

    setState(() {
      _threatProbability = probability;
      _isRunningInference = false;
    });
    print('Inference completed. Threat probability: $probability');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threat Detection'),
      ),
      body: Center(
        child: _modelLoaded
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isRunningInference
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _runInference,
                            child: const Text('Run Threat Detection'),
                          ),
                    const SizedBox(height: 20),
                    if (_threatProbability != null)
                      Text(
                        'Threat Probability: ${(_threatProbability! * 100).toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
