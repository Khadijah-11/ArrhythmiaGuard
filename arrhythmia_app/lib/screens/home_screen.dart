import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'monitor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('ArrhythmiaGuard',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF))),
              const Text('ECG + PPG Fusion Monitor',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: provider.isConnected
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00E5FF),
                        width: 3),
                    color: const Color(0xFF0D1321),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        provider.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        size: 48,
                        color: provider.isConnected
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00E5FF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                            color: provider.isConnected
                                ? const Color(0xFF00E676)
                                : Colors.white54),
                      ),
                      if (provider.isConnected)
                        Text(provider.deviceName,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                            textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isConnected
                        ? Colors.red.shade900
                        : const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: provider.isScanning
                      ? null
                      : () {
                          if (provider.isConnected) {
                            provider.disconnect();
                          } else {
                            provider.startScan();
                          }
                        },
                  child: provider.isScanning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          provider.isConnected
                              ? 'Disconnect'
                              : 'Scan & Connect',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.isConnected)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MonitorScreen())),
                    child: const Text('Open Monitor',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}