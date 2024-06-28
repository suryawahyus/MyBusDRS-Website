import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mybusdrs_website/Service/clock.dart';
import 'package:mybusdrs_website/Service/firebase_service.dart';
import 'package:mybusdrs_website/Service/service_api.dart';

class ScheduleBus extends StatefulWidget {
  const ScheduleBus({super.key});

  @override
  State<ScheduleBus> createState() => _ScheduleBusState();
}

class _ScheduleBusState extends State<ScheduleBus> {
  static const LatLng halteBposition =
      LatLng(-6.937816546171037, 107.62343455506435);
  FirebaseService firebaseService = FirebaseService();
  DirectionsRepository directionsRepository = DirectionsRepository(dio: Dio());
  Map<String, Map<String, dynamic>> busData = {};

  @override
  void initState() {
    super.initState();
    updateBusData();
  }

  final TextStyle busInfoStyle = const TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    height: 0,
  );

  void updateBusData() async {
    try {
      final allBusLocations =
          await firebaseService.fetchBusLocationsFromFunctions();
      for (var busLocation in allBusLocations) {
        try {
          if (kDebugMode) {
            print('Received data from Functions: $busLocation');
          }
          String busId = busLocation['busId'];
          LatLng? busPosition = busLocation['location'];
          double? speed = busLocation['speed'];

          if (busPosition == null || speed == null) {
            if (kDebugMode) {
              print('Invalid position or speed for bus: $busLocation');
            }
            continue;
          }

          final busIdRegex = RegExp(r'^bus(\d+)$');
          final match = busIdRegex.firstMatch(busId);
          if (match == null) {
            if (kDebugMode) {
              print('Invalid busId format: $busId');
            }
            continue;
          }

          int index = int.parse(match.group(1)!);
          String busIndexKey = 'Bus $index';

          // Mendapatkan jarak dan ETA dari Google Distance Matrix API
          var etaData = await directionsRepository.getDistanceMatrix(
            origin: busPosition,
            destination: halteBposition,
          );

          if (kDebugMode) {
            print('ETA data: $etaData');
          }

          double etaMinutes =
              // ignore: unnecessary_null_comparison
              etaData != null ? etaData['duration_value'] / 60 : 0.0;
          double googleDistance = etaData['distance_value'] != null
              ? etaData['distance_value'] / 1000
              : 0.0;

          setState(() {
            busData.putIfAbsent(
                busIndexKey,
                () => {
                      'bus': busIndexKey,
                      'halte': 'Halte B',
                      'position': const LatLng(0, 0),
                      'jarak': 'N/A',
                      'estimation': 'Estimasi tidak tersedia'
                    });

            busData[busIndexKey]!['position'] = busPosition;
            busData[busIndexKey]!['jarak'] =
                '${googleDistance.toStringAsFixed(2)} km';
            busData[busIndexKey]!['estimation'] =
                '${etaMinutes.toStringAsFixed(0)} menit ke halte';
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error updating bus data: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching bus locations from functions: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(41, 0, 41, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimasi Kedatangan Bus',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Clock(),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 21),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                          'Bus',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 0,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Text(
                          'Sampai ke halte',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 0,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Text(
                          'Jarak',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 0,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Text(
                          'Estimasi Kedatangan',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 5,
                  color: Colors.black,
                ),
                ...busData.values.map(
                  (bus) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 21),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bus['bus'], style: busInfoStyle),
                        Text(bus['halte'], style: busInfoStyle),
                        Text(bus['jarak'], style: busInfoStyle),
                        Text(bus['estimation'], style: busInfoStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
