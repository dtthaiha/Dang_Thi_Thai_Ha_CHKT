class SensorLog {
  final DateTime timestamp;
  final double noiseDb;
  final double acceleration;
  final String alertStatus;

  SensorLog({
    required this.timestamp,
    required this.noiseDb,
    required this.acceleration,
    required this.alertStatus,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'noiseDb': noiseDb,
    'acceleration': acceleration,
    'alertStatus': alertStatus,
  };
}