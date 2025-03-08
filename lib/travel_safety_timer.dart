import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:vetra/contacts.dart'; // Import your Contact class

class TravelSafetyTimer extends StatefulWidget {
  const TravelSafetyTimer({super.key});

  @override
  _TravelSafetyTimerState createState() => _TravelSafetyTimerState();
}

class _TravelSafetyTimerState extends State<TravelSafetyTimer> {
  Timer? _countdownTimer;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _alertAcknowledged = false;

  // Controllers for user input (minutes and seconds)
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  // Start the countdown timer using user-entered minutes and seconds
  void _startTimer() {
    int minutes = int.tryParse(_minutesController.text) ?? 0;
    int seconds = int.tryParse(_secondsController.text) ?? 0;
    _totalSeconds = minutes * 60 + seconds;
    if (_totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid duration")),
      );
      return;
    }
    setState(() {
      _isTimerRunning = true;
      _alertAcknowledged = false;
      _remainingSeconds = _totalSeconds;
    });
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _showReminderDialog();
      }
    });
  }

  // Stop the timer
  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = 0;
    });
  }

  // Show a reminder dialog asking the user to confirm they are safe
  Future<void> _showReminderDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Safety Reminder'),
        content: Text('Please confirm you are safe by tapping OK.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _alertAcknowledged = true;
              });
              Navigator.of(context).pop();
              _stopTimer();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    // Vibrate for 10 seconds as final warning (if available)
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 10000);
    }
    // Wait an extra 10 seconds before sending SOS
    await Future.delayed(Duration(seconds: 10));
    if (!_alertAcknowledged) {
      _sendSOSAlert();
    }
  }

  // Send an SOS alert via WhatsApp to saved contacts
  Future<void> _sendSOSAlert() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson == null) {
      _showSnackBar("No contacts available. Please add contacts first.");
      return;
    }
    List<dynamic> contactsList = jsonDecode(contactsJson);
    if (contactsList.isEmpty) {
      _showSnackBar("No contacts available. Please add contacts first.");
      return;
    }
    List<Contact> contacts = contactsList
        .map((contact) => Contact.fromMap(contact as Map<String, dynamic>))
        .toList();

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String message =
        "SOS! I need help! My location: ${position.latitude}, ${position.longitude}";

    // Loop through contacts and send WhatsApp message
    for (Contact contact in contacts) {
      String phone = contact.number;
      if (phone.startsWith('+')) {
        phone = phone.substring(1);
      }
      final Uri whatsappUrl = Uri.parse(
          "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
      try {
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          print("WhatsApp message sent to ${contact.name}");
        } else {
          print("Could not launch WhatsApp for ${contact.name}");
        }
      } catch (e) {
        print("Error sending WhatsApp message to ${contact.name}: $e");
      }
    }
    _showSnackBar("SOS alert sent via WhatsApp!");
    _stopTimer();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress for the circular countdown
    double progress = _isTimerRunning && _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 1.0;
    String formattedTime = _isTimerRunning
        ? "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}"
        : "";

    return Scaffold(
      appBar: AppBar(title: Text("Travel Safety Timer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isTimerRunning)
              Column(
                children: [
                  Text(
                    "Set Timer",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Minutes",
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _secondsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Seconds",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startTimer,
                    child: Text("Start Timer"),
                  ),
                ],
              ),
            if (_isTimerRunning)
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isTimerRunning)
              ElevatedButton(
                onPressed: _stopTimer,
                child: Text("Stop Timer"),
              ),
          ],
        ),
      ),
    );
  }
}
