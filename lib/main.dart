import 'package:flutter/material.dart';
//import 'package:smart_lock/presentation/pages/beacon_scanner_page.dart';
import 'package:smart_lock/presentation/pages/scan_screen.dart';

void main() {
  runApp(MyBeaconApp());
}

class MyBeaconApp extends StatelessWidget {
  const MyBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FaceScan(
        lockUuid: "0000abcd-0000-1000-8000-00805f9b34fb",
      ),
    );
  }
}
