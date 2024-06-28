import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimationBus extends StatefulWidget {
  final Function(String) onBusIconTap;

  const AnimationBus({super.key, required this.onBusIconTap});

  @override
  // ignore: library_private_types_in_public_api
  _AnimationBusState createState() => _AnimationBusState();
}

class _AnimationBusState extends State<AnimationBus>
    with TickerProviderStateMixin {
  List<double> progress = [0.0, 0.0, 0.0];
  List<AnimationController> controllers = [];
  List<Animation<double>> animations = [];
  List<StreamSubscription<DocumentSnapshot>> subscriptions = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      var controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      controllers.add(controller);

      var animation = Tween<double>(begin: 0.0, end: 0.0).animate(controller)
        ..addListener(() {
          setState(() {
            progress[i] = animations[i].value;
          });
        });
      animations.add(animation);

      var subscription = FirebaseFirestore.instance
          .collection('buses')
          .doc('bus$i')
          .snapshots()
          .listen((snapshot) {
        var data = snapshot.data();
        if (data != null && data['speed'] != null) {
          double? speed = double.tryParse(data['speed'].toString());
          if (speed != null && speed > 5.0) {
            double newPosition = progress[i] + 0.1;
            newPosition = newPosition.clamp(0.0, 1.0);
            if (newPosition != progress[i]) {
              animations[i] = Tween<double>(
                begin: progress[i],
                end: newPosition,
              ).animate(controllers[i]);
              if (!controllers[i].isAnimating) {
                controllers[i].forward(from: 0.0);
              }
            }
          }
        }
      });
      subscriptions.add(subscription);
    }
  }

  @override
  void dispose() {
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBusRow('Bus 1', 'images/buss_icon_red.svg',
              'images/buss_icon2_red.svg', Colors.red, progress[0], 'bus1'),
          _buildBusRow(
              'Bus 2',
              'images/buss_icon_yellow.svg',
              'images/buss_icon2_yellow.svg',
              Colors.yellow,
              progress[1],
              'bus2'),
          _buildBusRow('Bus 3', 'images/buss_icon_blue.svg',
              'images/buss_icon2_blue.svg', Colors.blue, progress[2], 'bus3'),
        ],
      ),
    );
  }

  Widget _buildBusRow(String busName, String assetName, String busIcon2,
      Color color, double progress, String busId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _buildBusContainer(busName, assetName),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                _buildBusRoute(color),
                Positioned(
                  left: 20 + progress * 160,
                  child: GestureDetector(
                    onTap: () => widget.onBusIconTap(busId),
                    child: SizedBox(
                      width: 60,
                      height: 70,
                      child: SvgPicture.asset(busIcon2),
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

  Widget _buildBusContainer(String busName, String assetName) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0500FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            busName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            width: 70,
            height: 60,
            child: SvgPicture.asset(assetName),
          ),
        ],
      ),
    );
  }

  Widget _buildBusRoute(Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            height: 4,
            color: color,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
