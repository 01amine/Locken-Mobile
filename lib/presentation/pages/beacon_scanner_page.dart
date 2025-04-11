// File: lib/presentation/pages/beacon_scanner_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'scan_screen.dart';

class BeaconScannerPage extends StatefulWidget {
  const BeaconScannerPage({super.key});

  @override
  State<BeaconScannerPage> createState() => _BeaconScannerPageState();
}

class _BeaconScannerPageState extends State<BeaconScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  bool _isScanning = false;
  String _statusText = "Searching for your lock...";
  String _errorText = "";

  // Target beacon information - your friend's beacon
  static const String TARGET_UUID = "0000abcd-1000-8000-00805f9b34fb";
  //static const int TARGET_MAJOR = 100;
  //static const int TARGET_MINOR = 1;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartScan();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    // Check and request multiple permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
        setState(() {
          _errorText += "${permission.toString()} denied. ";
        });
      }
    });

    if (allGranted) {
      _startScan();
    } else {
      setState(() {
        _statusText = "Permissions required for smart lock";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant all required permissions'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _statusText = "Searching for your smart lock...";
      _errorText = "";
    });

    bool beaconFound = false;

    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        print("Device: ${device.id} (${device.name}) RSSI: ${device.rssi}");

        if (isTargetBeacon(device)) {
          beaconFound = true;
          print("TARGET FOUND: ${device.id}");
          _stopScan();
          _connectToBeacon(device);
        }
      },
      onError: (error) {
        setState(() {
          _errorText = "Scan error: $error";
          _isScanning = false;
        });
      },
    );

    // If no beacon is found in 15 seconds, navigate to face scan screen
    Future.delayed(const Duration(seconds: 15), () {
      if (!beaconFound && mounted) {
        _stopScan();
        setState(() {
          _statusText = "Lock 1";
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FaceScan(
                lockUuid: "0000abcd-0000-1000-8000-00805f9b34fb",
              ),
            ),
          );
        });
      }
    });
  }

  bool isTargetBeacon(DiscoveredDevice device) {
    // Check every possible way this could be our target beacon:

    // 1. Check service UUIDs directly
    if (device.serviceUuids.contains(TARGET_UUID)) {
      return true;
    }

    // 2. If the device has our special UUID in its ID
    if (device.id.contains("abcd")) {
      return true;
    }

    // 3. If the device has "beacon" in the name and is relatively close
    if (device.name.toLowerCase().contains("beacon") && device.rssi > -80) {
      return true;
    }

    // 4. Check raw manufacturer data for patterns
    if (device.manufacturerData.isNotEmpty) {
      // Convert manufacturer data to string to search for "abcd" pattern
      String hexData = device.manufacturerData
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      if (hexData.contains("abcd")) {
        return true;
      }
    }

    return false;
  }

  void _connectToBeacon(DiscoveredDevice device) {
    setState(() {
      _statusText = "Smart lock found! Connecting...";
    });

    // Small delay to update UI before navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Navigate to face scan screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FaceScan(
            lockUuid: "0000abcd-0000-1000-8000-00805f9b34fb",
          ),
        ),
      );
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  const Text(
                    "Smart Lock",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Animation for searching
                  if (_isScanning)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Status text
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (_errorText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 50),

                  // Manual scan button
                  ElevatedButton(
                    onPressed: _isScanning ? _stopScan : _startScan,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue.shade900,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isScanning ? "Stop Scanning" : "Start Scanning",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
