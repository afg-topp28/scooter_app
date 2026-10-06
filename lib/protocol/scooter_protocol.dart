import '../models/scooter_telemetry.dart';

abstract interface class ScooterProtocol {
  ScooterTelemetry? decodeTelemetry(List<int> packet);
  List<List<int>> buildTelemetryRequests();
  List<int> buildLockCommand();
  List<int> buildUnlockCommand();
  List<int> buildHeadlightCommand(bool enabled);
  List<int> buildTaillightCommand(bool enabled);
  Future<void> authenticate(Future<void> Function(List<int>) send, Stream<List<int>> incoming);
}
