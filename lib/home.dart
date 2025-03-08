// ignore_for_file: unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:convert';
import 'package:vetra/main.dart';
import 'contacts.dart';
import 'travel_safety_timer.dart'; // Safety Timer feature
import 'vetra_connection.dart'; // Vetra Connection feature
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Contact> contacts = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FlutterReactiveBle _ble = FlutterReactiveBle();
  // bool _bluetoothState = false;
  String? _connectedDeviceName;
  // String? _connectedDeviceId;
  String _batteryStatus = "--";
  bool _isLocationSharing = false; // true if location is being shared
  bool _shouldSendSOSAfterDialer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeNotifications();
    loadContacts();
    requestPermissions();
    // _checkBluetoothState();
    _fetchLocationSharingStatus();
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
      'sos_channel', // channel id
      'SOS Notifications', // channel name
      channelDescription: 'Notification when SOS is triggered',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'SOS Alert', // notification title
      'Sending SOS messages and initiating call', // notification body
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes from the dialer, check if we need to send the SOS alert.
    if (state == AppLifecycleState.resumed && _shouldSendSOSAfterDialer) {
      _shouldSendSOSAfterDialer = false;
      _sendSOSAlert();
    }
  }

  // Updated callFirstContact() to launch dialer.
  Future<void> callFirstContact() async {
    if (contacts.isNotEmpty) {
      final Uri phoneUri = Uri.parse('tel:${contacts.first.number}');
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          print("Dialer launched for ${contacts.first.name}");
          // Set flag to trigger WhatsApp messaging once user returns.
          _shouldSendSOSAfterDialer = true;
        } else {
          print("Could not launch dialer for ${contacts.first.name}");
        }
      } catch (e) {
        print("Error launching dialer for ${contacts.first.name}: $e");
      }
    } else {
      print("No contacts available to call");
    }
  }

  // Updated onPressed callback for the SOS button:
  void _handleSOSButtonPressed() async {
    // Launch dialer for the first contact.
    await callFirstContact();
    // Now, when the user returns to the app (i.e., app state becomes resumed),
    // didChangeAppLifecycleState will trigger and send the WhatsApp SOS alert.
  }

// Updated _sendSOSAlert() to send WhatsApp message to all contacts.
  Future<void> _sendSOSAlert() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? contactsJson = prefs.getString('contacts');
    if (contactsJson == null || contactsJson.isEmpty) {
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

    // Prepare SOS message
    String message =
        "SOS! I need help! My location: ${position.latitude}, ${position.longitude}";

    // Loop through contacts and send WhatsApp message using wa.me URL
    for (Contact contact in contacts) {
      String phone = contact.number;
      // Remove all non-digit characters (including '+')
      phone = phone.replaceAll(RegExp(r'\D'), '');
      final Uri whatsappUrl = Uri.parse(
          "https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
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

  void _stopTimer() {
    print("Timer stopped.");
  }

  // Future<void> _checkBluetoothState() async {
  //   BleStatus bleStatus = await _ble.statusStream.first;
  //   _bluetoothState = bleStatus == BleStatus.ready;
  //   setState(() {});
  // }

  // Navigate to Vetra Connection Screen and update connection info dynamically,
  // then update battery status.
  void _navigateToVetraConnectionScreen() async {
    final selectedDevice = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VetraConnectionScreen()),
    );
    if (selectedDevice != null) {
      setState(() {
        _connectedDeviceName = selectedDevice.name.isNotEmpty
            ? selectedDevice.name
            : selectedDevice.id;
        // _connectedDeviceId = selectedDevice.id;
      });
      _updateBatteryStatus(selectedDevice);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to $_connectedDeviceName")),
      );
    }
  }

  // Dummy function to simulate reading battery status from the device.
  Future<void> _updateBatteryStatus(DiscoveredDevice device) async {
    // In real implementation, read from the battery characteristic.
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _batteryStatus = "85%"; // Simulated battery percentage.
    });
  }

  // Fetch location sharing status from Firestore.
  Future<void> _fetchLocationSharingStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _isLocationSharing = doc.get('isSharing') ?? false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.05; // dynamic 5% margin

    return Scaffold(
      body: Column(
        children: [
          // Top section: Device info with dynamic watch image
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 223, 218, 226),
            ),
            height: screenHeight * 0.3,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Container(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.25,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/watch.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.1),
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 193, 186, 222),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_connectedDeviceName != null
                            ? "Connected to:\n$_connectedDeviceName"
                            : "No Device Connected"),
                        Text("Battery Status: $_batteryStatus"),
                        Text(
                            "Location Sharing: ${_isLocationSharing ? 'Yes' : 'No'}"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SOS button placed slightly lower with reduced spacing
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(60),
                shape: const CircleBorder(),
              ),
              onPressed: _handleSOSButtonPressed,
              child: const Text(
                "SOS",
                style: TextStyle(color: Colors.white, fontSize: 50),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Vertically stacked buttons with dynamic horizontal padding.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _navigateToVetraConnectionScreen,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text("Connect to Vetra"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsManager(),
                      ),
                    );
                    loadContacts();
                  },
                  icon: const Icon(Icons.contacts),
                  label: const Text("Manage Contacts"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TravelSafetyTimer(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text("Safety Timer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  Future<void> _signOutAndNavigate(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_drawer_img.png'),
                fit: BoxFit.cover,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/images/sphere.png'),
            ),
            accountName: Text(
              "Sphere_username_1",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              "username1@gmail.com",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              _signOutAndNavigate(context);
            },
          ),
        ],
      ),
    );
  }
}
