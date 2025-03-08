import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntegratedLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSharing = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<void> initialize() async {
    await _loadSharingStatus();
    if (_isSharing) {
      await startLocationUpdates();
    }
  }

  Future<void> _loadSharingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isSharing = prefs.getBool('isSharing') ?? false;
  }

  Future<void> _saveSharingStatus(bool isSharing) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSharing', isSharing);
  }

  Future<void> toggleSharing() async {
    _isSharing = !_isSharing;
    await _saveSharingStatus(_isSharing);
    if (_isSharing) {
      await startLocationUpdates();
    } else {
      await stopLocationUpdates();
    }
  }

  Future<void> startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _updateFirestore(position);
    });
  }

  Future<void> stopLocationUpdates() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentPosition = null;
  }

  Future<void> _updateFirestore(Position position) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is currently signed in');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'location': GeoPoint(position.latitude, position.longitude),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
          'Location updated in Firestore: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyUsers(
      double radiusInMeters) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('Current user document does not exist in Firestore');
      }

      GeoPoint? userLocation = userDoc.get('location') as GeoPoint?;
      if (userLocation == null) {
        throw Exception('Current user location is not set in Firestore');
      }

      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> nearbyUsers = querySnapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).where((user) {
        GeoPoint? otherLocation = user['location'] as GeoPoint?;
        if (otherLocation == null) return false;

        double distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          otherLocation.latitude,
          otherLocation.longitude,
        );
        return distance <= radiusInMeters;
      }).toList();

      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  bool get isSharing => _isSharing;
  Position? get currentPosition => _currentPosition;
}
