import 'package:flutter/material.dart';

class Contact {
  String name;
  String number;

  Contact({required this.name, required this.number});
}

class ContactsManager extends StatefulWidget {
  const ContactsManager({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ContactsManagerState createState() => _ContactsManagerState();
}

class _ContactsManagerState extends State<ContactsManager> {
  final List<Contact> contacts = []; // Store added contacts
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  // Function to add a contact
  void addContact() {
    if (nameController.text.isNotEmpty && numberController.text.isNotEmpty) {
      setState(() {
        contacts.add(
            Contact(name: nameController.text, number: numberController.text));
        nameController.clear();
        numberController.clear();
      });
    }
  }

  // Function to remove a contact
  void removeContact(Contact contact) {
    setState(() {
      contacts.remove(contact);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Contacts"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Input fields for adding contact's name and number
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
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Contact Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          // Add Contact Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: addContact,
              child: const Text('Add Contact'),
            ),
          ),

          // Display Contacts
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
