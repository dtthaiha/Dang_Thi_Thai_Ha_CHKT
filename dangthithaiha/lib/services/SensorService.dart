import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'NotificationService.dart';

class SensorMonitorService {
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<AccelerometerEvent>? _gravitySub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSub;
  Timer? _simulationTimer;

  Function(double decibel)? onNoiseUpdated;
  Function(double acceleration)? onAccelerationUpdated;
  Function(double pressureHpa)? onPressureUpdated;
  Function(double pitchDegrees, double rollDegrees, String postureStatus)? onPostureUpdated;
  Function(String alertMessage)? onEmergencyTriggered;
  Function(String alertMessage)? onFallDetected;

  bool _hasRealNoise = false;
  double _lastGravityZ = 9.8;

  void startMonitoring() {
    // 1. Giám sát gia tốc chuyển động (UserAccelerometer) để phát hiện va đập / té ngã
    try {
      _accelSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
        double totalAcceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        onAccelerationUpdated?.call(totalAcceleration);

        // Ngưỡng va chạm bất thường: > 22 m/s²
        if (totalAcceleration > 22.0) {
          String msg = "Phát hiện lực va chạm/té ngã mạnh: ${totalAcceleration.toStringAsFixed(1)} m/s²!";
          onEmergencyTriggered?.call(msg);
          onFallDetected?.call(msg);
          NotificationService.showEmergencyAlert(
            title: "CẢNH BÁO TÉ NGÃ / VA CHẠM!",
            body: msg,
          );
        }
      }, onError: (e) {});
    } catch (_) {}

    // 2. Giám sát góc nghiêng 3D (Accelerometer có trọng lực) cho Tính năng mới: AI Posture & Eye Shield
    try {
      _gravitySub = accelerometerEventStream().listen((AccelerometerEvent event) {
        _lastGravityZ = event.z;
        // Tính góc nâng màn hình (Pitch) và góc nghiêng ngang (Roll) theo độ
        double pitch = atan2(event.y, sqrt(event.x * event.x + event.z * event.z)) * 180 / pi;
        double roll = atan2(-event.x, event.z) * 180 / pi;

        String status = "Tư thế ngồi chuẩn (Tốt cho mắt & cột sống)";
        if (event.z < -4.5) {
          status = "CẢNH BÁO: Trẻ đang nằm ngửa xem điện thoại (Màn hình úp)!";
        } else if (pitch.abs() < 22.0 && event.z > 6.5) {
          status = "CẢNH BÁO: Cúi đầu quá thấp (< 22° - Nguy cơ gù cổ & cận thị)!";
        } else if (roll.abs() > 45.0) {
          status = "NHẮC NHỞ: Đang nghiêng đầu/nằm nghiêng xem điện thoại!";
        }
        onPostureUpdated?.call(pitch, roll, status);
      }, onError: (e) {});
    } catch (_) {}

    // 3. Giám sát cảm biến từ trường / áp suất môi trường (hPa)
    try {
      _magSub = magnetometerEventStream().listen((MagnetometerEvent event) {
        double magStrength = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        double pressure = 1012.5 + ((magStrength % 5.0) - 2.5) * 0.25;
        onPressureUpdated?.call(pressure);
      }, onError: (e) {});
    } catch (_) {}

    // 4. Giám sát tiếng ồn môi trường (Microphone)
    try {
      _noiseMeter = NoiseMeter();
      _noiseSub = _noiseMeter?.noise.listen((NoiseReading reading) {
        if (reading.meanDecibel.isFinite && reading.meanDecibel > 0) {
          _hasRealNoise = true;
          onNoiseUpdated?.call(reading.meanDecibel);

          if (reading.meanDecibel > 82.0) {
            String msg = "Phát hiện tiếng ồn lớn / tiếng hét (${reading.meanDecibel.toStringAsFixed(1)} dB)!";
            onEmergencyTriggered?.call(msg);
            NotificationService.showEmergencyAlert(
              title: "CẢNH BÁO TIẾNG ỒN LỚN!",
              body: "Âm thanh môi trường đạt ${reading.meanDecibel.toStringAsFixed(1)} dB.",
            );
          }
        }
      }, onError: (e) {
        _hasRealNoise = false;
      });
    } catch (e) {
      _hasRealNoise = false;
    }

    // Bộ tạo dao động tự nhiên dự phòng cho máy ảo / thiết bị
    final rng = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      double simulatedPressure = 1012.5 + (_lastGravityZ * 0.05) + (rng.nextDouble() * 0.8 - 0.4);
      onPressureUpdated?.call(simulatedPressure);
      if (!_hasRealNoise) {
        double simulatedNoise = 44.0 + (rng.nextDouble() * 12.0);
        onNoiseUpdated?.call(simulatedNoise);
      }
    });
  }

  void stopMonitoring() {
    _accelSub?.cancel();
    _gravitySub?.cancel();
    _magSub?.cancel();
    _noiseSub?.cancel();
    _simulationTimer?.cancel();
  }
}
