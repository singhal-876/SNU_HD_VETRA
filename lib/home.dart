import 'package:flutter/material.dart';
import 'contacts.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
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
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/watch.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(60),
                shape: const CircleBorder(),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Calling and messaging your contacts")),
                );
              },
              child: const Text("SOS", style: TextStyle(color: Colors.white)),
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
                      onPressed: () {
                        // Add Start/Stop sharing location functionality here
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text("Start/Stop Sharing Location"),
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
