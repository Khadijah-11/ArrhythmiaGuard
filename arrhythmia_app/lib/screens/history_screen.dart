import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Detection History',
            style: TextStyle(color: Color(0xFF00E5FF))),
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: provider.history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No detections yet',
                      style: TextStyle(color: Colors.white38)),
                  SizedBox(height: 8),
                  Text('Connect to ESP32 and start monitoring',
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final record = provider.history[index];
                final labelColor = {
                  'N': const Color(0xFF00E676),
                  'S': const Color(0xFFFFD740),
                  'V': const Color(0xFFFF1744),
                  'F': const Color(0xFFFF6D00),
                  'Q': const Color(0xFF78909C),
                }[record.label] ?? Colors.white;

                final labelFull = {
                  'N': 'Normal',
                  'S': 'Supraventricular',
                  'V': 'Ventricular',
                  'F': 'Fusion',
                  'Q': 'Unclassifiable',
                }[record.label] ?? 'Unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1321),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: labelColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      // Label badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: labelColor.withOpacity(0.12),
                          border: Border.all(color: labelColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(record.label,
                              style: TextStyle(
                                  color: labelColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(labelFull,
                                style: TextStyle(
                                    color: labelColor,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                                '${record.heartRate} BPM  •  ${(record.confidence * 100).toStringAsFixed(1)}% confidence',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),

                      // Timestamp
                      Text(
                          '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}:${record.timestamp.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
