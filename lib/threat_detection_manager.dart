import 'dart:convert';
import 'package:http/http.dart' as http;

class ThreatDetectionManager {
  final String apiUrl;

  ThreatDetectionManager(this.apiUrl);

  void sendHeartRate(double heartRate) async {
    var response = await http.post(
      Uri.parse('$apiUrl/heart_rate'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'heart_rate': heartRate,
      }),
    );
    if (response.statusCode == 200) {
      print('Heart rate data sent successfully.');
      print('Response: ${response.body}');
    } else {
      print('Failed to send heart rate data.');
    }
  }

  void sendVoiceData(double voiceData) async {
    var response = await http.post(
      Uri.parse('$apiUrl/voice_data'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'voice_data': voiceData,
      }),
    );
    if (response.statusCode == 200) {
      print('Voice data sent successfully.');
      print('Response: ${response.body}');
    } else {
      print('Failed to send voice data.');
    }
  }
}
