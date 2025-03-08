import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'integrated_location_service.dart';

class NearbyUsersPage extends StatefulWidget {
  const NearbyUsersPage({super.key});

  @override
  _NearbyUsersPageState createState() => _NearbyUsersPageState();
}

class _NearbyUsersPageState extends State<NearbyUsersPage> {
  final IntegratedLocationService _locationService =
      IntegratedLocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userEmail;
  List<Map<String, dynamic>> nearbyUsers = [];
  bool _isSharing = false;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
    // Set up real-time listener for users collection
    _setupUsersListener();
  }

  void _setupUsersListener() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      _updateNearbyUsers(snapshot);
    }, onError: (error) {
      print('Error in users stream: $error');
    });
  }

  Future<void> _initializeLocationService() async {
    setState(() => _isLoading = true);
    try {
      await _locationService.initialize();
      setState(() {
        _isSharing = _locationService.isSharing;
      });
      await _getCurrentPositionAndFetchUsers();
    } catch (e) {
      print('Error initializing location service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize location service: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentPositionAndFetchUsers() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update current user's location in Firestore
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentPosition = position;
      });
      await _getUserEmail();
      await _getNearbyUsers();
    } catch (e) {
      print('Error getting current position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    }
  }

  void _updateNearbyUsers(QuerySnapshot snapshot) {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> users = snapshot.docs
        .where((doc) => doc.id != _auth.currentUser?.uid)
        .map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).where((user) {
      GeoPoint? userLocation = user['location'] as GeoPoint?;
      if (userLocation == null) return false;

      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        userLocation.latitude,
        userLocation.longitude,
      );

      // Calculate distance in meters
      user['distance'] = distance.round();
      return distance <= 5000; // 5km radius
    }).toList();

    setState(() {
      nearbyUsers = users;
    });
  }

  Future<void> _getUserEmail() async {
    final user = _auth.currentUser;
    setState(() {
      userEmail = user?.email;
    });
  }

  Future<void> _getNearbyUsers() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to see nearby users')),
      );
      return;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      _updateNearbyUsers(querySnapshot);
    } catch (e) {
      print('Error getting nearby users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch nearby users: $e')),
      );
    }
  }

  Future<void> _sendSOSNotification(BuildContext context) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location not available. Please try again.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SOS Alert'),
        content: const Text(
            'Are you sure you want to send an SOS alert to all nearby users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendSOSToUsers();
            },
            child: const Text('Send SOS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOSToUsers() async {
    try {
      for (var user in nearbyUsers) {
        await _firestore
            .collection('users')
            .doc(user['id'])
            .collection('notifications')
            .add({
          'type': 'SOS',
          'message':
              'Emergency! User ${userEmail ?? 'Unknown'} needs immediate assistance!',
          'location':
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
          'timestamp': FieldValue.serverTimestamp(),
          'from': userEmail,
          'fromId': _auth.currentUser?.uid,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS alert sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error sending SOS notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS alert: $e')),
      );
    }
  }

  void _toggleSharing() async {
    try {
      await _locationService.toggleSharing();
      setState(() {
        _isSharing = _locationService.isSharing;
      });

      if (_isSharing) {
        await _getCurrentPositionAndFetchUsers();
      } else {
        // Clear location data when stopping sharing
        await _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .update({
          'location': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling location sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle location sharing: $e')),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, h:mm a').format(timestamp.toDate());
    }
    return 'N/A';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: ValueKey(_isSharing),
              icon: Icon(
                _isSharing ? Icons.share_location : Icons.location_disabled,
                color: _isSharing ? Colors.green : Colors.red,
              ),
              onPressed: _toggleSharing,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getCurrentPositionAndFetchUsers,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Users: ${nearbyUsers.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isSharing ? 'Sharing Location' : 'Location Hidden',
                          style: TextStyle(
                            color: _isSharing ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: nearbyUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No nearby users found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: nearbyUsers.length,
                            itemBuilder: (context, index) {
                              final user = nearbyUsers[index];
                              return Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.primaries[
                                            index % Colors.primaries.length],
                                        child: Text(
                                          (user['email'] as String?)
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              '?',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['email'] ?? 'Unknown User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDistance(
                                                      user['distance'] ?? 0),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Last seen: ${_formatTimestamp(user['lastUpdated'])}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sendSOSNotification(context),
        label: const Text('SOS'),
        icon: const Icon(Icons.warning),
        backgroundColor: Colors.red,
      ),
    );
  }
}
