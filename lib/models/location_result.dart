/// Represents the result of a location prediction or lookup operation.
///
/// This class encapsulates geographic location data including coordinates,
/// administrative divisions (province, district, village), and the distance
/// from a reference point.
class LocationResult {
  /// Latitude coordinate in decimal degrees.
  final double latitude;

  /// Longitude coordinate in decimal degrees.
  final double longitude;

  /// The province/region name where this location is situated.
  final String province;

  /// The district/municipality name where this location is situated.
  final String district;

  /// The village/locality name where this location is situated.
  final String village;

  /// Distance in meters from the reference point to this location.
  final double distance;

  /// Unique identifier for this location.
  final String id;

  /// Creates a new [LocationResult] instance with all required fields.
  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.district,
    required this.village,
    required this.distance,
    required this.id,
  });

  /// Creates a [LocationResult] from a GeoJSON feature object.
  ///
  /// Expects a GeoJSON format with 'geometry.coordinates' and 'properties'
  /// containing administrative division information.
  ///
  /// Parameters:
  /// - [json]: A Map containing GeoJSON feature data
  ///
  /// Returns: A new [LocationResult] with properties extracted from the JSON
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

  /// Converts this [LocationResult] to a JSON-serializable Map.
  ///
  /// Returns: A Map containing all properties of this location result
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
