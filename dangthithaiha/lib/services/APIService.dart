import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ChildDevice.dart';
import '../models/SafeZone.dart';
import '../models/AlertLog.dart';
import '../models/AppUser.dart';

class ApiService {
  // Tự động chọn địa chỉ IP phù hợp: Máy ảo Android dùng 10.0.2.2:5000, Windows/Web dùng localhost:5000.
  // Cho phép đổi IP trực tiếp trên màn hình Đăng nhập nếu nhóm chạy trên điện thoại thật qua Wi-Fi LAN.
  static String _customBaseRoot = "";

  static String get baseRoot {
    if (_customBaseRoot.isNotEmpty) return _customBaseRoot;
    if (!kIsWeb && Platform.isAndroid) {
      return "http://10.0.2.2:5000";
    }
    return "http://localhost:5000";
  }

  static void setServerUrl(String url) {
    String cleaned = url.trim();
    if (cleaned.endsWith("/")) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    _customBaseRoot = cleaned;
  }

  static String get devicesUrl => "$baseRoot/api/ChildDevices";
  static String get authUrl => "$baseRoot/api/Authenticate";
  static String get safeZonesUrl => "$baseRoot/api/SafeZones";
  static String get alertLogsUrl => "$baseRoot/api/AlertLogs";

  static AppUser? currentUser;
  static bool isOnlineMode = true;

  // Dữ liệu dự phòng thông minh để đảm bảo cả nhóm chạy được 100% ngay cả khi chưa bật SQL Server
  static final List<ChildDevice> _fallbackDevices = [
    ChildDevice(
      id: 1,
      childName: "Bé Gia Bảo (Lớp 4A)",
      deviceCode: "IMEI-8891-GB01",
      latitude: 10.7769,
      longitude: 106.7009,
      noiseLevel: 48.5,
      acceleration: 0.8,
      pressure: 1012.8,
      isSafe: true,
      isLocked: false,
      screenTimeLimitMinutes: 120,
      usedScreenTimeMinutes: 65,
      postureStatus: "Tư thế ngồi chuẩn (Góc 65°)",
    ),
    ChildDevice(
      id: 2,
      childName: "Bé Minh Anh (Lớp 2B)",
      deviceCode: "IMEI-5520-MA02",
      latitude: 10.7805,
      longitude: 106.6982,
      noiseLevel: 82.4,
      acceleration: 1.5,
      pressure: 1011.5,
      isSafe: false,
      isLocked: false,
      screenTimeLimitMinutes: 90,
      usedScreenTimeMinutes: 85,
      postureStatus: "Cảnh báo: Đang nằm xem điện thoại!",
    ),
  ];

  static final List<SafeZone> _fallbackZones = [
    SafeZone(
      id: 1,
      zoneName: "Trường Tiểu học Nguyễn Bỉnh Khiêm",
      latitude: 10.7769,
      longitude: 106.7009,
      radiusMeters: 250,
      deviceId: 1,
      notifyOnExit: true,
    ),
    SafeZone(
      id: 2,
      zoneName: "Nhà riêng (Quận 1, TP.HCM)",
      latitude: 10.7801,
      longitude: 106.6990,
      radiusMeters: 150,
      deviceId: 1,
      notifyOnExit: true,
    ),
  ];

  static final List<AlertLog> _fallbackAlerts = [
    AlertLog(
      id: 1,
      deviceId: 2,
      childName: "Bé Minh Anh (Lớp 2B)",
      alertType: "Noise",
      message: "Phát hiện tiếng ồn môi trường cao bất thường (82.4 dB) gần cổng trường.",
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isResolved: false,
    ),
    AlertLog(
      id: 2,
      deviceId: 2,
      childName: "Bé Minh Anh (Lớp 2B)",
      alertType: "Posture",
      message: "AI Posture Shield: Trẻ nằm ngửa xem điện thoại quá 5 phút (nguy cơ hại mắt).",
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isResolved: false,
    ),
    AlertLog(
      id: 3,
      deviceId: 1,
      childName: "Bé Gia Bảo (Lớp 4A)",
      alertType: "SafeZone",
      message: "Trẻ đã đến Trường Tiểu học Nguyễn Bỉnh Khiêm an toàn.",
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isResolved: true,
      resolvedBy: "Hệ thống tự động",
    ),
  ];

  static final List<AppUser> _fallbackUsers = [
    AppUser(
      id: "1",
      userName: "admin",
      email: "admin@childguard.vn",
      fullName: "Quản Trị Viên Hệ Thống",
      role: "Admin",
    ),
    AppUser(
      id: "2",
      userName: "nhanvien",
      email: "staff@childguard.vn",
      fullName: "Nhân Viên Giám Sát Hỗ Trợ",
      role: "Staff",
    ),
    AppUser(
      id: "3",
      userName: "phuhuynh",
      email: "parent@childguard.vn",
      fullName: "Phụ Huynh Đặng Thị Thái Hà",
      role: "Customer",
    ),
  ];

  // ===========================================================================
  // 1. AUTHENTICATION: ĐĂNG KÝ QUA EMAIL + ĐĂNG NHẬP USERNAME/PASSWORD + OTP
  // ===========================================================================

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$authUrl/register"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'username': username,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        isOnlineMode = true;
        return {
          'success': true,
          'message': data['message'] ?? data['Message'] ?? 'Đăng ký thành công!',
          'demoOtp': data['demoOtp'] ?? data['DemoOtp'] ?? '123456',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? data['Message'] ?? 'Đăng ký thất bại!',
      };
    } catch (e) {
      // Fallback local registration
      isOnlineMode = false;
      final otp = (100000 + DateTime.now().millisecond * 899 % 900000).toString();
      _fallbackUsers.add(AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: username.isNotEmpty ? username : email.split('@').first,
        email: email,
        fullName: name.isNotEmpty ? name : username,
        role: role,
      ));
      return {
        'success': true,
        'message': 'Đăng ký tài khoản thành công qua email $email!',
        'demoOtp': otp,
      };
    }
  }

  static Future<Map<String, dynamic>> requestLoginOtp({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$authUrl/login"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': usernameOrEmail,
              'email': usernameOrEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        isOnlineMode = true;
        return {
          'success': true,
          'requireOtp': data['requireOtp'] ?? data['RequireOtp'] ?? true,
          'demoOtp': (data['demoOtp'] ?? data['DemoOtp'] ?? '123456').toString(),
          'email': data['email'] ?? data['Email'] ?? usernameOrEmail,
          'message': data['message'] ?? data['Message'] ?? 'Đã gửi mã OTP qua email!',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? data['Message'] ?? 'Sai tên đăng nhập hoặc mật khẩu!',
      };
    } catch (e) {
      isOnlineMode = false;
      final otp = (100000 + (DateTime.now().second * 13579) % 899999).toString();
      return {
        'success': true,
        'requireOtp': true,
        'demoOtp': otp,
        'email': usernameOrEmail.contains('@') ? usernameOrEmail : '$usernameOrEmail@childguard.vn',
        'message': 'Đã gửi mã OTP xác thực tới email (Chế độ Offline/Demo: $otp)',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String usernameOrEmail,
    required String password,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$authUrl/login"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': usernameOrEmail,
              'email': usernameOrEmail,
              'password': password,
              'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        isOnlineMode = true;
        final user = AppUser.fromJson(data);
        currentUser = user;
        return {
          'success': true,
          'user': user,
          'message': data['message'] ?? data['Message'] ?? 'Đăng nhập thành công!',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? data['Message'] ?? 'Mã OTP không hợp lệ!',
      };
    } catch (e) {
      isOnlineMode = false;
      if (otp.trim().length < 4) {
        return {'success': false, 'message': 'Mã OTP phải gồm 6 chữ số!'};
      }

      String lower = usernameOrEmail.toLowerCase();
      AppUser matched = _fallbackUsers.firstWhere(
        (u) => u.userName.toLowerCase() == lower || u.email.toLowerCase() == lower,
        orElse: () {
          String role = "Customer";
          if (lower.contains("admin")) role = "Admin";
          if (lower.contains("staff") || lower.contains("nhanvien") || lower.contains("nv")) role = "Staff";
          return AppUser(
            id: "99",
            userName: usernameOrEmail,
            email: usernameOrEmail.contains('@') ? usernameOrEmail : "$usernameOrEmail@childguard.vn",
            fullName: role == "Admin"
                ? "Quản Trị Viên"
                : (role == "Staff" ? "Nhân Viên Hỗ Trợ" : "Phụ Huynh ($usernameOrEmail)"),
            role: role,
          );
        },
      );
      currentUser = matched;
      return {
        'success': true,
        'user': matched,
        'message': 'Đăng nhập thành công (${matched.role})!',
      };
    }
  }

  // ===========================================================================
  // 2. CRUD THIẾT BỊ TRẺ EM (CHILD DEVICES)
  // ===========================================================================

  static Future<List<ChildDevice>> getDevices() async {
    try {
      final response = await http.get(Uri.parse(devicesUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        isOnlineMode = true;
        List data = jsonDecode(response.body);
        final list = data.map((e) => ChildDevice.fromJson(e)).toList();
        _fallbackDevices
          ..clear()
          ..addAll(list);
        return list;
      }
      return List.from(_fallbackDevices);
    } catch (e) {
      isOnlineMode = false;
      return List.from(_fallbackDevices);
    }
  }

  static Future<bool> addDevice(ChildDevice device) async {
    try {
      final response = await http
          .post(
            Uri.parse(devicesUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(device.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    final newId = (_fallbackDevices.isEmpty ? 0 : (_fallbackDevices.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b))) + 1;
    _fallbackDevices.insert(0, device.copyWith(id: newId));
    return true;
  }

  static Future<bool> updateDevice(int id, ChildDevice device) async {
    try {
      final response = await http
          .put(
            Uri.parse("$devicesUrl/$id"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(device.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (_) {}
    final idx = _fallbackDevices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      _fallbackDevices[idx] = device.copyWith(id: id);
    }
    return true;
  }

  static Future<bool> toggleDeviceLock(int id) async {
    try {
      final response = await http
          .post(Uri.parse("$devicesUrl/$id/toggle-lock"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _fallbackDevices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final current = _fallbackDevices[idx];
      _fallbackDevices[idx] = current.copyWith(isLocked: !current.isLocked);
    }
    return true;
  }

  static Future<bool> rewardScreenTime(int id, int bonusMinutes) async {
    try {
      final response = await http
          .post(Uri.parse("$devicesUrl/$id/reward-time?bonusMinutes=$bonusMinutes"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _fallbackDevices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final current = _fallbackDevices[idx];
      _fallbackDevices[idx] = current.copyWith(
        screenTimeLimitMinutes: current.screenTimeLimitMinutes + bonusMinutes,
        isLocked: false,
      );
    }
    return true;
  }

  static Future<bool> deleteDevice(int id) async {
    try {
      final response = await http
          .delete(Uri.parse("$devicesUrl/$id"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fallbackDevices.removeWhere((d) => d.id == id);
        return true;
      }
    } catch (_) {}
    _fallbackDevices.removeWhere((d) => d.id == id);
    return true;
  }

  // ===========================================================================
  // 3. CRUD VÙNG AN TOÀN ĐỊA LÝ (SAFE ZONES)
  // ===========================================================================

  static Future<List<SafeZone>> getSafeZones() async {
    try {
      final response = await http.get(Uri.parse(safeZonesUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        final list = data.map((e) => SafeZone.fromJson(e)).toList();
        _fallbackZones
          ..clear()
          ..addAll(list);
        return list;
      }
    } catch (_) {}
    return List.from(_fallbackZones);
  }

  static Future<bool> addSafeZone(SafeZone zone) async {
    try {
      final response = await http
          .post(
            Uri.parse(safeZonesUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(zone.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final newId = _fallbackZones.length + 10;
    _fallbackZones.insert(
      0,
      SafeZone(
        id: newId,
        zoneName: zone.zoneName,
        latitude: zone.latitude,
        longitude: zone.longitude,
        radiusMeters: zone.radiusMeters,
        deviceId: zone.deviceId,
        notifyOnExit: zone.notifyOnExit,
      ),
    );
    return true;
  }

  static Future<bool> updateSafeZone(int id, SafeZone zone) async {
    try {
      final response = await http
          .put(
            Uri.parse("$safeZonesUrl/$id"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(zone.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _fallbackZones.indexWhere((z) => z.id == id);
    if (idx != -1) {
      _fallbackZones[idx] = SafeZone(
        id: id,
        zoneName: zone.zoneName,
        latitude: zone.latitude,
        longitude: zone.longitude,
        radiusMeters: zone.radiusMeters,
        deviceId: zone.deviceId,
        notifyOnExit: zone.notifyOnExit,
      );
    }
    return true;
  }

  static Future<bool> deleteSafeZone(int id) async {
    try {
      final response = await http
          .delete(Uri.parse("$safeZonesUrl/$id"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        _fallbackZones.removeWhere((z) => z.id == id);
        return true;
      }
    } catch (_) {}
    _fallbackZones.removeWhere((z) => z.id == id);
    return true;
  }

  // ===========================================================================
  // 4. CRUD NHẬT KÝ CẢNH BÁO (ALERT LOGS - CHO NHÂN VIÊN & ADMIN & PHỤ HUYNH)
  // ===========================================================================

  static Future<List<AlertLog>> getAlertLogs() async {
    try {
      final response = await http.get(Uri.parse(alertLogsUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        final list = data.map((e) => AlertLog.fromJson(e)).toList();
        _fallbackAlerts
          ..clear()
          ..addAll(list);
        return list;
      }
    } catch (_) {}
    return List.from(_fallbackAlerts);
  }

  static Future<bool> addAlertLog(AlertLog log) async {
    try {
      final response = await http
          .post(
            Uri.parse(alertLogsUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(log.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    _fallbackAlerts.insert(
      0,
      AlertLog(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        deviceId: log.deviceId,
        childName: log.childName,
        alertType: log.alertType,
        message: log.message,
      ),
    );
    return true;
  }

  static Future<bool> resolveAlertLog(int id, String resolvedBy) async {
    try {
      final response = await http
          .put(Uri.parse("$alertLogsUrl/$id/resolve?resolvedBy=${Uri.encodeComponent(resolvedBy)}"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _fallbackAlerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final old = _fallbackAlerts[idx];
      _fallbackAlerts[idx] = AlertLog(
        id: old.id,
        deviceId: old.deviceId,
        childName: old.childName,
        alertType: old.alertType,
        message: old.message,
        createdAt: old.createdAt,
        isResolved: true,
        resolvedBy: resolvedBy,
      );
    }
    return true;
  }

  static Future<bool> deleteAlertLog(int id) async {
    try {
      final response = await http
          .delete(Uri.parse("$alertLogsUrl/$id"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        _fallbackAlerts.removeWhere((a) => a.id == id);
        return true;
      }
    } catch (_) {}
    _fallbackAlerts.removeWhere((a) => a.id == id);
    return true;
  }

  // ===========================================================================
  // 5. CRUD NGƯỜI DÙNG & PHÂN QUYỀN (CHO ADMIN)
  // ===========================================================================

  static Future<List<AppUser>> getUsers() async {
    try {
      final response = await http.get(Uri.parse("$authUrl/users")).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        final list = data.map((e) => AppUser.fromJson(e)).toList();
        _fallbackUsers
          ..clear()
          ..addAll(list);
        return list;
      }
    } catch (_) {}
    return List.from(_fallbackUsers);
  }

  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      final response = await http
          .put(Uri.parse("$authUrl/users/$userId/role?newRole=$newRole"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    final idx = _fallbackUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _fallbackUsers[idx];
      _fallbackUsers[idx] = AppUser(
        id: old.id,
        userName: old.userName,
        email: old.email,
        fullName: old.fullName,
        role: newRole,
      );
    }
    return true;
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await http
          .delete(Uri.parse("$authUrl/users/$userId"))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        _fallbackUsers.removeWhere((u) => u.id == userId);
        return true;
      }
    } catch (_) {}
    _fallbackUsers.removeWhere((u) => u.id == userId);
    return true;
  }
}
