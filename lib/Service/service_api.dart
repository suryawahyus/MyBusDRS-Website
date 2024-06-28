import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mybusdrs_website/Service/service_model.dart';

class DirectionsRepository {
  final Dio _dio;

  final String baseUrl =
      "https://us-central1-mybussdrs-8eac9.cloudfunctions.net";

  DirectionsRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directions> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        "$baseUrl/getDirections",
        queryParameters: {
          "origin": "${origin.latitude},${origin.longitude}",
          "destination": "${destination.latitude},${destination.longitude}",
          "mode": "driving",
        },
      );

      if (kDebugMode) {
        print(
            'Directions request: origin=${origin.toString()}, destination=${destination.toString()}');
        print('Directions response: ${response.data}');
      }

      if (response.statusCode == 200) {
        return Directions.fromMap(response.data);
      } else {
        throw Exception(
            "Failed to fetch directions: ${response.statusCode} ${response.statusMessage} ${response.data}");
      }
    } catch (e) {
      throw Exception("Failed to fetch directions: $e");
    }
  }

  Future<Map<String, dynamic>> getDistanceMatrix({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        "$baseUrl/getDistanceMatrix",
        queryParameters: {
          "origins": "${origin.latitude},${origin.longitude}",
          "destinations": "${destination.latitude},${destination.longitude}",
          "traffic_model": "best_guess",
          "departure_time": "now",
          "mode": "driving",
        },
      );

      if (kDebugMode) {
        print(
            'Distance Matrix request: origins=${origin.toString()}, destinations=${destination.toString()}');
        print('Distance Matrix response: ${response.data}');
      }

      if (response.statusCode == 200 &&
          response.data["rows"][0]["elements"][0]["status"] == "OK") {
        var element = response.data["rows"][0]["elements"][0];
        return {
          "duration_text": element["duration"]["text"],
          "duration_value": element["duration"]["value"],
          "distance_text": element["distance"]["text"],
          "distance_value": element["distance"]["value"],
        };
      } else {
        throw Exception(
            "Failed to fetch ETA: ${response.statusCode} ${response.statusMessage} ${response.data}");
      }
    } catch (e) {
      throw Exception("Failed to fetch ETA: $e");
    }
  }
}
