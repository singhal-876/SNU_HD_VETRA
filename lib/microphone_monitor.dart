import 'threat_detection_manager.dart';

class MicrophoneMonitor {
  final ThreatDetectionManager _threatDetectionManager;

  MicrophoneMonitor(this._threatDetectionManager);

  void startMonitoring() {
    // Logic for monitoring microphone input
    print('Microphone monitoring started...');
    // Simulate receiving data
    double simulatedVoiceData = 0.8; // Example threshold
    _threatDetectionManager.sendVoiceData(simulatedVoiceData);
  }

  void stopMonitoring() {
    // Logic to stop monitoring
    print('Microphone monitoring stopped.');
  }
}
