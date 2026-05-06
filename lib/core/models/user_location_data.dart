/// Holds user location details used for prayer time calculations.
class UserLocationData {
  final double latitude;
  final double longitude;
  final String cityName;
  final String countryName;
  final String timeZoneId;
  final DateTime updatedAt;

  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.countryName,
    required this.timeZoneId,
    required this.updatedAt,
  });

  UserLocationData copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? countryName,
    String? timeZoneId,
    DateTime? updatedAt,
  }) {
    return UserLocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'countryName': countryName,
      'timeZoneId': timeZoneId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserLocationData.fromMap(Map<String, dynamic> map) {
    return UserLocationData(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      cityName: map['cityName'] as String? ?? '',
      countryName: map['countryName'] as String? ?? '',
      timeZoneId: map['timeZoneId'] as String? ?? 'UTC',
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
