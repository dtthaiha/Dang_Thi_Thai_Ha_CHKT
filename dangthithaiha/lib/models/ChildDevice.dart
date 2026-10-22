class ChildDevice {
  final int? id;
  final String childName;
  final String deviceCode;
  final double? latitude;
  final double? longitude;
  final double? noiseLevel;
  final double? acceleration;
  final double? pressure;
  final bool isSafe;
  final bool isLocked;
  final int screenTimeLimitMinutes;
  final int usedScreenTimeMinutes;
  final String postureStatus;
  final DateTime? lastUpdated;

  ChildDevice({
    this.id,
    required this.childName,
    required this.deviceCode,
    this.latitude = 10.7769,
    this.longitude = 106.7009,
    this.noiseLevel = 45.0,
    this.acceleration = 0.2,
    this.pressure = 1013.25,
    this.isSafe = true,
    this.isLocked = false,
    this.screenTimeLimitMinutes = 120,
    this.usedScreenTimeMinutes = 45,
    this.postureStatus = "Tư thế chuẩn",
    this.lastUpdated,
  });

  factory ChildDevice.fromJson(Map<String, dynamic> json) {
    return ChildDevice(
      id: json['id'] ?? json['Id'],
      childName: json['childName'] ?? json['deviceName'] ?? json['DeviceName'] ?? 'Thiết bị của trẻ',
      deviceCode: json['deviceCode'] ?? json['macAddress'] ?? json['MacAddress'] ?? 'DEV-001',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : (json['Latitude'] != null ? (json['Latitude'] as num).toDouble() : 10.7769),
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : (json['Longitude'] != null ? (json['Longitude'] as num).toDouble() : 106.7009),
      noiseLevel: json['noiseLevel'] != null
          ? (json['noiseLevel'] as num).toDouble()
          : (json['NoiseLevel'] != null ? (json['NoiseLevel'] as num).toDouble() : 45.0),
      acceleration: json['acceleration'] != null
          ? (json['acceleration'] as num).toDouble()
          : (json['Acceleration'] != null ? (json['Acceleration'] as num).toDouble() : 0.2),
      pressure: json['pressure'] != null
          ? (json['pressure'] as num).toDouble()
          : (json['Pressure'] != null ? (json['Pressure'] as num).toDouble() : 1013.25),
      isSafe: json['isSafe'] ?? json['IsSafe'] ?? true,
      isLocked: json['isLocked'] ?? json['IsLocked'] ?? false,
      screenTimeLimitMinutes: json['screenTimeLimitMinutes'] ?? json['ScreenTimeLimitMinutes'] ?? 120,
      usedScreenTimeMinutes: json['usedScreenTimeMinutes'] ?? json['UsedScreenTimeMinutes'] ?? 45,
      postureStatus: json['postureStatus'] ?? json['PostureStatus'] ?? "Tư thế chuẩn",
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'childName': childName,
      'deviceName': childName,
      'deviceCode': deviceCode,
      'macAddress': deviceCode,
      'parentId': 1,
      'latitude': latitude,
      'longitude': longitude,
      'noiseLevel': noiseLevel,
      'acceleration': acceleration,
      'pressure': pressure,
      'isSafe': isSafe,
      'isLocked': isLocked,
      'screenTimeLimitMinutes': screenTimeLimitMinutes,
      'usedScreenTimeMinutes': usedScreenTimeMinutes,
      'postureStatus': postureStatus,
    };
  }

  ChildDevice copyWith({
    int? id,
    String? childName,
    String? deviceCode,
    double? latitude,
    double? longitude,
    double? noiseLevel,
    double? acceleration,
    double? pressure,
    bool? isSafe,
    bool? isLocked,
    int? screenTimeLimitMinutes,
    int? usedScreenTimeMinutes,
    String? postureStatus,
  }) {
    return ChildDevice(
      id: id ?? this.id,
      childName: childName ?? this.childName,
      deviceCode: deviceCode ?? this.deviceCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      acceleration: acceleration ?? this.acceleration,
      pressure: pressure ?? this.pressure,
      isSafe: isSafe ?? this.isSafe,
      isLocked: isLocked ?? this.isLocked,
      screenTimeLimitMinutes: screenTimeLimitMinutes ?? this.screenTimeLimitMinutes,
      usedScreenTimeMinutes: usedScreenTimeMinutes ?? this.usedScreenTimeMinutes,
      postureStatus: postureStatus ?? this.postureStatus,
      lastUpdated: DateTime.now(),
    );
  }
}
