import 'package:flutter/material.dart';
import '../models/AppUser.dart';
import '../services/APIService.dart';
import 'RegisterScreen.dart';
import 'HomeScreen.dart';
import 'AdminDashboardScreen.dart';
import 'StaffDashboardScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'phuhuynh');
  final _passwordCtrl = TextEditingController(text: '123456');
  final _otpCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _otpSent = false;
  String? _receivedDemoOtp;
  String? _targetEmail;

  Future<void> _sendOtpStep() async {
    final user = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Tên đăng nhập và Mật khẩu!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.requestLoginOtp(usernameOrEmail: user, password: pass);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _otpSent = true;
        _receivedDemoOtp = res['demoOtp']?.toString();
        _targetEmail = res['email']?.toString();
        _otpCtrl.text = _receivedDemoOtp ?? '123456';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đã gửi mã OTP qua email!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đăng nhập thất bại!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    final user = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Tên đăng nhập, Mật khẩu và Mã OTP!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.verifyLoginOtp(
      usernameOrEmail: user,
      password: pass,
      otp: otp,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res['success'] == true && res['user'] is AppUser) {
      final AppUser loggedInUser = res['user'];
      _navigateByRole(loggedInUser);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Mã OTP không đúng!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _navigateByRole(AppUser user) {
    final role = user.role.toLowerCase();
    Widget destination;
    if (role.contains('admin')) {
      destination = AdminDashboardScreen(currentUser: user);
    } else if (role.contains('staff') || role.contains('nhân viên')) {
      destination = StaffDashboardScreen(currentUser: user);
    } else {
      destination = HomeScreen(currentUser: user);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _fillQuickAccount(String username, String roleLabel) {
    setState(() {
      _usernameCtrl.text = username;
      _passwordCtrl.text = '123456';
      _otpSent = false;
      _receivedDemoOtp = null;
      _otpCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn tài khoản mẫu: $roleLabel ($username). Bấm "Lấy mã OTP" để tiếp tục!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showServerSettingsDialog() {
    final ctrl = TextEditingController(text: ApiService.baseRoot);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình Địa chỉ C# Backend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• Máy ảo Android: http://10.0.2.2:5000\n'
              '• Chạy trên Windows: http://localhost:5000\n'
              '• Máy thật qua Wi-Fi: http://192.168.1.X:5000',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              ApiService.setServerUrl(ctrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã lưu địa chỉ Server: ${ApiService.baseRoot}')),
              );
            },
            child: const Text('Lưu cấu hình'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade800, Colors.deepPurple.shade600, Colors.indigo.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: _showServerSettingsDialog,
                        icon: const Icon(Icons.settings_ethernet, size: 18),
                        label: const Text('Cấu hình IP Server'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_moon, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CHILD GUARD MANAGER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Text(
                    'Ứng dụng Quản lý & Bảo vệ Điện thoại Trẻ em',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Card Đăng nhập chính
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Đăng Nhập Bảo Mật 2 Lớp (2FA OTP)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tên đăng nhập hoặc Email',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Khu vực OTP (Tên đăng nhập + Mật khẩu + OTP)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _otpCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Mã xác thực OTP (6 số)',
                                          hintText: 'Nhập OTP hoặc 123456',
                                          prefixIcon: const Icon(Icons.pin_outlined, color: Colors.deepOrange),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _isLoading ? null : _sendOtpStep,
                                      icon: const Icon(Icons.send_to_mobile, size: 18),
                                      label: const Text('Lấy OTP'),
                                    ),
                                  ],
                                ),
                                if (_otpSent && _receivedDemoOtp != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '📩 Đã gửi OTP tới $_targetEmail — Mã OTP: $_receivedDemoOtp (Đã tự động điền)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _verifyOtpAndLogin,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login),
                              label: const Text(
                                'XÁC THỰC OTP & ĐĂNG NHẬP',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Chưa có tài khoản?'),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                  if (result is Map) {
                                    setState(() {
                                      _usernameCtrl.text = (result['username'] ?? '').toString();
                                      _passwordCtrl.text = (result['password'] ?? '').toString();
                                      _otpCtrl.text = (result['otp'] ?? '123456').toString();
                                      _otpSent = true;
                                      _receivedDemoOtp = _otpCtrl.text;
                                    });
                                  }
                                },
                                child: const Text(
                                  'Đăng ký qua Email ngay',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thanh chọn nhanh 3 quyền (Admin / Nhân viên / Khách hàng)
                  Card(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Text(
                            '⚡ Chọn nhanh Tài khoản Mẫu (Kiểm tra Phân quyền)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => _fillQuickAccount('admin', 'Admin Quản trị'),
                                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                                  label: const Text('Admin', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade700,
                                    side: BorderSide(color: Colors.teal.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => _fillQuickAccount('nhanvien', 'Nhân viên'),
                                  icon: const Icon(Icons.support_agent, size: 16),
                                  label: const Text('Nhân viên', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.indigo.shade700,
                                    side: BorderSide(color: Colors.indigo.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => _fillQuickAccount('phuhuynh', 'Phụ huynh'),
                                  icon: const Icon(Icons.family_restroom, size: 16),
                                  label: const Text('Phụ huynh', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
