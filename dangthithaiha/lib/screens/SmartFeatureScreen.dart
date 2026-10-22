import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ChildDevice.dart';
import '../models/AlertLog.dart';
import '../services/APIService.dart';
import '../services/SensorService.dart';
import '../services/NotificationService.dart';

class SmartFeatureScreen extends StatefulWidget {
  const SmartFeatureScreen({super.key});

  @override
  State<SmartFeatureScreen> createState() => _SmartFeatureScreenState();
}

class _SmartFeatureScreenState extends State<SmartFeatureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SensorMonitorService _sensorService = SensorMonitorService();

  // Trạng thái Tab 1: AI Posture & Eye Shield
  double _pitch = 62.0;
  double _roll = 2.0;
  String _postureStatus = "Tư thế ngồi chuẩn (Tốt cho mắt & cột sống)";
  bool _isManualOverride = false;
  List<ChildDevice> _devices = [];
  ChildDevice? _selectedDevice;

  // Trạng thái Tab 2: Edu-Unlock (Giải toán đổi giờ dùng máy)
  int _score = 0;
  int _questionIndex = 0;
  late int _numA;
  late int _numB;
  late String _operator;
  late int _correctAnswer;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _rewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDevices();
    _generateMathQuestion();

    _sensorService.onPostureUpdated = (pitch, roll, status) {
      if (!_isManualOverride && mounted) {
        setState(() {
          _pitch = pitch;
          _roll = roll;
          _postureStatus = status;
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
      if (_devices.isNotEmpty) {
        _selectedDevice = _devices.first;
      }
    });
  }

  void _generateMathQuestion() {
    final rng = Random();
    final ops = ['+', '-', '×'];
    _operator = ops[rng.nextInt(ops.length)];
    if (_operator == '×') {
      _numA = rng.nextInt(9) + 2;
      _numB = rng.nextInt(9) + 2;
      _correctAnswer = _numA * _numB;
    } else if (_operator == '+') {
      _numA = rng.nextInt(40) + 12;
      _numB = rng.nextInt(35) + 10;
      _correctAnswer = _numA + _numB;
    } else {
      _numA = rng.nextInt(40) + 30;
      _numB = rng.nextInt(25) + 5;
      _correctAnswer = _numA - _numB;
    }
    _answerCtrl.clear();
  }

  Future<void> _syncPostureToBackend() async {
    if (_selectedDevice == null || _selectedDevice!.id == null) return;
    final isBad = _postureStatus.contains('CẢNH BÁO');
    final updated = _selectedDevice!.copyWith(
      postureStatus: "${_postureStatus} (${_pitch.toStringAsFixed(0)}°)",
      isSafe: !isBad,
    );
    await ApiService.updateDevice(_selectedDevice!.id!, updated);

    if (isBad) {
      await ApiService.addAlertLog(
        AlertLog(
          deviceId: _selectedDevice!.id!,
          childName: _selectedDevice!.childName,
          alertType: 'Posture',
          message: 'AI Posture Shield: $_postureStatus (Góc nghiêng ${_pitch.toStringAsFixed(1)}°)',
        ),
      );
      await NotificationService.showEmergencyAlert(
        title: 'CẢNH BÁO TƯ THẾ & THỊ LỰC!',
        body: _postureStatus,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đồng bộ trạng thái tư thế của ${_selectedDevice!.childName} lên Server!'),
        backgroundColor: isBad ? Colors.deepOrange : Colors.green,
      ),
    );
  }

  Future<void> _submitMathAnswer() async {
    final userAns = int.tryParse(_answerCtrl.text.trim());
    if (userAns == null) return;

    if (userAns == _correctAnswer) {
      setState(() {
        _score++;
        _questionIndex++;
      });

      if (_score >= 3) {
        // Thưởng +15 phút sử dụng trên C# Backend
        if (_selectedDevice != null && _selectedDevice!.id != null) {
          await ApiService.rewardScreenTime(_selectedDevice!.id!, 15);
          await _loadDevices();
        }
        setState(() => _rewardClaimed = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Xuất sắc! Đã mở khóa và cộng thưởng +15 phút dùng máy!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _generateMathQuestion();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa đúng rồi! Đáp án đúng là $_correctAnswer. Hãy thử câu tiếp theo nhé!'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      setState(() {
        _questionIndex++;
        _generateMathQuestion();
      });
    }
  }

  @override
  void dispose() {
    _sensorService.stopMonitoring();
    _tabController.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBadPosture = _postureStatus.contains('CẢNH BÁO');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        title: const Text('Tính Năng Mới Độc Quyền (AI & Edu)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.accessibility_new), text: 'AI Bảo Vệ Tư Thế & Mắt'),
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Giải Toán Đổi Giờ Chơi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ===================================================================
          // TAB 1: AI POSTURE & EYE SHIELD (CHỐNG CẬN THỊ & GÙ LƯNG)
          // ===================================================================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_devices.isNotEmpty)
                  DropdownButtonFormField<ChildDevice>(
                    value: _selectedDevice,
                    decoration: InputDecoration(
                      labelText: 'Thiết bị trẻ em đang áp dụng',
                      prefixIcon: const Icon(Icons.child_care),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _devices
                        .map((d) => DropdownMenuItem(value: d, child: Text(d.childName)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDevice = v),
                  ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isBadPosture
                          ? [Colors.red.shade700, Colors.deepOrange.shade500]
                          : [Colors.teal.shade700, Colors.green.shade500],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isBadPosture ? Icons.warning_amber_rounded : Icons.verified_user,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _postureStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAngleMetric('Góc Nâng (Pitch)', '${_pitch.toStringAsFixed(1)}°'),
                          _buildAngleMetric('Góc Nghiêng (Roll)', '${_roll.toStringAsFixed(1)}°'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  '💡 Mô phỏng nhanh Tư thế cầm máy (Dành cho Thuyết trình):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      label: const Text('Ngồi thẳng chuẩn (65°)'),
                      onPressed: () => setState(() {
                        _isManualOverride = true;
                        _pitch = 65.0;
                        _roll = 1.0;
                        _postureStatus = "Tư thế ngồi chuẩn (Tốt cho mắt & cột sống)";
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.airline_seat_flat, color: Colors.red, size: 18),
                      label: const Text('Nằm ngửa xem máy (-35°)'),
                      onPressed: () => setState(() {
                        _isManualOverride = true;
                        _pitch = -35.0;
                        _roll = 12.0;
                        _postureStatus = "CẢNH BÁO: Trẻ đang nằm ngửa xem điện thoại (Màn hình úp)!";
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.downhill_skiing, color: Colors.deepOrange, size: 18),
                      label: const Text('Cúi gằm cổ rùa (12°)'),
                      onPressed: () => setState(() {
                        _isManualOverride = true;
                        _pitch = 12.0;
                        _roll = 3.0;
                        _postureStatus = "CẢNH BÁO: Cúi đầu quá thấp (< 22° - Nguy cơ gù cổ & cận thị)!";
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.sensors, color: Colors.indigo, size: 18),
                      label: const Text('Dùng cảm biến thật'),
                      onPressed: () => setState(() => _isManualOverride = false),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _syncPostureToBackend,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text(
                    'ĐỒNG BỘ TƯ THẾ & GỬI CẢNH BÁO VỀ MÁY PHỤ HUYNH',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // TAB 2: EDU-UNLOCK (GIẢI TOÁN ĐỔI THÊM GIỜ SỬ DỤNG)
          // ===================================================================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                        const SizedBox(height: 6),
                        const Text(
                          'Thử Thách Trí Tuệ - Đổi Giờ Dùng Máy',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Giải đúng 3 câu toán tư duy để hệ thống tự động mở khóa và cộng thưởng +15 phút sử dụng thiết bị!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (_score / 3.0).clamp(0.0, 1.0),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.amber.shade100,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tiến độ hiện tại: $_score / 3 câu đúng',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_selectedDevice != null)
                  ListTile(
                    tileColor: Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.timer, color: Colors.deepPurple),
                    title: Text('Thiết bị: ${_selectedDevice!.childName}'),
                    subtitle: Text(
                      'Giới hạn hiện tại: ${_selectedDevice!.usedScreenTimeMinutes} / ${_selectedDevice!.screenTimeLimitMinutes} phút',
                    ),
                  ),
                const SizedBox(height: 16),

                if (_rewardClaimed)
                  Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.celebration, size: 64, color: Colors.green),
                          const SizedBox(height: 12),
                          const Text(
                            'CHÚC MỪNG BÉ ĐÃ VƯỢT QUA THỬ THÁCH!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hệ thống đã tự động mở khóa thiết bị và cộng thêm +15 phút vào quỹ thời gian hôm nay.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _score = 0;
                                _questionIndex = 0;
                                _rewardClaimed = false;
                                _generateMathQuestion();
                              });
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Làm thử thách mới'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Câu hỏi số ${_questionIndex + 1}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_numA  $_operator  $_numB  =  ?',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _answerCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Nhập kết quả...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _submitMathAnswer,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'KIỂM TRA ĐÁP ÁN',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleMetric(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
