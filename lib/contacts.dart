import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Contact {
  String name;
  String number;

  Contact({required this.name, required this.number});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'],
      number: map['number'],
    );
  }
}

class ContactsManager extends StatefulWidget {
  const ContactsManager({super.key});

  @override
  ContactsManagerState createState() => ContactsManagerState();
}

class ContactsManagerState extends State<ContactsManager> {
  List<Contact> contacts = [];
  final TextEditingController nameController = TextEditingController();
  String completePhoneNumber = '';
  bool isValidPhoneNumber = false;

  @override
  void initState() {
    super.initState();
    loadContacts();
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

  void saveContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> contactsList =
        contacts.map((contact) => contact.toMap()).toList();
    String contactsJson = jsonEncode(contactsList);
    await prefs.setString('contacts', contactsJson);
  }

  void addContact() {
    if (nameController.text.isNotEmpty && isValidPhoneNumber) {
      setState(() {
        contacts.add(
            Contact(name: nameController.text, number: completePhoneNumber));
        nameController.clear();
        completePhoneNumber = '';
        isValidPhoneNumber = false;
      });
      saveContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact added successfully")),
      );
    } else {
      String errorMessage = "Please enter ";
      if (nameController.text.isEmpty) errorMessage += "a name";
      if (nameController.text.isEmpty && !isValidPhoneNumber) {
        errorMessage += " and ";
      }
      if (!isValidPhoneNumber) errorMessage += "a valid 10-digit phone number";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void removeContact(Contact contact) {
    setState(() {
      contacts.remove(contact);
    });
    saveContacts();
  }

  // New method to get all contacts
  List<Contact> getAllContacts() {
    return contacts;
  }

  // New method to get the first contact
  Contact? getFirstContact() {
    return contacts.isNotEmpty ? contacts.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Contacts"),
        foregroundColor: const Color.fromARGB(255, 247, 244, 233),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Enter Phone Number',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    completePhoneNumber = phone.completeNumber;
                    isValidPhoneNumber = phone.number.length == 10;
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: addContact,
              child: const Text('Add Contact'),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const Center(child: Text("No contacts added yet"))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(contacts[index].name),
                        subtitle: Text(contacts[index].number),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => removeContact(contacts[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
