import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/alert_model.dart';
class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  bool isLive = true;
  final List<ThreatModel> threats = [
    ThreatModel(
      alertLevel: AlertLevel.high,
      description: "Blocked Port Scanning attack from suspicious IP",
      source: "172.207.93.38",
      timestamp: DateTime.now().subtract(const Duration(seconds: 25)),
      status: ThreatStatus.blocked,
    ),
    ThreatModel(
      alertLevel: AlertLevel.high,
      description: "Blocked Port Scanning attack from suspicious IP",
      source: "39.12.5.15",
      timestamp: DateTime.now().subtract(const Duration(seconds: 40)),
      status: ThreatStatus.blocked,
    ),
    ThreatModel(
      alertLevel: AlertLevel.critical,
      description: "Blocked Malware attack from suspicious IP",
      source: "91.234.56.78",
      timestamp: DateTime.now().subtract(const Duration(seconds: 55)),
      status: ThreatStatus.blocked,
    ),
    ThreatModel(
      alertLevel: AlertLevel.critical,
      description: "Unauthorized login attempt",
      source: "103.45.67.89",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      status: ThreatStatus.investigating,
    ),
    ThreatModel(
      alertLevel: AlertLevel.medium,
      description: "Unusual network activity detected",
      source: "192.168.1.105",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      status: ThreatStatus.monitoring,
    ),
  ];

  int get criticalCount =>
      threats.where((t) => t.alertLevel == AlertLevel.critical).length;
  int get highCount =>
      threats.where((t) => t.alertLevel == AlertLevel.high).length;
  int get mediumCount =>
      threats.where((t) => t.alertLevel == AlertLevel.medium).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildAlertSummary(),
              const SizedBox(height: 24),
              _buildLiveThreatsHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildThreatsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, size: 28),
              const SizedBox(width: 8),
              Text(
                "Urgent Alerts",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLive = !isLive;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLive ? Colors.grey.shade800 : Colors.transparent,
              foregroundColor: isLive ? Colors.white : Colors.grey,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: isLive ? Colors.transparent : Colors.grey.shade800),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Live",
              style: TextStyle(
                fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildAlertCard(
            "Critical",
            criticalCount.toString(),
            Colors.red.shade400,
            Icons.gpp_bad_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAlertCard(
            "High",
            highCount.toString(),
            Colors.orange,
            Icons.gpp_maybe_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
      String title, String count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade300,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveThreatsHeader() {
    return Row(
      children: [
        Text(
          "Live Threats",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            setState(() {
              // Refresh functionality
            });
          },
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildThreatsList() {
    return ListView.builder(
      itemCount: threats.length,
      itemBuilder: (context, index) {
        final threat = threats[index];
        return _buildThreatCard(threat);
      },
    );
  }

  Widget _buildThreatCard(ThreatModel threat) {
    Color borderColor;
    switch (threat.alertLevel) {
      case AlertLevel.critical:
        borderColor = Colors.red.shade300;
        break;
      case AlertLevel.high:
        borderColor = Colors.orange;
        break;
      default:
        borderColor = Colors.yellow.shade700;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAlertLevelChip(threat.alertLevel),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(threat.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              threat.description,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Source: ",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                    ),
                    Text(
                      threat.source,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                _buildStatusChip(threat.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertLevelChip(AlertLevel level) {
    final Map<AlertLevel, Color> colors = {
      AlertLevel.critical: Colors.red.shade400,
      AlertLevel.high: Colors.orange,
      AlertLevel.medium: Colors.yellow.shade700,
    };

    final Map<AlertLevel, String> labels = {
      AlertLevel.critical: "CRITICAL",
      AlertLevel.high: "HIGH",
      AlertLevel.medium: "MEDIUM",
    };

    return level == AlertLevel.critical
        ? Chip(
            label: Text(
              labels[level]!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            backgroundColor: colors[level],
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          )
        : Text(
            labels[level]!,
            style: TextStyle(
              color: colors[level],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
  }

  Widget _buildStatusChip(ThreatStatus status) {
    final Map<ThreatStatus, Color> colors = {
      ThreatStatus.blocked: Colors.red.shade100,
      ThreatStatus.monitoring: Colors.blue.shade100,
      ThreatStatus.investigating: Colors.amber.shade100,
    };

    final Map<ThreatStatus, Color> textColors = {
      ThreatStatus.blocked: Colors.red.shade900,
      ThreatStatus.monitoring: Colors.blue.shade900,
      ThreatStatus.investigating: Colors.amber.shade900,
    };

    final Map<ThreatStatus, String> labels = {
      ThreatStatus.blocked: "BLOCKED",
      ThreatStatus.monitoring: "MONITORING",
      ThreatStatus.investigating: "INVESTIGATING",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors[status],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        labels[status]!,
        style: TextStyle(
          color: textColors[status],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

