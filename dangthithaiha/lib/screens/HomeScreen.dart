import 'package:flutter/material.dart';
import '../models/AppUser.dart';
import '../models/ChildDevice.dart';
import '../services/APIService.dart';
import 'LocationScreen.dart';
import 'SensorScreen.dart';
import 'VideoCallScreen.dart';
import 'SmartFeatureScreen.dart';
import 'LoginScreen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser? currentUser;
  const HomeScreen({super.key, this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChildDevice> _devices = [];
  bool _isLoading = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getDevices();
    if (!mounted) return;
    setState(() {
      _devices = data;
      _isLoading = false;
    });
  }

  // Hộp thoại Thêm mới / Cập nhật thiết bị (Full Create & Update trong CRUD)
  void _showAddOrEditDeviceDialog({ChildDevice? existing}) {
    final nameCtrl = TextEditingController(text: existing?.childName ?? '');
    final codeCtrl = TextEditingController(
      text: existing?.deviceCode ?? 'IMEI-${1000 + DateTime.now().millisecond % 9000}',
    );
    final limitCtrl = TextEditingController(
      text: (existing?.screenTimeLimitMinutes ?? 120).toString(),
    );
    final usedCtrl = TextEditingController(
      text: (existing?.usedScreenTimeMinutes ?? 30).toString(),
    );
    bool isSafe = existing?.isSafe ?? true;
    bool isLocked = existing?.isLocked ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(existing == null ? 'Thêm Thiết Bị Con Mới' : 'Chỉnh Sửa Thiết Bị'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên của trẻ (*)',
                    prefixIcon: Icon(Icons.child_care),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã định danh máy (IMEI / MAC)',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn thời gian/ngày (phút)',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian đã dùng hôm nay (phút)',
                    prefixIcon: Icon(Icons.hourglass_bottom),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Trạng thái An toàn'),
                  value: isSafe,
                  activeColor: Colors.green,
                  onChanged: (v) => setDialogState(() => isSafe = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Khóa màn hình từ xa'),
                  value: isLocked,
                  activeColor: Colors.red,
                  onChanged: (v) => setDialogState(() => isLocked = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final limit = int.tryParse(limitCtrl.text) ?? 120;
                final used = int.tryParse(usedCtrl.text) ?? 30;

                if (existing == null) {
                  final newDevice = ChildDevice(
                    childName: nameCtrl.text.trim(),
                    deviceCode: codeCtrl.text.trim(),
                    screenTimeLimitMinutes: limit,
                    usedScreenTimeMinutes: used,
                    isSafe: isSafe,
                    isLocked: isLocked,
                  );
                  await ApiService.addDevice(newDevice);
                } else {
                  final updated = existing.copyWith(
                    childName: nameCtrl.text.trim(),
                    deviceCode: codeCtrl.text.trim(),
                    screenTimeLimitMinutes: limit,
                    usedScreenTimeMinutes: used,
                    isSafe: isSafe,
                    isLocked: isLocked,
                  );
                  await ApiService.updateDevice(existing.id!, updated);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchDevices();
              },
              icon: const Icon(Icons.save, size: 18),
              label: Text(existing == null ? 'Thêm mới' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceDetailsBottomSheet(ChildDevice item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: item.isSafe ? Colors.indigo : Colors.red,
                  child: const Icon(Icons.face, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.childName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      Text('Mã thiết bị: ${item.deviceCode}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    item.isSafe ? 'An toàn' : 'Cảnh báo!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: item.isSafe ? Colors.green : Colors.red,
                ),
              ],
            ),
            const Divider(height: 24),
            Text('📍 Tọa độ GPS: (${item.latitude?.toStringAsFixed(4)}, ${item.longitude?.toStringAsFixed(4)})'),
            const SizedBox(height: 6),
            Text('🔊 Độ ồn môi trường: ${item.noiseLevel?.toStringAsFixed(1)} dB   |   Áp suất: ${item.pressure?.toStringAsFixed(1)} hPa'),
            const SizedBox(height: 6),
            Text('⏳ Thời lượng sử dụng: ${item.usedScreenTimeMinutes} / ${item.screenTimeLimitMinutes} phút/ngày'),
            const SizedBox(height: 6),
            Text('🧘 Trạng thái tư thế (AI): ${item.postureStatus}'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isLocked ? Colors.green : Colors.orange.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (item.id != null) {
                        await ApiService.toggleDeviceLock(item.id!);
                        _fetchDevices();
                      }
                    },
                    icon: Icon(item.isLocked ? Icons.lock_open : Icons.lock),
                    label: Text(item.isLocked ? 'Mở khóa máy' : 'Khóa máy từ xa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddOrEditDeviceDialog(existing: item);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.currentUser?.fullName ?? "Phụ Huynh Đặng Thị Thái Hà";
    final filteredDevices = _devices
        .where((d) =>
            d.childName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.deviceCode.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Child Guard - Trang Phụ Huynh', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Xin chào: $userName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDevices),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDeviceDialog(),
        backgroundColor: Colors.indigo.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm thiết bị con', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner trạng thái kết nối
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.deepPurple.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.amberAccent, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hệ Thống Bảo Vệ Trẻ Em Toàn Diện',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Đang giám sát ${_devices.length} thiết bị • Trạng thái: ${ApiService.isOnlineMode ? "Đồng bộ C# SQL Server" : "Đồng bộ thông minh"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              '🚀 3 Chức năng Thuyết trình & Tính năng Mới Độc Quyền',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lưới 2x2 cho 4 chức năng nổi bật
            Row(
              children: [
                _buildQuickCard(
                  title: 'b. Chia sẻ Vị trí',
                  subtitle: 'GPS & Vùng an toàn',
                  icon: Icons.location_on,
                  color: Colors.blue.shade700,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationScreen()));
                    _fetchDevices();
                  },
                ),
                const SizedBox(width: 10),
                _buildQuickCard(
                  title: 'c. Video Nhóm',
                  subtitle: 'Phòng họp gia đình',
                  icon: Icons.videocam,
                  color: Colors.green.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoCallScreen())),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickCard(
                  title: 'd. Đo Cảm biến',
                  subtitle: 'Tiếng ồn, Ngã, Áp suất',
                  icon: Icons.sensors,
                  color: Colors.deepOrange.shade700,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SensorScreen()));
                    _fetchDevices();
                  },
                ),
                const SizedBox(width: 10),
                _buildQuickCard(
                  title: '★ Tính Năng Mới',
                  subtitle: 'AI Tư thế & Giải toán',
                  icon: Icons.auto_awesome,
                  color: Colors.deepPurple.shade700,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartFeatureScreen()));
                    _fetchDevices();
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Phần CRUD Thiết bị trẻ em
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📱 Quản lý Thiết bị Con (Full CRUD)',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tổng: ${filteredDevices.length} máy',
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên trẻ hoặc mã IMEI...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                : filteredDevices.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Chưa có thiết bị nào. Nhấn "Thêm thiết bị con" để tạo mới.'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDevices.length,
                        itemBuilder: (context, index) {
                          final item = filteredDevices[index];
                          final progress = (item.usedScreenTimeMinutes /
                                  (item.screenTimeLimitMinutes > 0 ? item.screenTimeLimitMinutes : 120))
                              .clamp(0.0, 1.0);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showDeviceDetailsBottomSheet(item),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: item.isSafe ? Colors.indigo : Colors.red,
                                          child: Icon(
                                            item.isLocked ? Icons.lock : Icons.person,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.childName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                'Mã: ${item.deviceCode} • ${item.isLocked ? "ĐANG KHÓA MÀN HÌNH" : "Đang mở"}',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: item.isLocked ? Colors.red : Colors.black54,
                                                  fontWeight: item.isLocked ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: item.isLocked ? 'Mở khóa từ xa' : 'Khóa máy từ xa',
                                          icon: Icon(
                                            item.isLocked ? Icons.lock_open : Icons.lock_outline,
                                            color: item.isLocked ? Colors.green : Colors.orange.shade800,
                                          ),
                                          onPressed: () async {
                                            if (item.id != null) {
                                              await ApiService.toggleDeviceLock(item.id!);
                                              _fetchDevices();
                                            }
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Sửa thông tin',
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                          onPressed: () => _showAddOrEditDeviceDialog(existing: item),
                                        ),
                                        IconButton(
                                          tooltip: 'Xóa thiết bị',
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            if (item.id != null) {
                                              await ApiService.deleteDevice(item.id!);
                                              _fetchDevices();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '⏱ Giờ dùng hôm nay: ${item.usedScreenTimeMinutes}/${item.screenTimeLimitMinutes} phút',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '🔊 ${item.noiseLevel?.toStringAsFixed(0) ?? 45} dB',
                                          style: const TextStyle(fontSize: 12.5, color: Colors.deepOrange),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(6),
                                      backgroundColor: Colors.grey.shade200,
                                      color: progress > 0.85 ? Colors.red : Colors.indigo,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '🧘 AI Tư thế: ${item.postureStatus}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.postureStatus.contains('Cảnh báo') ||
                                                item.postureStatus.contains('CẢNH BÁO')
                                            ? Colors.red.shade700
                                            : Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
