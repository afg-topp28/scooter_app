import '../models/scooter_telemetry.dart';
import 'scooter_protocol.dart';

/// Deliberately does not invent Xiaomi/Ninebot packet layouts.
/// Replace this adapter with a verified model+firmware implementation.
class GenericScooterProtocol implements ScooterProtocol {
  const GenericScooterProtocol();

  @override
  ScooterTelemetry? decodeTelemetry(List<int> packet) => null;

  @override
  List<List<int>> buildTelemetryRequests() => const [];

  Never _unsupported(String operation) => UnsupportedError(
        '$operation is not configured for this scooter profile.',
      );

  @override
  List<int> buildLockCommand() => throw _unsupported('Lock');
  @override
  List<int> buildUnlockCommand() => throw _unsupported('Unlock');
  @override
  List<int> buildHeadlightCommand(bool enabled) => throw _unsupported('Headlight');
  @override
  List<int> buildTaillightCommand(bool enabled) => throw _unsupported('Taillight');

  @override
  Future<void> authenticate(Future<void> Function(List<int>) send, Stream<List<int>> incoming) async {}
}
