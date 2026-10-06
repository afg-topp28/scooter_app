class ScooterTelemetry {
  final double? speedKmh;
  final int? batteryPercent;
  final double? batteryVoltage;
  final double? controllerTemperature;
  final double? batteryTemperature;
  final bool? locked;
  final bool? headlightOn;
  final bool? taillightOn;
  final DateTime timestamp;

  const ScooterTelemetry({
    this.speedKmh,
    this.batteryPercent,
    this.batteryVoltage,
    this.controllerTemperature,
    this.batteryTemperature,
    this.locked,
    this.headlightOn,
    this.taillightOn,
    required this.timestamp,
  });

  ScooterTelemetry copyWith({
    double? speedKmh,
    int? batteryPercent,
    double? batteryVoltage,
    double? controllerTemperature,
    double? batteryTemperature,
    bool? locked,
    bool? headlightOn,
    bool? taillightOn,
  }) => ScooterTelemetry(
    speedKmh: speedKmh ?? this.speedKmh,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    batteryVoltage: batteryVoltage ?? this.batteryVoltage,
    controllerTemperature: controllerTemperature ?? this.controllerTemperature,
    batteryTemperature: batteryTemperature ?? this.batteryTemperature,
    locked: locked ?? this.locked,
    headlightOn: headlightOn ?? this.headlightOn,
    taillightOn: taillightOn ?? this.taillightOn,
    timestamp: DateTime.now(),
  );
}
