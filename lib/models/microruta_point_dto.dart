class MicrorutaPointDto {
  const MicrorutaPointDto({
    required this.latitude,
    required this.longitude,
    this.isBlocked = false,
  });

  factory MicrorutaPointDto.fromJson(Map<String, dynamic> json) {
    final latValue = json['latitude'] ?? json['lat'];
    final lngValue = json['longitude'] ?? json['lng'];
    return MicrorutaPointDto(
      latitude: latValue is num ? latValue.toDouble() : 0,
      longitude: lngValue is num ? lngValue.toDouble() : 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'isBlocked': isBlocked,
  };

  MicrorutaPointDto copyWith({
    double? latitude,
    double? longitude,
    bool? isBlocked,
  }) => MicrorutaPointDto(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isBlocked: isBlocked ?? this.isBlocked,
  );

  final double latitude;
  final double longitude;
  final bool isBlocked;
}
