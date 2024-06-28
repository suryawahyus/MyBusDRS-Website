import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adjust the return type to properly reflect the nullable entries
  Stream<List<Map<String, dynamic>>> getAllBusLocations() {
    return _firestore.collection('buses').snapshots().map((snapshot) {
      List<Map<String, dynamic>> result =
          []; // Initialize a list to hold non-null results
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('position') &&
            data['position'] is GeoPoint &&
            data['speed'] != null) {
          GeoPoint geoPoint = data['position'];
          double? speed =
              (data['speed'] is num) ? data['speed'].toDouble() : 0.0;
          if (kDebugMode) {
            print(
                'Bus ${doc.id} position: ${geoPoint.latitude}, ${geoPoint.longitude}');
          }
          result.add({
            'busId': doc.id,
            'location': LatLng(geoPoint.latitude, geoPoint.longitude),
            'speed': speed
          });
        } else {
          if (kDebugMode) {
            print('Invalid or incomplete data for doc id: ${doc.id}');
          }
        }
      }
      return result; // Return the list of valid entries
    }).handleError((error) {
      if (kDebugMode) {
        print('Error fetching bus locations: $error');
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchBusLocationsFromFunctions() async {
    final response = await http.get(Uri.parse(
        'https://us-central1-mybussdrs-8eac9.cloudfunctions.net/getFirestoreData'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (kDebugMode) {
        print('Data received from functions: $data');
      }
      return data.map((item) {
        var position = item['position'] ?? {'_latitude': 0, '_longitude': 0};
        return {
          'busId': item['id'],
          'location': LatLng(position['_latitude'], position['_longitude']),
          'speed': item['speed']
              .toDouble() // Assuming speed is always available and a number.
        };
      }).toList();
    } else {
      if (kDebugMode) {
        print('Failed to load data from functions: ${response.statusCode}');
      }
      return [];
    }
  }
}
