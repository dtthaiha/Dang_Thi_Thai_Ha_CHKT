import 'package:flutter/material.dart';
import 'services/NotificationService.dart';
import 'services/PermissionHelper.dart';
import 'screens/LoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.initNotification();
    await PermissionHelper.requestAllPermissions();
  } catch (_) {}
  runApp(const ChildGuardApp());
}

class ChildGuardApp extends StatelessWidget {
  const ChildGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Điện Thoại Trẻ Em - Child Guard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
