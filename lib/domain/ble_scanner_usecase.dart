import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../data/scanner_service.dart';

class BleScannerUseCase {
  final BleScannerService _service = BleScannerService();

  StreamSubscription<DiscoveredDevice> scanForTargetDevice({
    required Function(DiscoveredDevice) onFound,
    required Function(Object error) onError,
  }) {
    return _service.startScan(
      onDeviceFound: onFound,
      onError: onError,
    );
  }

  void stopScan(StreamSubscription<DiscoveredDevice>? subscription) {
    _service.stopScan(subscription);
  }
}
