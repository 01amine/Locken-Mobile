import 'package:flutter/material.dart';

class ScanStatusWidget extends StatelessWidget {
  final String status;

  const ScanStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Text(
      status,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
    );
  }
}
