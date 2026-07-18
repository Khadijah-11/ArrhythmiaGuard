import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final label = provider.currentLabel;
    final labelFull = {
      'N': 'Normal Sinus Rhythm',
      'S': 'Supraventricular',
      'V': 'Ventricular',
      'F': 'Fusion Beat',
      'Q': 'Unclassifiable',
    }[label] ?? 'Unknown';
    final labelColor = {
      'N': const Color(0xFF00E676),
      'S': const Color(0xFFFFD740),
      'V': const Color(0xFFFF1744),
      'F': const Color(0xFFFF6D00),
      'Q': const Color(0xFF78909C),
    }[label] ?? Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Live Monitor',
            style: TextStyle(color: Color(0xFF00E5FF))),
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Heart Rate + Beats analyzed
            Row(
              children: [
                _VitalCard(
                    label: 'Heart Rate',
                    value: '${provider.heartRate}',
                    unit: 'BPM',
                    icon: Icons.favorite,
                    color: const Color(0xFFFF1744)),
                const SizedBox(width: 12),
                _VitalCard(
                    label: 'Abnormal Beats',
                    value: '${provider.abnormalCount}',
                    unit: '',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFFD740)),
              ],
            ),
            const SizedBox(height: 16),

            // Current Rhythm card (real, live)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: labelColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: labelColor.withOpacity(0.12),
                      border: Border.all(color: labelColor, width: 2),
                    ),
                    child: Center(
                      child: Text(label,
                          style: TextStyle(
                              color: labelColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Rhythm',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(labelFull,
                            style: TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                            'Confidence: ${(provider.confidence * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bigger ECG chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ECG Signal (live)',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minY: -1.5,
                        maxY: 1.5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: provider.ecgData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: const Color(0xFF00E676),
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF00E676).withOpacity(0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.analytics),
                label: const Text('View Detection Result',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ResultScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;

  const _VitalCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1321),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 10)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: color,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (unit.isNotEmpty) const SizedBox(width: 3),
                      if (unit.isNotEmpty)
                        Text(unit,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}