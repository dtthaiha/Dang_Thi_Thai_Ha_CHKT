class SafeZone {
  final int? id;
  final String zoneName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int deviceId;
  final bool notifyOnExit;

  SafeZone({
    this.id,
    required this.zoneName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.deviceId = 1,
    this.notifyOnExit = true,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'] ?? json['Id'],
      zoneName: json['zoneName'] ?? json['ZoneName'] ?? 'Vùng an toàn',
      latitude: ((json['latitude'] ?? json['Latitude'] ?? 10.7769) as num).toDouble(),
      longitude: ((json['longitude'] ?? json['Longitude'] ?? 106.7009) as num).toDouble(),
      radiusMeters: ((json['radiusMeters'] ?? json['RadiusMeters'] ?? 200) as num).toDouble(),
      deviceId: json['deviceId'] ?? json['DeviceId'] ?? 1,
      notifyOnExit: json['notifyOnExit'] ?? json['NotifyOnExit'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'zoneName': zoneName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'deviceId': deviceId,
      'notifyOnExit': notifyOnExit,
    };
  }
}
