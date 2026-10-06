import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/scooter_device.dart';
import '../models/scooter_telemetry.dart';
import '../protocol/scooter_protocol.dart';

enum ScooterConnectionState { disconnected, scanning, connecting, connected, error }

class BleScooterService {
  BleScooterService({required ScooterProtocol protocol}) : _protocol = protocol;
  final ScooterProtocol _protocol;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  final _devices = StreamController<ScooterDevice>.broadcast();
  final _telemetry = StreamController<ScooterTelemetry>.broadcast();
  final _states = StreamController<ScooterConnectionState>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  ScooterConnectionState _state = ScooterConnectionState.disconnected;

  Stream<ScooterDevice> get devices => _devices.stream;
  Stream<ScooterTelemetry> get telemetry => _telemetry.stream;
  Stream<ScooterConnectionState> get connectionState => _states.stream;
  Stream<Object> get errors => _errors.stream;
  ScooterConnectionState get state => _state;

  Future<void> requestPermissions() async {
    final result = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    if (result.values.any((p) => p.isDenied || p.isPermanentlyDenied)) {
      throw StateError('Required Bluetooth permissions were not granted.');
    }
  }

  Future<void> scan({Duration timeout = const Duration(seconds: 8)}) async {
    await requestPermissions();
    _setState(ScooterConnectionState.scanning);
    await FlutterBluePlus.stopScan();
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (!_looksLikeScooter(result)) continue;
        _devices.add(ScooterDevice.fromScanResult(result));
      }
    }, onError: _errors.add);
    FlutterBluePlus.cancelWhenScanComplete(sub);
    try {
      await FlutterBluePlus.startScan(timeout: timeout, removeIfGone: const Duration(seconds: 2), continuousUpdates: true);
      await FlutterBluePlus.isScanning.where((v) => !v).first;
      if (_device == null) _setState(ScooterConnectionState.disconnected);
    } catch (e) {
      _setState(ScooterConnectionState.error); _errors.add(e); rethrow;
    }
  }

  bool _looksLikeScooter(ScanResult r) {
    final name = '${r.advertisementData.advName} ${r.device.platformName}'.toLowerCase();
    const keys = ['xiaomi', 'mi scooter', 'ninebot', 'segway', 'm365', 'pro 2', '1s', 'g30', 'essential', 'e22', 'e25', 'e45'];
    return keys.any(name.contains);
  }

  Future<void> connect(ScooterDevice scooter) async {
    await FlutterBluePlus.stopScan();
    await _cleanupSubscriptions();
    _setState(ScooterConnectionState.connecting);
    _device = scooter.device;
    _connectionSubscription = _device!.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.connected) {
        try { await _onConnected(_device!); } catch (e) { _errors.add(e); _setState(ScooterConnectionState.error); }
      } else if (s == BluetoothConnectionState.disconnected) {
        _writeCharacteristic = null; _notifyCharacteristic = null;
        _setState(ScooterConnectionState.disconnected);
      }
    });
    _device!.cancelWhenDisconnected(_connectionSubscription!, delayed: true, next: true);
    try {
      await _device!.connect();
      await _device!.connectionState.where((s) => s == BluetoothConnectionState.connected).first;
    } catch (e) { _setState(ScooterConnectionState.error); _errors.add(e); rethrow; }
  }

  Future<void> _onConnected(BluetoothDevice device) async {
    final services = await device.discoverServices();
    _writeCharacteristic = null; _notifyCharacteristic = null;
    for (final service in services) {
      for (final c in service.characteristics) {
        if (_notifyCharacteristic == null && (c.properties.notify || c.properties.indicate)) _notifyCharacteristic = c;
        if (_writeCharacteristic == null && (c.properties.write || c.properties.writeWithoutResponse)) _writeCharacteristic = c;
      }
    }
    if (_notifyCharacteristic == null) throw StateError('No notification characteristic found.');
    if (_writeCharacteristic == null) throw StateError('No writable characteristic found.');
    await _notifyCharacteristic!.setNotifyValue(true);
    _notificationSubscription = _notifyCharacteristic!.onValueReceived.listen((packet) {
      try { final t = _protocol.decodeTelemetry(packet); if (t != null) _telemetry.add(t); } catch (e) { _errors.add(e); }
    }, onError: _errors.add);
    await _protocol.authenticate(_writeRaw, _notifyCharacteristic!.onValueReceived);
    _setState(ScooterConnectionState.connected);
    await requestTelemetry();
  }

  Future<void> requestTelemetry() async {
    for (final packet in _protocol.buildTelemetryRequests()) {
      await _writeRaw(packet);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _writeRaw(List<int> packet) async {
    final c = _writeCharacteristic;
    if (c == null) throw StateError('Scooter is not connected.');
    await c.write(packet, withoutResponse: c.properties.writeWithoutResponse && !c.properties.write);
  }

  Future<void> lock() => _writeRaw(_protocol.buildLockCommand());
  Future<void> unlock() => _writeRaw(_protocol.buildUnlockCommand());
  Future<void> setHeadlight(bool enabled) => _writeRaw(_protocol.buildHeadlightCommand(enabled));
  Future<void> setTaillight(bool enabled) => _writeRaw(_protocol.buildTaillightCommand(enabled));

  Future<void> disconnect() async {
    await _device?.disconnect();
    await _cleanupSubscriptions();
    _device = null; _writeCharacteristic = null; _notifyCharacteristic = null;
    _setState(ScooterConnectionState.disconnected);
  }

  Future<void> _cleanupSubscriptions() async {
    await _notificationSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _notificationSubscription = null; _connectionSubscription = null;
  }

  void _setState(ScooterConnectionState s) { _state = s; _states.add(s); }

  Future<void> dispose() async {
    await disconnect();
    await _devices.close(); await _telemetry.close(); await _states.close(); await _errors.close();
  }
}
