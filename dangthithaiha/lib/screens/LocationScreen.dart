import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ChildDevice.dart';
import '../models/SafeZone.dart';
import '../services/APIService.dart';
import '../services/LocationService.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double _lat = 10.7769;
  double _lng = 106.7009;
  double _accuracy = 4.5;
  bool _isLoading = false;
  String _statusText = "Đang định vị GPS thời gian thực";

  List<ChildDevice> _devices = [];
  ChildDevice? _selectedDevice;
  List<SafeZone> _safeZones = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final devices = await ApiService.getDevices();
    final zones = await ApiService.getSafeZones();
    if (mounted) {
      setState(() {
        _devices = devices;
        if (_devices.isNotEmpty) {
          _selectedDevice = _devices.first;
          _lat = _selectedDevice!.latitude ?? 10.7769;
          _lng = _selectedDevice!.longitude ?? 106.7009;
        }
        _safeZones = zones;
      });
    }
    await _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      final Position pos = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _accuracy = pos.accuracy;
        _statusText = "Đã lấy tọa độ GPS thực tế từ cảm biến định vị";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "Đang dùng tọa độ GPS đồng bộ của thiết bị trẻ em";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tính khoảng cách giữa 2 tọa độ GPS theo mét (Haversine)
  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  Future<void> _shareLocationToServer() async {
    if (_selectedDevice == null || _selectedDevice!.id == null) return;
    final updated = _selectedDevice!.copyWith(
      latitude: _lat,
      longitude: _lng,
    );
    await ApiService.updateDevice(_selectedDevice!.id!, updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📍 Đã chia sẻ vị trí (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}) của ${_selectedDevice!.childName} lên Server!',
        ),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  void _showSafeZoneDialog({SafeZone? existing}) {
    final nameCtrl = TextEditingController(text: existing?.zoneName ?? '');
    final latCtrl = TextEditingController(text: (existing?.latitude ?? _lat).toStringAsFixed(5));
    final lngCtrl = TextEditingController(text: (existing?.longitude ?? _lng).toStringAsFixed(5));
    final radiusCtrl = TextEditingController(text: (existing?.radiusMeters ?? 200).toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm Vùng An Toàn GPS' : 'Sửa Vùng An Toàn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên địa điểm (VD: Trường học, Nhà)'),
              ),
              TextField(
                controller: latCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Vĩ độ (Latitude)'),
              ),
              TextField(
                controller: lngCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kinh độ (Longitude)'),
              ),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bán kính an toàn (mét)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final zone = SafeZone(
                id: existing?.id,
                zoneName: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Khu vực an toàn',
                latitude: double.tryParse(latCtrl.text) ?? _lat,
                longitude: double.tryParse(lngCtrl.text) ?? _lng,
                radiusMeters: double.tryParse(radiusCtrl.text) ?? 200,
                deviceId: _selectedDevice?.id ?? 1,
              );
              if (existing == null) {
                await ApiService.addSafeZone(zone);
              } else {
                await ApiService.updateSafeZone(existing.id!, zone);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              final zones = await ApiService.getSafeZones();
              if (mounted) setState(() => _safeZones = zones);
            },
            child: const Text('Lưu vùng an toàn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chia Sẻ Vị Trí GPS & Vùng An Toàn'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.my_location), onPressed: _getLocation),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () => _showSafeZoneDialog(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Thêm Vùng An Toàn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_devices.isNotEmpty)
                    DropdownButtonFormField<ChildDevice>(
                      value: _selectedDevice,
                      decoration: InputDecoration(
                        labelText: 'Chọn thiết bị trẻ em chia sẻ vị trí',
                        prefixIcon: const Icon(Icons.person_pin_circle, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _devices
                          .map((d) => DropdownMenuItem(value: d, child: Text(d.childName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDevice = val;
                            _lat = val.latitude ?? _lat;
                            _lng = val.longitude ?? _lng;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 14),

                  // Radar Map trực quan
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade800, Colors.indigo.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 2),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 2),
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                              ),
                            ),
                            const Icon(Icons.location_on, size: 46, color: Colors.amberAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vĩ độ (Lat): ${_lat.toStringAsFixed(5)}   |   Kinh độ (Lng): ${_lng.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sai số GPS: ±${_accuracy.toStringAsFixed(1)}m',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade800,
                                ),
                                onPressed: _getLocation,
                                icon: const Icon(Icons.gps_fixed, size: 18),
                                label: const Text('Lấy GPS Hiện Tại'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade600,
                                  foregroundColor: Colors.black87,
                                ),
                                onPressed: _shareLocationToServer,
                                icon: const Icon(Icons.share_location, size: 18),
                                label: const Text('Chia sẻ lên Server'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Danh sách Vùng An Toàn (CRUD SafeZones)
                  const Text(
                    '🛡️ Quản lý Vùng An Toàn Địa Lý (Geofencing CRUD)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._safeZones.map((zone) {
                    final dist = _calculateDistanceMeters(_lat, _lng, zone.latitude, zone.longitude);
                    final inside = dist <= zone.radiusMeters;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: inside ? Colors.green : Colors.orange,
                          child: Icon(
                            inside ? Icons.verified_user : Icons.directions_walk,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(zone.zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Bán kính: ${zone.radiusMeters.toInt()}m | Khoảng cách: ${dist.toStringAsFixed(0)}m\n'
                          'Trạng thái: ${inside ? "Trẻ đang ở TRONG vùng an toàn" : "Ngoài vùng (${(dist / 1000).toStringAsFixed(2)} km)"}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Đặt vị trí trẻ về vùng này',
                              icon: const Icon(Icons.pin_drop, color: Colors.teal),
                              onPressed: () {
                                setState(() {
                                  _lat = zone.latitude;
                                  _lng = zone.longitude;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSafeZoneDialog(existing: zone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                if (zone.id != null) {
                                  await ApiService.deleteSafeZone(zone.id!);
                                  final zones = await ApiService.getSafeZones();
                                  if (mounted) setState(() => _safeZones = zones);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
}
