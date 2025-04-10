import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class FaceScanScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const FaceScanScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device Found")),
      body: Center(
        child: Text(
          "Connected to ${device.name}\nID: ${device.id}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
