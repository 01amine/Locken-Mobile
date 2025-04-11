// Models
enum Severity { critical, high, medium, low }

enum LogStatus { flagged, allowed, blocked, investigating, resolved }

class LogEntry {
  final Severity severity;
  final String description;
  final String source;
  final DateTime timestamp;
  final LogStatus status;

  LogEntry({
    required this.severity,
    required this.description,
    required this.source,
    required this.timestamp,
    required this.status,
  });
}