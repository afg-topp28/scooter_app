import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScooterDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  const ScooterDevice({required this.device, required this.name, required this.rssi});

  String get id => device.remoteId.str;

  factory ScooterDevice.fromScanResult(ScanResult result) {
    final adv = result.advertisementData.advName.trim();
    final platform = result.device.platformName.trim();
    return ScooterDevice(
      device: result.device,
      name: adv.isNotEmpty ? adv : (platform.isNotEmpty ? platform : 'Unknown scooter'),
      rssi: result.rssi,
    );
  }
}
