import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mybusdrs_website/Widget/animations_widget.dart';
import 'package:mybusdrs_website/Widget/maps_widget.dart';
import 'package:mybusdrs_website/Widget/schedule_widget.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyCAyBWjk98_t4w2gDSlA2ofkaCfHnbrPvQ",
            authDomain: "mybussdrs-8eac9.firebaseapp.com",
            databaseURL:
                "https://mybussdrs-8eac9-default-rtdb.asia-southeast1.firebasedatabase.app",
            projectId: "mybussdrs-8eac9",
            storageBucket: "mybussdrs-8eac9.appspot.com",
            messagingSenderId: "387806559771",
            appId: "1:387806559771:web:5f0991ad9c901a008e42be",
            measurementId: "G-L5HSNDSBVP",
          )
        : null,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BusLocationsProvider(),
      child: const MaterialApp(
        title: 'monitoring',
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showAnimationWidget = false;
  bool showScheduleWidget = false;
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _moveCameraToBus(String busId) {
    if (mapController != null) {
      final busMarker =
          markers.firstWhere((marker) => marker.markerId.value == busId);
      mapController!.animateCamera(CameraUpdate.newLatLng(busMarker.position));
    } else {
      if (kDebugMode) {
        print("Map controller is not initialized.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          MapScreen(onMapCreated: _onMapCreated),
          Positioned(
            bottom: 10,
            left: 10,
            child: Row(
              children: [
                const Padding(padding: EdgeInsets.only(right: 100)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAnimationWidget = !showAnimationWidget;
                      showScheduleWidget = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Animation'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showScheduleWidget = !showScheduleWidget;
                      showAnimationWidget = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Schedule'),
                ),
              ],
            ),
          ),
          if (showAnimationWidget)
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: IntrinsicHeight(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: AnimationBus(
                    onBusIconTap: _moveCameraToBus,
                  ),
                ),
              ),
            ),
          if (showScheduleWidget)
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: IntrinsicHeight(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: const ScheduleBus(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
