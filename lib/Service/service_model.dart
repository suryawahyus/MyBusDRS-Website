import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final LatLngBounds? bounds;
  final List<PointLatLng>? polylinePoints;
  final String? totalDistance;
  final String? totalDuration;

  const Directions({
    this.bounds,
    this.polylinePoints,
    this.totalDistance,
    this.totalDuration,
  });

  factory Directions.fromMap(Map<String, dynamic> map) {
    if (map['routes'] is! List || (map['routes'] as List).isEmpty) {
      throw const FormatException("No routes found");
    }

    final data = Map<String, dynamic>.from(map['routes'][0]);

    final northeast = data['bounds']?['northeast'];
    final southwest = data['bounds']?['southwest'];
    final bounds = (northeast != null && southwest != null)
        ? LatLngBounds(
            northeast: LatLng(northeast['lat'], northeast['lng']),
            southwest: LatLng(southwest['lat'], southwest['lng']),
          )
        : null;

    String? distance;
    String? duration;
    if (data['legs'] is List && (data['legs'] as List).isNotEmpty) {
      final leg = data['legs'][0];
      distance = leg['distance']?['text'];
      duration = leg['duration']?['text'];
    }

    List<PointLatLng>? polylinePoints;
    if (data.containsKey('overview_polyline')) {
      polylinePoints = PolylinePoints()
          .decodePolyline(data['overview_polyline']?['points'] ?? '');
    }

    return Directions(
      bounds: bounds,
      polylinePoints: polylinePoints,
      totalDistance: distance,
      totalDuration: duration,
    );
  }
}
