import 'package:flutter/material.dart';
import '../models/ChildDevice.dart';
import '../models/AlertLog.dart';
import '../services/APIService.dart';
import '../services/SensorService.dart';
import '../services/NotificationService.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final SensorMonitorService _sensorService = SensorMonitorService();
  double _db = 46.5;
  double _accel = 0.4;
  double _pressureHpa = 1012.8;
  String _alertMessage = "Môi trường xung quanh trẻ hoàn toàn an toàn";
  bool _isEmergency = false;

  List<ChildDevice> _devices = [];
  ChildDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _sensorService.onNoiseUpdated = (db) {
      if (mounted) setState(() => _db = db);
    };
    _sensorService.onAccelerationUpdated = (accel) {
      if (mounted) setState(() => _accel = accel);
    };
    _sensorService.onPressureUpdated = (pressure) {
      if (mounted) setState(() => _pressureHpa = pressure);
    };
    _sensorService.onEmergencyTriggered = (msg) {
      if (mounted) {
        setState(() {
          _alertMessage = msg;
          _isEmergency = true;
        });
      }
    };
    _sensorService.startMonitoring();
  }

  Future<void> _loadDevices() async {
    final list = await ApiService.getDevices();
    if (!mounted) return;
    setState(() {
      _devices = list;
      if (_devices.isNotEmpty) _selectedDevice = _devices.first;
    });
  }

  // Công thức ước tính độ cao tương đối (m) từ áp suất khí quyển hPa
  double get _estimatedAltitudeMeters {
    return 44330.0 * (1.0 - (_pressureHpa / 1013.25).clamp(0.5, 1.2) + 0.0001);
  }

  Future<void> _syncSensorsToServer({bool triggerAlert = false}) async {
    if (_selectedDevice == null || _selectedDevice!.id == null) return;
    final updated = _selectedDevice!.copyWith(
      noiseLevel: _db,
      acceleration: _accel,
      pressure: _pressureHpa,
      isSafe: !_isEmergency,
    );
    await ApiService.updateDevice(_selectedDevice!.id!, updated);

    if (triggerAlert || _isEmergency) {
      await ApiService.addAlertLog(
        AlertLog(
          deviceId: _selectedDevice!.id!,
          childName: _selectedDevice!.childName,
          alertType: _accel > 20 ? 'Fall' : 'Noise',
          message: '$_alertMessage (Độ ồn: ${_db.toStringAsFixed(1)} dB, Gia tốc: ${_accel.toStringAsFixed(1)} m/s², Áp suất: ${_pressureHpa.toStringAsFixed(1)} hPa)',
        ),
      );
      await NotificationService.showEmergencyAlert(
        title: 'CẢNH BÁO CẢM BIẾN KHẨN CẤP!',
        body: _alertMessage,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đồng bộ thông số cảm biến của ${_selectedDevice!.childName} lên Server C#!'),
        backgroundColor: _isEmergency ? Colors.red : Colors.teal,
      ),
    );
  }

  @override
  void dispose() {
    _sensorService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đo Tiếng Ồn, Chuyển Động & Áp Suất'),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_devices.isNotEmpty)
              DropdownButtonFormField<ChildDevice>(
                value: _selectedDevice,
                decoration: InputDecoration(
                  labelText: 'Thiết bị trẻ em đang đo cảm biến',
                  prefixIcon: const Icon(Icons.sensors, color: Colors.deepOrange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _devices
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.childName)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDevice = v),
              ),
            const SizedBox(height: 14),

            // 1. Card Độ ồn môi trường (Noise Meter)
            Card(
              elevation: 3,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.mic, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('1. Độ ồn môi trường xung quanh (Microphone)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${_db.toStringAsFixed(1)} dB — ${_db > 80 ? "CẢNH BÁO ỒN ÀO / TIẾNG HÉT!" : "Bình thường"}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _db > 80 ? Colors.red : Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (_db / 110.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.orange.shade100,
                      color: _db > 80 ? Colors.red : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Card Gia tốc chuyển động & Phát hiện té ngã (Accelerometer)
            Card(
              elevation: 3,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.speed, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2. Gia tốc chuyển động & Phát hiện té ngã',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${_accel.toStringAsFixed(2)} m/s² — ${_accel > 22 ? "VA CHẠM / TÉ NGÃ MẠNH!" : "Ổn định"}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _accel > 22 ? Colors.red : Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (_accel / 35.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.blue.shade100,
                      color: _accel > 22 ? Colors.red : Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Card Áp suất khí quyển & Độ cao tầng nhà (Barometer)
            Card(
              elevation: 3,
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.compress, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('3. Áp suất khí quyển (Barometer Sensor)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${_pressureHpa.toStringAsFixed(2)} hPa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                          Text(
                            'Độ cao tương đối ước tính: ~${_estimatedAltitudeMeters.abs().toStringAsFixed(1)}m so với mực nước biển',
                            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hộp trạng thái cảnh báo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEmergency ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isEmergency ? Colors.red : Colors.green),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEmergency ? Icons.warning_amber_rounded : Icons.verified_user,
                    color: _isEmergency ? Colors.red.shade900 : Colors.green.shade900,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _alertMessage,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: _isEmergency ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Các nút mô phỏng nhanh khi thuyết trình trên máy ảo
            const Text(
              '⚡ Công cụ Kiểm thử Cảm biến nhanh (Dành cho Thuyết trình):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                    onPressed: () {
                      setState(() {
                        _db = 94.5;
                        _accel = 28.4;
                        _pressureHpa = 1008.2;
                        _isEmergency = true;
                        _alertMessage = "KHẨN CẤP: Phát hiện va chạm mạnh (28.4 m/s²) & tiếng hét lớn (94.5 dB)!";
                      });
                      _syncSensorsToServer(triggerAlert: true);
                    },
                    icon: const Icon(Icons.crisis_alert, size: 18),
                    label: const Text('Giả lập Té Ngã & Ồn', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green.shade700),
                    onPressed: () {
                      setState(() {
                        _db = 45.0;
                        _accel = 0.3;
                        _pressureHpa = 1013.2;
                        _isEmergency = false;
                        _alertMessage = "Môi trường xung quanh trẻ hoàn toàn an toàn";
                      });
                      _syncSensorsToServer(triggerAlert: false);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Đặt lại An Toàn', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _syncSensorsToServer(triggerAlert: false),
              icon: const Icon(Icons.sync),
              label: const Text(
                'ĐỒNG BỘ DỮ LIỆU CẢM BIẾN LÊN C# BACKEND',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
