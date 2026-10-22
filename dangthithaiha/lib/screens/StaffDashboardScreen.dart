import 'package:flutter/material.dart';
import '../models/AppUser.dart';
import '../models/ChildDevice.dart';
import '../models/AlertLog.dart';
import '../services/APIService.dart';
import 'VideoCallScreen.dart';
import 'LocationScreen.dart';
import 'SensorScreen.dart';
import 'LoginScreen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  const StaffDashboardScreen({super.key, required this.currentUser});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AlertLog> _alerts = [];
  List<ChildDevice> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    final alerts = await ApiService.getAlertLogs();
    final devices = await ApiService.getDevices();
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _devices = devices;
      _isLoading = false;
    });
  }

  void _showCreateAlertDialog() {
    final childCtrl = TextEditingController(
      text: _devices.isNotEmpty ? _devices.first.childName : 'Bé Gia Bảo',
    );
    final msgCtrl = TextEditingController();
    String alertType = 'SOS';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tạo Phiếu Cảnh Báo / Hỗ Trợ Kỹ Thuật'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: childCtrl, decoration: const InputDecoration(labelText: 'Tên trẻ / Thiết bị')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: alertType,
                decoration: const InputDecoration(labelText: 'Loại cảnh báo'),
                items: const [
                  DropdownMenuItem(value: 'SOS', child: Text('SOS Khẩn cấp')),
                  DropdownMenuItem(value: 'Noise', child: Text('Tiếng ồn lớn bất thường')),
                  DropdownMenuItem(value: 'Fall', child: Text('Phát hiện va chạm / Té ngã')),
                  DropdownMenuItem(value: 'Posture', child: Text('Nhắc nhở tư thế & thị lực')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => alertType = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msgCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Nội dung ghi nhận của nhân viên'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (msgCtrl.text.isNotEmpty) {
                  await ApiService.addAlertLog(
                    AlertLog(
                      deviceId: 1,
                      childName: childCtrl.text,
                      alertType: alertType,
                      message: msgCtrl.text,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadStaffData();
                }
              },
              child: const Text('Gửi cảnh báo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAlerts = _alerts.where((a) => !a.isResolved).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DASHBOARD NHÂN VIÊN GIÁM SÁT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Nhân viên trực: ${widget.currentUser.fullName}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStaffData),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.support_agent), text: 'Trực ban SOS ($pendingAlerts)'),
            const Tab(icon: Icon(Icons.radar), text: 'Giám sát Thiết bị'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        onPressed: _showCreateAlertDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('Tạo Phiếu Hỗ Trợ'),
      ),
      body: Column(
        children: [
          // Thanh công cụ hỗ trợ nhanh của Nhân viên
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationScreen()),
                    ),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Định vị GPS', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoCallScreen()),
                    ),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Video Hỗ trợ', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SensorScreen()),
                    ),
                    icon: const Icon(Icons.sensors, size: 18),
                    label: const Text('Đo Cảm biến', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: DANH SÁCH CẢNH BÁO CẦN NHÂN VIÊN XỬ LÝ
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _alerts.length,
                        itemBuilder: (ctx, i) {
                          final a = _alerts[i];
                          return Card(
                            elevation: 2,
                            color: a.isResolved ? Colors.white : Colors.orange.shade50,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          a.alertType,
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                        backgroundColor: a.isResolved ? Colors.grey : Colors.deepOrange,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          a.childName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      if (a.isResolved)
                                        const Icon(Icons.verified, color: Colors.green)
                                      else
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          onPressed: () async {
                                            if (a.id != null) {
                                              await ApiService.resolveAlertLog(
                                                a.id!,
                                                widget.currentUser.fullName,
                                              );
                                              _loadStaffData();
                                            }
                                          },
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Tiếp nhận xử lý', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(a.message, style: const TextStyle(fontSize: 13.5)),
                                  if (a.isResolved) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '✔ Đã xử lý bởi: ${a.resolvedBy}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // TAB 2: GIÁM SÁT THIẾT BỊ & THÔNG SỐ CẢM BIẾN
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _devices.length,
                        itemBuilder: (ctx, i) {
                          final d = _devices[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: d.isSafe ? Colors.teal : Colors.red,
                                child: const Icon(Icons.child_care, color: Colors.white),
                              ),
                              title: Text(d.childName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'GPS: (${d.latitude?.toStringAsFixed(4)}, ${d.longitude?.toStringAsFixed(4)})\n'
                                'Độ ồn: ${d.noiseLevel?.toStringAsFixed(1)} dB | Áp suất: ${d.pressure?.toStringAsFixed(1)} hPa\n'
                                'Tư thế: ${d.postureStatus}',
                              ),
                              isThreeLine: true,
                              trailing: Switch(
                                value: d.isSafe,
                                activeColor: Colors.green,
                                onChanged: (val) async {
                                  if (d.id != null) {
                                    await ApiService.updateDevice(d.id!, d.copyWith(isSafe: val));
                                    _loadStaffData();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
