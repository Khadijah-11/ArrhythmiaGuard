import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final record = provider.history.isNotEmpty ? provider.history.first : null;
    final label = record?.label ?? provider.currentLabel;
    final confidence = record?.confidence ?? provider.confidence;

    final labelFull = {
      'N': 'Normal Sinus Rhythm',
      'S': 'Supraventricular Ectopy',
      'V': 'Ventricular Ectopy',
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

    final labelDescription = {
      'N': 'Normal sinus rhythm. The heartbeat originates normally from the sinus node and follows a regular, healthy pattern.',
      'S': 'Supraventricular ectopic beat. Originates above the ventricles, earlier than expected. Often benign but can indicate atrial issues if frequent.',
      'V': 'Premature ventricular contraction. Originates in the ventricles, disrupting the normal rhythm. Occasional PVCs are common; frequent ones warrant evaluation.',
      'F': 'Fusion beat. A normal and a ventricular beat occur simultaneously, producing a blended waveform.',
      'Q': 'Unclassifiable or paced beat. The morphology does not fit a standard category, or originates from a pacemaker.',
    }[label] ?? 'No description available.';

    final isAlert = label == 'V' || label == 'F';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Detection Result',
            style: TextStyle(color: Color(0xFF00E5FF))),
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Main result circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: labelColor, width: 4),
                color: labelColor.withOpacity(0.08),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: labelColor)),
                  Text(labelFull,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Confidence bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Model Confidence',
                          style: TextStyle(color: Colors.white70)),
                      Text('${(confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: labelColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(labelColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // What this means
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: labelColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: labelColor, size: 18),
                      const SizedBox(width: 8),
                      const Text('What this means',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(labelDescription,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13, height: 1.4)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Alert banner
            if (isAlert)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abnormal Rhythm Detected',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              label == 'V'
                                  ? 'Ventricular ectopy detected. Consult a cardiologist.'
                                  : 'Fusion beat detected. Monitor closely.',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Heart rate
            Row(
              children: [
                _StatCard(
                    label: 'Heart Rate',
                    value: '${provider.heartRate} BPM',
                    color: const Color(0xFFFF1744)),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1321),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deployed Model — ArrhythmiaGuard v1.0',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 6),
                  const Text('ChannelGate Fusion · Float32 ·  229.9 KB · Macro F1: 0.86',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1321),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}