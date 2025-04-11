import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/log_entry_model.dart';
class SecurityLogsScreen extends StatefulWidget {
  const SecurityLogsScreen({super.key});

  @override
  State<SecurityLogsScreen> createState() => _SecurityLogsScreenState();
}

class _SecurityLogsScreenState extends State<SecurityLogsScreen> {
  String selectedFilter = 'All Threats';
  final TextEditingController _searchController = TextEditingController();
  List<LogEntry> filteredLogs = [];
  
  final List<String> filterOptions = [
    'All Threats',
    'Critical Only',
    'High Only',
    'Medium Only',
    'Low Only',
    'Flagged Items',
    'Allowed Items',
  ];

  final List<LogEntry> logs = [
    LogEntry(
      severity: Severity.medium,
      description: "Potential Phishing attempt detected",
      source: "30.85.74.252",
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      status: LogStatus.flagged,
    ),
    LogEntry(
      severity: Severity.medium,
      description: "Potential Phishing attempt detected",
      source: "1.244.245.57",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      status: LogStatus.flagged,
    ),
    LogEntry(
      severity: Severity.low,
      description: "Unusual traffic pattern detected, possible Man-in-the-Middle",
      source: "169.113.75.147",
      timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
      status: LogStatus.allowed,
    ),
    LogEntry(
      severity: Severity.critical,
      description: "Brute force attack on admin portal",
      source: "45.67.89.123",
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      status: LogStatus.blocked,
    ),
    LogEntry(
      severity: Severity.high,
      description: "Multiple failed login attempts",
      source: "192.168.1.45",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      status: LogStatus.flagged,
    ),
    LogEntry(
      severity: Severity.low,
      description: "Endpoint security update failed",
      source: "Internal System",
      timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      status: LogStatus.resolved,
    ),
    LogEntry(
      severity: Severity.medium,
      description: "Unauthorized file access attempt",
      source: "10.0.0.15",
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      status: LogStatus.investigating,
    ),
  ];

  @override
  void initState() {
    super.initState();
    filteredLogs = List.from(logs);
    _searchController.addListener(_filterLogs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLogs() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredLogs = logs.where((log) {
        final matchesSearch = searchTerm.isEmpty ||
            log.description.toLowerCase().contains(searchTerm) ||
            log.source.toLowerCase().contains(searchTerm);

        final matchesFilter = switch (selectedFilter) {
          'All Threats' => true,
          'Critical Only' => log.severity == Severity.critical,
          'High Only' => log.severity == Severity.high,
          'Medium Only' => log.severity == Severity.medium,
          'Low Only' => log.severity == Severity.low,
          'Flagged Items' => log.status == LogStatus.flagged,
          'Allowed Items' => log.status == LogStatus.allowed,
          _ => true,
        };

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterDropdown(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildLogsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.menu, size: 28),
        const SizedBox(width: 16),
        Text(
          "Security Logs",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search logs...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: selectedFilter,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            elevation: 16,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF212121),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedFilter = newValue;
                  _filterLogs();
                });
              }
            },
            items: filterOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 20),
                      const SizedBox(width: 16),
                      Text(value),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(LogEntry log) {
    // Define colors based on severity
    Color borderColor;
    switch (log.severity) {
      case Severity.critical:
        borderColor = Colors.red.shade600;
      case Severity.high:
        borderColor = Colors.orange.shade600;
      case Severity.medium:
        borderColor = Colors.yellow;
      case Severity.low:
        borderColor = Colors.green.shade400;
      }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(8),
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
                _buildSeverityChip(log.severity),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              log.description,
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
                      log.source,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                _buildStatusChip(log.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(Severity severity) {
    final Map<Severity, Color> colors = {
      Severity.critical: Colors.red.shade400,
      Severity.high: Colors.orange,
      Severity.medium: Colors.yellow,
      Severity.low: Colors.green.shade300,
    };

    final Map<Severity, String> labels = {
      Severity.critical: "CRITICAL",
      Severity.high: "HIGH",
      Severity.medium: "MEDIUM",
      Severity.low: "LOW",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[severity]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors[severity]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        labels[severity]!,
        style: TextStyle(
          color: colors[severity],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusChip(LogStatus status) {
    final Map<LogStatus, Color> colors = {
      LogStatus.flagged: Colors.yellow,
      LogStatus.allowed: Colors.green.shade300,
      LogStatus.blocked: Colors.red.shade300,
      LogStatus.investigating: Colors.blue.shade300,
      LogStatus.resolved: Colors.purple.shade300,
    };

    final Map<LogStatus, String> labels = {
      LogStatus.flagged: "flagged",
      LogStatus.allowed: "allowed",
      LogStatus.blocked: "blocked",
      LogStatus.investigating: "investigating",
      LogStatus.resolved: "resolved",
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors[status]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        labels[status]!,
        style: TextStyle(
          color: colors[status],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

