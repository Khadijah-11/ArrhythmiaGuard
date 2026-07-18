import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/detection_record.dart';
import 'package:permission_handler/permission_handler.dart';

class AppProvider extends ChangeNotifier {
  bool isConnected = false;
  bool isScanning = false;
  String deviceName = '';
  int heartRate = 0;
  double spo2 = 0;
  int abnormalCount = 0;
  String currentLabel = 'N';
  double confidence = 0.99;
  List<double> ecgData = List.filled(100, 0);
  List<double> ppgData = List.filled(100, 0);
  List<DetectionRecord> history = [];

  static const String targetName = 'ArrhythmiaGuard';
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String charUuid    = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String streamUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothDevice? _device;
  StreamSubscription? _scanSub;
  StreamSubscription? _charSub;
  StreamSubscription? _connSub;

 

  final Map<int, String> _classMap = {0: 'N', 1: 'S', 2: 'V', 3: 'F', 4: 'Q'};

  void startScan() async {
    isScanning = true;
    notifyListeners();

    // Request runtime permissions (Android 12+)
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (await FlutterBluePlus.isSupported == false) {
      isScanning = false;
      notifyListeners();
      return;
    }

    // wrap scan in try/catch so a failure doesn't leave UI stuck
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      isScanning = false;
      notifyListeners();
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.platformName == targetName) {
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();
          _connectToDevice(r.device);
          break;
        }
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (!isConnected) {
        isScanning = false;
        notifyListeners();
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    _device = device;
    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (_) {}

    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        isConnected = false;
        deviceName = '';
        
        notifyListeners();
      }
    });

    isConnected = true;
    isScanning = false;
    deviceName = device.platformName;
    notifyListeners();

    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (final c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == charUuid.toLowerCase()) {
            await c.setNotifyValue(true);
            _charSub = c.lastValueStream.listen(_onBleData);
          }
          if (c.uuid.toString().toLowerCase() == streamUuid.toLowerCase()) {   
            await c.setNotifyValue(true);                                       
            c.lastValueStream.listen(_onStreamData);                           
          }              
        }
      }
    }

    
  }

  void _onBleData(List<int> value) {
    if (value.length < 2) return;
    final classIdx = value[0];
    final conf = value[1] / 100.0;
    if (value.length >= 3) {
      heartRate = value[2];
    }

    currentLabel = _classMap[classIdx] ?? 'Q';
    confidence = conf;

    if (currentLabel == 'S' || currentLabel == 'V' || currentLabel == 'F') {
      abnormalCount++;
    }

    history.insert(0, DetectionRecord(
      label: currentLabel,
      confidence: confidence,
      timestamp: DateTime.now(),
      heartRate: heartRate,
    ));
    if (history.length > 50) history.removeLast();
    notifyListeners();
  }

  void disconnect() async {
    _charSub?.cancel();
    _connSub?.cancel();
   
    try { await _device?.disconnect(); } catch (_) {}
    isConnected = false;
    deviceName = '';
    notifyListeners();
  }

  void _onStreamData(List<int> value) {
    if (value.length < 3) return;
    // Map 0..255 back to ~-1..1 for chart
    final ecg = (value[0] / 255.0) * 2.0 - 1.0;
    // Map 0..255 to 0..1 for PPG chart
    final ppg = value[1] / 255.0;
    
    // SpO2 is sent as raw byte
    spo2 = value[2].toDouble();

    // Shift data for rolling chart
    ecgData = [...ecgData.sublist(1), ecg];
    ppgData = [...ppgData.sublist(1), ppg];
    
    // Note: We notifyListeners here to drive the 20Hz chart update
    notifyListeners();
  }
}