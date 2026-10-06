import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scooter_device.dart';
import '../models/scooter_telemetry.dart';
import '../services/ble_scooter_service.dart';
import '../state/scooter_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scooterControllerProvider);
    final c = ref.read(scooterControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Scooter Dashboard'), actions: [IconButton(onPressed: c.scan, icon: const Icon(Icons.bluetooth_searching))]),
      body: RefreshIndicator(onRefresh: c.refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
        _Connection(state: s.connectionState, devices: s.devices, onConnect: c.connect),
        if (s.error != null) ...[const SizedBox(height: 12), Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(s.error!)))],
        const SizedBox(height: 12), _Telemetry(t: s.telemetry), const SizedBox(height: 12),
        _Controls(t: s.telemetry, enabled: s.connectionState == ScooterConnectionState.connected, lock: c.lock, unlock: c.unlock, headlight: c.setHeadlight, taillight: c.setTaillight),
      ])),
    );
  }
}

class _Connection extends StatelessWidget {
  const _Connection({required this.state, required this.devices, required this.onConnect});
  final ScooterConnectionState state; final List<ScooterDevice> devices; final Future<void> Function(ScooterDevice) onConnect;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(state.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    if (devices.isEmpty) const Text('No compatible-looking scooter found. Tap scan.'),
    ...devices.map((d) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.electric_scooter), title: Text(d.name), subtitle: Text('${d.id}\nRSSI ${d.rssi} dBm'), trailing: FilledButton(onPressed: () => onConnect(d), child: const Text('Connect')))),
  ])));
}

class _Telemetry extends StatelessWidget {
  const _Telemetry({required this.t}); final ScooterTelemetry? t;
  @override Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5, children: [
    _Metric('Speed', t?.speedKmh == null ? '--' : '${t!.speedKmh!.toStringAsFixed(1)} km/h', Icons.speed),
    _Metric('Battery', t?.batteryPercent == null ? '--' : '${t!.batteryPercent}%', Icons.battery_full),
    _Metric('Voltage', t?.batteryVoltage == null ? '--' : '${t!.batteryVoltage!.toStringAsFixed(1)} V', Icons.bolt),
    _Metric('Controller', t?.controllerTemperature == null ? '--' : '${t!.controllerTemperature!.toStringAsFixed(1)} °C', Icons.memory),
    _Metric('Battery temp.', t?.batteryTemperature == null ? '--' : '${t!.batteryTemperature!.toStringAsFixed(1)} °C', Icons.thermostat),
    _Metric('Lock', t?.locked == null ? '--' : (t!.locked! ? 'Locked' : 'Unlocked'), Icons.lock),
  ]);
}
class _Metric extends StatelessWidget { const _Metric(this.title, this.value, this.icon); final String title,value; final IconData icon; @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon), const SizedBox(height: 6), Text(title), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))]))); }

class _Controls extends StatelessWidget {
  const _Controls({required this.t, required this.enabled, required this.lock, required this.unlock, required this.headlight, required this.taillight});
  final ScooterTelemetry? t; final bool enabled; final Future<void> Function() lock,unlock; final Future<void> Function(bool) headlight,taillight;
  @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Align(alignment: Alignment.centerLeft, child: Text('Controls', style: Theme.of(c).textTheme.titleLarge)), const SizedBox(height: 8),
    FilledButton.icon(onPressed: !enabled ? null : (t?.locked ?? false) ? unlock : lock, icon: Icon((t?.locked ?? false) ? Icons.lock_open : Icons.lock), label: Text((t?.locked ?? false) ? 'Unlock' : 'Lock')),
    SwitchListTile(title: const Text('Headlight'), value: t?.headlightOn ?? false, onChanged: enabled ? headlight : null),
    SwitchListTile(title: const Text('Taillight'), value: t?.taillightOn ?? false, onChanged: enabled ? taillight : null),
  ])));
}
