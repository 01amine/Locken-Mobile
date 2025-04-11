// Models
enum AlertLevel { critical, high, medium }

enum ThreatStatus { blocked, monitoring, investigating }

class ThreatModel {
  final AlertLevel alertLevel;
  final String description;
  final String source;
  final DateTime timestamp;
  final ThreatStatus status;

  ThreatModel({
    required this.alertLevel,
    required this.description,
    required this.source,
    required this.timestamp,
    required this.status,
  });
}
