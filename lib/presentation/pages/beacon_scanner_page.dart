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

class _BeaconScannerPageState extends State<BeaconScannerPage>
    with SingleTickerProviderStateMixin {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  bool _isScanning = false;
  String _statusText = "Searching for your lock...";
  String _errorText = "";
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Target beacon information
  static const String TARGET_UUID = "0000abcd-1000-8000-00805f9b34fb";

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
        SnackBar(
          content: const Text('Please grant all required permissions'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.shade700,
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Lock Scanner",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildLiveIndicator(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(),

                const SizedBox(height: 24),

                // Scan animation and status
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animation for searching
                        _buildScanAnimation(),

                        const SizedBox(height: 32),

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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.shade800, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _errorText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isScanning ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "Live",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    _isScanning ? Colors.blue.shade700 : Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_searching,
                color: Colors.grey.shade200,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isScanning ? "Scanner Active" : "Scanner Idle",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isScanning
                        ? "Searching for nearby locks..."
                        : "Press scan to find nearby locks",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isScanning
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isScanning
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                  width: 1,
                ),
              ),
              child: Text(
                _isScanning ? "ACTIVE" : "IDLE",
                style: TextStyle(
                  color: _isScanning
                      ? Colors.green.shade400
                      : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanAnimation() {
    if (_isScanning) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Middle pulse
              Transform.scale(
                scale: (_pulseAnimation.value + 1) / 2,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Lock icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade700.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_outline,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Main scan button
        ElevatedButton(
          onPressed: _isScanning ? _stopScan : _startScan,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _isScanning ? Colors.red : Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isScanning ? Icons.stop : Icons.bluetooth_searching,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isScanning ? "Stop Scanning" : "Start Scanning",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Manual enter button
        TextButton(
          onPressed: () {
            // Navigate to manual lock selection
            _stopScan();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const FaceScan(
                  lockUuid: "0000abcd-0000-1000-8000-00805f9b34fb",
                ),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Enter Lock ID Manually",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
