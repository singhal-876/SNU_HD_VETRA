import 'package:flutter/material.dart';
import 'package:sphere/bottom_nav_bar.dart';
import 'package:sphere/home.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Sphere",
    home: const HomePage(),
    theme: ThemeData(
      primaryColor: const Color.fromARGB(255, 247, 244, 233),
      scaffoldBackgroundColor: const Color.fromARGB(255, 247, 244, 233),
      appBarTheme: const AppBarTheme(
        backgroundColor:
            Color.fromARGB(255, 223, 218, 226), // Default AppBar color
        titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20), // Optional: Customize AppBar title text style
      ),
    ),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedItem = 0;

  // List of pages to show based on bottom menu selection
  final List<Widget> pages = [
    const Home(),
    const Community(),
    const Location(),
    const Favourites()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sphere"),
      ),
      drawer: const DrawerMenu(),
      body: pages[selectedItem], // Display the selected page content
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.pink[100],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.pink[200],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Location"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favourites"),
        ],
        currentIndex: selectedItem,
        onTap: (value) {
          setState(() {
            selectedItem = value; // Update selected item and refresh body
          });
        },
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              // Adding a background image
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/bg_drawer_img.png'), // URL of background image
                fit: BoxFit.cover, // Make image cover the entire header
              ),
            ),
            // Adding CircleAvatar for the profile image
            currentAccountPicture: CircleAvatar(
              radius: 80, // Size of the avatar
              backgroundImage: AssetImage(
                  'assets/images/sphere.png'), // URL of the avatar image
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
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Contact'),
          ),
        ],
      ),
    );
  }
}
