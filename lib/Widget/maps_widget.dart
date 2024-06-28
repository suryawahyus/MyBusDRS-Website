import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mybusdrs_website/Service/firebase_service.dart';
import 'package:mybusdrs_website/Service/service_api.dart';
import 'package:provider/provider.dart';

class BusLocationsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _busLocations = [];

  List<Map<String, dynamic>> get busLocations => _busLocations;

  void updateBusLocations(List<Map<String, dynamic>> newLocations) {
    _busLocations = newLocations;
    notifyListeners();
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.onMapCreated});
  final void Function(GoogleMapController controller) onMapCreated;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng originHalte =
      LatLng(-6.972298578308109, 107.63625816087101);
  static const LatLng destinationHalte =
      LatLng(-6.937816546171037, 107.62343455506435);

  BitmapDescriptor halteIconA = BitmapDescriptor.defaultMarker;
  BitmapDescriptor halteIconB = BitmapDescriptor.defaultMarker;
  BitmapDescriptor halteIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor busIconA = BitmapDescriptor.defaultMarker;
  BitmapDescriptor busIconB = BitmapDescriptor.defaultMarker;
  BitmapDescriptor busIconC = BitmapDescriptor.defaultMarker;

  Map<PolylineId, Polyline> polylines = {};
  late GoogleMapController mapController;
  String? mapStyle;

  Set<Marker> markers = {};
  Set<Marker> dynamicMarkers = {};

  FirebaseService firebaseService = FirebaseService();
  DirectionsRepository directionsRepository = DirectionsRepository(dio: Dio());

  @override
  void initState() {
    super.initState();
    loadMapStyle();
    getPolyPoints();
    setCustomMarkerIcon();
    addStaticMarkers();
    loadBusLocations();
  }

  Future<void> loadMapStyle() async {
    final String style =
        await rootBundle.loadString('assets/maps_style_drs.json');
    if (mounted) {
      setState(() {
        mapStyle = style;
      });
    }
  }

  Future<void> getPolyPoints() async {
    try {
      final directions = await directionsRepository.getDirections(
        origin: originHalte,
        destination: destinationHalte,
      );

      if (mounted && directions.polylinePoints!.isNotEmpty) {
        setState(() {
          polylines[const PolylineId("route")] = Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blueAccent,
            points: directions.polylinePoints!
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
          );
        });
      } else {
        if (kDebugMode) {
          print("Failed to get route points");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching directions: $e");
      }
    }
  }

  Future<void> setCustomMarkerIcon() async {
    const ImageConfiguration config =
        ImageConfiguration(size: Size(40.0, 40.0));
    halteIconA =
        await BitmapDescriptor.asset(config, "images/halte_icon_new.png");
    halteIconB =
        await BitmapDescriptor.asset(config, "images/halte_icon_new.png");
    halteIcon = await BitmapDescriptor.asset(config, "images/halte_icon.png");
    busIconA = await BitmapDescriptor.asset(config, "images/icon_bus_red.png");
    busIconB =
        await BitmapDescriptor.asset(config, "images/icon_bus_yellow.png");
    busIconC = await BitmapDescriptor.asset(config, "images/icon_bus_blue.png");

    addStaticMarkers();
  }

  Set<Marker> _createMarkers(List<Map<String, dynamic>> busLocations) {
    Set<Marker> newMarkers = {};

    newMarkers.addAll(markers);

    for (var bus in busLocations) {
      LatLng position = bus['location'];
      if (position.latitude != 0 && position.longitude != 0) {
        BitmapDescriptor icon;
        switch (bus['busId']) {
          case 'bus1':
            icon = busIconA;
            break;
          case 'bus2':
            icon = busIconB;
            break;
          case 'bus3':
            icon = busIconC;
            break;
          default:
            icon = halteIcon;
        }
        newMarkers.add(
          Marker(
            markerId: MarkerId(bus['busId']),
            icon: icon,
            position: position,
          ),
        );
      }
    }

    return newMarkers;
  }

  void addStaticMarkers() {
    markers.add(
      Marker(
        markerId: const MarkerId("halte_A"),
        icon: halteIconA,
        position: originHalte,
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId("halte_B"),
        icon: halteIconB,
        position: destinationHalte,
      ),
    );
  }

  Future<void> loadBusLocations() async {
    final busLocations = await firebaseService.fetchBusLocationsFromFunctions();
    setState(() {
      dynamicMarkers = _createMarkers(busLocations);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Consumer<BusLocationsProvider>(
              builder: (context, busLocationsProvider, child) {
                return GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    widget.onMapCreated(controller);
                    if (mapStyle != null) {
                      // ignore: deprecated_member_use
                      controller.setMapStyle(mapStyle);
                    }
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-6.9589278, 107.6366338),
                    zoom: 14,
                  ),
                  mapType: MapType.normal,
                  trafficEnabled: true,
                  polylines: Set<Polyline>.of(polylines.values),
                  markers: _createMarkers(busLocationsProvider.busLocations),
                );
              },
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebaseService.getAllBusLocations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                if (kDebugMode) {
                  print("Error: ${snapshot.error}");
                }
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Provider.of<BusLocationsProvider>(context, listen: false)
                        .updateBusLocations(snapshot.data!);
                  }
                });
                return Container();
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }
}
