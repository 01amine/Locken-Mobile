import 'package:flutter/material.dart';
import 'package:smart_lock/presentation/pages/beacon_scanner_page.dart';

void main() {
  runApp(MyBeaconApp());
}

class MyBeaconApp extends StatelessWidget {
  const MyBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: BeaconScannerPage());
  }
}
