// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:convert';
import 'contacts.dart';
import 'ble_devices_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Contact> contacts = [];
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  bool _bluetoothState = false;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadContacts();
    requestPermissions();
    _checkBluetoothState();
  }

  Future<void> requestPermissions() async {
    var smsStatus = await Permission.sms.request();
    var phoneStatus = await Permission.phone.request();
    var bluetoothScanStatus = await Permission.bluetoothScan.request();
    var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    var locationStatus = await Permission.location.request();

    if (smsStatus.isDenied || phoneStatus.isDenied || locationStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All permissions are required for SOS")),
      );
    }
  }

  void loadContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      List<dynamic> contactsList = jsonDecode(contactsJson);
      setState(() {
        contacts =
            contactsList.map((contact) => Contact.fromMap(contact)).toList();
      });
    }
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sos_channel',
      'SOS Notifications',
      channelDescription: 'Notification when SOS is triggered',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'SOS Alert',
      'Sending SOS messages and initiating call',
      platformChannelSpecifics,
    );
  }

  Future<void> sendSOSMessages() async {
    String message = "SOS! I need help!";
    for (Contact contact in contacts) {
      final Uri smsUri = Uri.parse(
          'sms:${contact.number}?body=${Uri.encodeComponent(message)}');
      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          print("SMS sent to ${contact.name}");
        } else {
          print("Could not launch SMS for ${contact.name}");
        }
      } catch (e) {
        print("Error sending SMS to ${contact.name}: $e");
      }
    }
  }

  Future<void> callFirstContact() async {
    if (contacts.isNotEmpty) {
      final Uri phoneUri = Uri.parse('tel:${contacts.first.number}');
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
          print("Calling ${contacts.first.name}");
        } else {
          print("Could not launch call for ${contacts.first.name}");
        }
      } catch (e) {
        print("Error calling ${contacts.first.name}: $e");
      }
    } else {
      print("No contacts available to call");
    }
  }

  Future<void> sendSOS() async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No contacts available. Please add contacts first.")),
      );
      return;
    }

    await showNotification();

    // Send SOS messages to all contacts
    await sendSOSMessages();

    // Call the first contact
    await callFirstContact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS alert sent and call initiated")),
    );
  }

  Future<void> _checkBluetoothState() async {
    BleStatus bleStatus = await _ble.statusStream.first; // Listen to the stream
    _bluetoothState =
        bleStatus == BleStatus.ready; // Check if Bluetooth is ready
    setState(() {}); // Update the UI
  }

  void _navigateToBLEDevicesPage() async {
    if (_bluetoothState) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BleScannerPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enable Bluetooth to scan for devices")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 223, 218, 226),
            ),
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/watch.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 193, 186, 222),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CONNECTED"),
                        Text("Battery Status: FULL"),
                        Text("GPS Tracking: ON"),
                        Text("Safety Status: YES"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(60),
                shape: const CircleBorder(),
              ),
              onPressed: sendSOS,
              child: const Text("SOS",
                  style: TextStyle(color: Colors.white, fontSize: 50)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactsManager(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.contacts),
                      label: const Text("Manage Contacts"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToBLEDevicesPage,
                      icon: Icon(_bluetoothState
                          ? Icons.bluetooth
                          : Icons.bluetooth_disabled),
                      label: Text(_bluetoothState
                          ? "Scan BLE Devices"
                          : "Bluetooth OFF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _bluetoothState ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
