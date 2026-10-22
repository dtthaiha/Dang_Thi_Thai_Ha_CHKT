class AlertLog {
  final int? id;
  final int deviceId;
  final String childName;
  final String alertType;
  final String message;
  final DateTime createdAt;
  final bool isResolved;
  final String? resolvedBy;

  AlertLog({
    this.id,
    required this.deviceId,
    required this.childName,
    required this.alertType,
    required this.message,
    DateTime? createdAt,
    this.isResolved = false,
    this.resolvedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AlertLog.fromJson(Map<String, dynamic> json) {
    return AlertLog(
      id: json['id'] ?? json['Id'],
      deviceId: json['deviceId'] ?? json['DeviceId'] ?? 1,
      childName: json['childName'] ?? json['ChildName'] ?? 'Thiết bị trẻ em',
      alertType: json['alertType'] ?? json['AlertType'] ?? 'SOS',
      message: json['message'] ?? json['Message'] ?? '',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isResolved: json['isResolved'] ?? json['IsResolved'] ?? false,
      resolvedBy: json['resolvedBy'] ?? json['ResolvedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'deviceId': deviceId,
      'childName': childName,
      'alertType': alertType,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'resolvedBy': resolvedBy,
    };
  }
}
