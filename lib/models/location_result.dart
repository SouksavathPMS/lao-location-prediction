class LocationResult {
  final double latitude;
  final double longitude;
  final String province;
  final String district;
  final String village;
  final double distance; // in meters
  final String id;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.district,
    required this.village,
    required this.distance,
    required this.id,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    final coordinates = json['geometry']['coordinates'];
    final properties = json['properties'];

    return LocationResult(
      latitude: coordinates[1],
      longitude: coordinates[0],
      province: properties['urcne'] ?? '',
      district: properties['uscne'] ?? '',
      village: properties['uucne'] ?? '',
      distance: 0.0, // Will be calculated during prediction
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'province': province,
      'district': district,
      'village': village,
      'distance': distance,
      'id': id,
    };
  }
}
