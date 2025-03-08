// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'contacts.dart';

// class ThreatDetection {
//   static bool isThreatDetected(int heartRate, List<int> voiceData) {
//     // Add your threat detection logic here
//     return heartRate > 100; // Simple threshold for demo
//   }

//   static Future<void> triggerEmergencyCall(BuildContext context) async {
//     final contactsManager = ContactsManagerState();
//     contactsManager.loadContacts();
//     final firstContact = contactsManager.getFirstContact();

//     if (firstContact != null) {
//       final Uri phoneUri = Uri.parse('tel:${firstContact.number}');
//       if (await canLaunchUrl(phoneUri)) {
//         await launchUrl(phoneUri);
//       } else {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Could not launch emergency call')),
//           );
//         }
//       }
//     } else {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No emergency contacts found')),
//         );
//       }
//     }
//   }
// }
