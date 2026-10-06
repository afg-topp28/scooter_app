import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scooter_device.dart';
import '../models/scooter_telemetry.dart';
import '../protocol/generic_scooter_protocol.dart';
import '../services/ble_scooter_service.dart';

final scooterServiceProvider = Provider<BleScooterService>((ref) {
  final service = BleScooterService(protocol: const GenericScooterProtocol());
  ref.onDispose(service.dispose);
  return service;
});

class ScooterState {
  final List<ScooterDevice> devices;
  final ScooterTelemetry? telemetry;
  final ScooterConnectionState connectionState;
  final String? error;
  const ScooterState({this.devices = const [], this.telemetry, this.connectionState = ScooterConnectionState.disconnected, this.error});
  ScooterState copyWith({List<ScooterDevice>? devices, ScooterTelemetry? telemetry, ScooterConnectionState? connectionState, String? error, bool clearError = false}) => ScooterState(
    devices: devices ?? this.devices, telemetry: telemetry ?? this.telemetry,
    connectionState: connectionState ?? this.connectionState,
    error: clearError ? null : error ?? this.error,
  );
}

class ScooterController extends Notifier<ScooterState> {
  late final BleScooterService _service;
  StreamSubscription<ScooterDevice>? _devices;
  StreamSubscription<ScooterTelemetry>? _telemetry;
  StreamSubscription<ScooterConnectionState>? _states;
  StreamSubscription<Object>? _errors;

  @override
  ScooterState build() {
    _service = ref.read(scooterServiceProvider);
    _devices = _service.devices.listen((d) {
      final list = [...state.devices.where((x) => x.id != d.id), d]..sort((a,b) => b.rssi.compareTo(a.rssi));
      state = state.copyWith(devices: list);
    });
    _telemetry = _service.telemetry.listen((t) => state = state.copyWith(telemetry: t, clearError: true));
    _states = _service.connectionState.listen((s) => state = state.copyWith(connectionState: s));
    _errors = _service.errors.listen((e) => state = state.copyWith(error: e.toString()));
    ref.onDispose(() async { await _devices?.cancel(); await _telemetry?.cancel(); await _states?.cancel(); await _errors?.cancel(); });
    return const ScooterState();
  }
  Future<void> scan() async { try { await _service.scan(); } catch (e) { state = state.copyWith(error: e.toString(), connectionState: ScooterConnectionState.error); } }
  Future<void> connect(ScooterDevice d) async { try { await _service.connect(d); } catch (e) { state = state.copyWith(error: e.toString(), connectionState: ScooterConnectionState.error); } }
  Future<void> disconnect() => _service.disconnect();
  Future<void> refresh() => _service.requestTelemetry();
  Future<void> lock() => _service.lock();
  Future<void> unlock() => _service.unlock();
  Future<void> setHeadlight(bool e) => _service.setHeadlight(e);
  Future<void> setTaillight(bool e) => _service.setTaillight(e);
}

final scooterControllerProvider = NotifierProvider<ScooterController, ScooterState>(ScooterController.new);
