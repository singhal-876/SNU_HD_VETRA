import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class GoogleKmlMapPage extends StatefulWidget {
  const GoogleKmlMapPage({super.key});

  @override
  _GoogleKmlMapPageState createState() => _GoogleKmlMapPageState();
}

class _GoogleKmlMapPageState extends State<GoogleKmlMapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final databaseRef = FirebaseDatabase.instance
      .ref("user_location"); // Reference to your Firebase location node

  StreamSubscription<DatabaseEvent>? locationSubscription;
  LatLng currentLocation = LatLng(0, 0); // Initialize with a default value

  Future<void> _loadKml() async {
    final kmlString = await rootBundle.loadString('assets/doc.kml');
    final kmlDocument = xml.XmlDocument.parse(kmlString);

    for (var placemark in kmlDocument.findAllElements('Placemark')) {
      final coordinates =
          placemark.findElements('coordinates').first.text.trim().split(',');
      final lat = double.parse(coordinates[1]);
      final lng = double.parse(coordinates[0]);

      markers.add(
        Marker(
          markerId: MarkerId(lat.toString() + lng.toString()),
          position: LatLng(lat, lng),
        ),
      );
    }

    setState(() {});
  }

  // Listen for location updates from Firebase
  void _listenToLocationUpdates() {
    locationSubscription = databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map;
      final lat = data['latitude'];
      final lng = data['longitude'];
      setState(() {
        currentLocation = LatLng(lat, lng);
      });
      _updateMapLocation(currentLocation);
    });
  }

  // Update camera position to the new location
  void _updateMapLocation(LatLng newLocation) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newLocation, zoom: 14.0),
      ),
    );

    // Optionally, update a marker to show the current location
    markers.add(
      Marker(
        markerId: MarkerId("current_location"),
        position: newLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    setState(() {}); // Update the UI with the new marker
  }

  @override
  void initState() {
    super.initState();
    _loadKml();
    _listenToLocationUpdates();
  }

  @override
  void dispose() {
    locationSubscription
        ?.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Location in Google Maps")),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: markers,
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 5,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _updateMapLocation(currentLocation),
        tooltip: 'Go to Current Location',
        child: Icon(Icons.my_location),
      ),
    );
  }
}
