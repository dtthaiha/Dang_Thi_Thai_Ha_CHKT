import 'package:flutter/material.dart';
import '../models/AppUser.dart';
import '../models/ChildDevice.dart';
import '../models/AlertLog.dart';
import '../services/APIService.dart';
import 'LoginScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  const AdminDashboardScreen({super.key, required this.currentUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  List<ChildDevice> _devices = [];
  List<AlertLog> _alerts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllAdminData();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    final users = await ApiService.getUsers();
    final devices = await ApiService.getDevices();
    final alerts = await ApiService.getAlertLogs();
    if (!mounted) return;
    setState(() {
      _users = users;
      _devices = devices;
      _alerts = alerts;
      _isLoading = false;
    });
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    String role = 'Staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm Tài Khoản Mới (Admin)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên')),
                TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Phân quyền'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản trị viên)')),
                    DropdownMenuItem(value: 'Staff', child: Text('Staff (Nhân viên)')),
                    DropdownMenuItem(value: 'Customer', child: Text('Customer (Phụ huynh)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isNotEmpty) {
                  await ApiService.registerUser(
                    name: nameCtrl.text,
                    username: userCtrl.text,
                    email: emailCtrl.text,
                    password: passCtrl.text,
                    role: role,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAllAdminData();
                }
              },
              child: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDeviceDialog({ChildDevice? existing}) {
    final nameCtrl = TextEditingController(text: existing?.childName ?? '');
    final codeCtrl = TextEditingController(text: existing?.deviceCode ?? 'IMEI-${DateTime.now().millisecond}');
    final limitCtrl = TextEditingController(text: (existing?.screenTimeLimitMinutes ?? 120).toString());
    bool isSafe = existing?.isSafe ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Thêm Thiết Bị Mới' : 'Cập Nhật Thiết Bị #${existing.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên của trẻ')),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã thiết bị (IMEI/MAC)')),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giới hạn sử dụng/ngày (phút)'),
              ),
              SwitchListTile(
                title: const Text('Trạng thái An toàn'),
                value: isSafe,
                onChanged: (v) => setDialogState(() => isSafe = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final limit = int.tryParse(limitCtrl.text) ?? 120;
                if (existing == null) {
                  await ApiService.addDevice(
                    ChildDevice(
                      childName: nameCtrl.text,
                      deviceCode: codeCtrl.text,
                      screenTimeLimitMinutes: limit,
                      isSafe: isSafe,
                    ),
                  );
                } else {
                  await ApiService.updateDevice(
                    existing.id!,
                    existing.copyWith(
                      childName: nameCtrl.text,
                      deviceCode: codeCtrl.text,
                      screenTimeLimitMinutes: limit,
                      isSafe: isSafe,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadAllAdminData();
              },
              child: const Text('Lưu lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unresolvedCount = _alerts.where((a) => !a.isResolved).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TRANG QUẢN TRỊ ADMIN', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Xin chào: ${widget.currentUser.fullName} (Role: Admin)', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllAdminData),
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
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Tài khoản & Quyền'),
            Tab(icon: Icon(Icons.devices), text: 'Thiết bị Trẻ em'),
            Tab(icon: Icon(Icons.notification_important), text: 'Nhật ký SOS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thống kê tổng quan Admin
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                _buildStatBox('Người dùng', '${_users.length}', Icons.group, Colors.indigo),
                const SizedBox(width: 8),
                _buildStatBox('Thiết bị', '${_devices.length}', Icons.phone_android, Colors.teal),
                const SizedBox(width: 8),
                _buildStatBox('Cảnh báo SOS', '$unresolvedCount', Icons.warning_amber, Colors.red),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: CRUD NGƯỜI DÙNG & PHÂN QUYỀN
                      Scaffold(
                        floatingActionButton: FloatingActionButton.extended(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Thêm Tài Khoản'),
                        ),
                        body: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _users.length,
                          itemBuilder: (ctx, i) {
                            final u = _users[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: u.role == 'Admin'
                                      ? Colors.red.shade700
                                      : (u.role == 'Staff' ? Colors.teal : Colors.indigo),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text('${u.fullName} (${u.userName})',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Email: ${u.email}\nQuyền hiện tại: ${u.role}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<String>(
                                      tooltip: 'Đổi phân quyền',
                                      icon: const Icon(Icons.manage_accounts, color: Colors.indigo),
                                      onSelected: (newRole) async {
                                        await ApiService.updateUserRole(u.id, newRole);
                                        _loadAllAdminData();
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'Admin', child: Text('Cấp quyền Admin')),
                                        PopupMenuItem(value: 'Staff', child: Text('Cấp quyền Nhân viên (Staff)')),
                                        PopupMenuItem(value: 'Customer', child: Text('Cấp quyền Khách hàng')),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        await ApiService.deleteUser(u.id);
                                        _loadAllAdminData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // TAB 2: CRUD THIẾT BỊ TRẺ EM
                      Scaffold(
                        floatingActionButton: FloatingActionButton.extended(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          onPressed: () => _showEditDeviceDialog(),
                          icon: const Icon(Icons.add_to_home_screen),
                          label: const Text('Thêm Thiết Bị'),
                        ),
                        body: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _devices.length,
                          itemBuilder: (ctx, i) {
                            final d = _devices[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: d.isSafe ? Colors.green : Colors.red,
                                  child: Icon(d.isLocked ? Icons.lock : Icons.smartphone, color: Colors.white),
                                ),
                                title: Text(d.childName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Mã: ${d.deviceCode} | Giới hạn: ${d.usedScreenTimeMinutes}/${d.screenTimeLimitMinutes} phút\n'
                                  'Tư thế: ${d.postureStatus}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditDeviceDialog(existing: d),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        if (d.id != null) {
                                          await ApiService.deleteDevice(d.id!);
                                          _loadAllAdminData();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // TAB 3: CRUD NHẬT KÝ CẢNH BÁO
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _alerts.length,
                        itemBuilder: (ctx, i) {
                          final a = _alerts[i];
                          return Card(
                            color: a.isResolved ? Colors.grey.shade100 : Colors.red.shade50,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                a.isResolved ? Icons.check_circle : Icons.warning_rounded,
                                color: a.isResolved ? Colors.green : Colors.red,
                                size: 32,
                              ),
                              title: Text('[${a.alertType}] ${a.childName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${a.message}\nTrạng thái: ${a.isResolved ? "Đã xử lý (${a.resolvedBy})" : "Chưa xử lý"}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () async {
                                  if (a.id != null) {
                                    await ApiService.deleteAlertLog(a.id!);
                                    _loadAllAdminData();
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

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
