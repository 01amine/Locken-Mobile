import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleScannerService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice> startScan({
  required Function(DiscoveredDevice) onDeviceFound,
  required Function(Object) onError,
}) {
  return _ble.scanForDevices(
    withServices: [], 
    scanMode: ScanMode.lowLatency,
  ).listen(
    onDeviceFound,
    onError: onError,
  );
}

  void stopScan(StreamSubscription<DiscoveredDevice>? subscription) {
    subscription?.cancel();
  }
}
