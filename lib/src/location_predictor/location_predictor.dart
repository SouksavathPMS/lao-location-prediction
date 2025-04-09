import '../../models/models.dart';
import '../models/models.dart';

class LocationPredictor {
  static const int _gridSize = 100; // Grid size in kilometers
  static final LocationPredictor _instance = LocationPredictor._internal();

  factory LocationPredictor() {
    return _instance;
  }

  LocationPredictor._internal();

  SpatialGrid? _grid;
  bool _initialized = false;

  // Initialize the predictor by loading the spatial grid
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _grid = await SpatialGrid.load(_gridSize);
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize LocationPredictor: $e');
    }
  }

  // Predict the location based on a given latitude and longitude
  Future<List<LocationResult>> predict(
    double latitude,
    double longitude, {
    int limit = 5,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (_grid == null) {
      throw Exception('Spatial grid not initialized');
    }

    // Get the nearest locations from the spatial grid
    return _grid!.findNearest(latitude, longitude, limit: limit);
  }

  // Get all locations within a radius (in km)
  Future<List<LocationResult>> findWithinRadius(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    if (_grid == null) {
      throw Exception('Spatial grid not initialized');
    }

    return _grid!.findWithinRadius(latitude, longitude, radiusKm);
  }

  // Search for locations by name (province, district, or village)
  Future<List<LocationResult>> searchByName(String query) async {
    if (!_initialized) {
      await initialize();
    }

    if (_grid == null) {
      throw Exception('Spatial grid not initialized');
    }

    return _grid!.searchByName(query);
  }

  // Get locations within a bounding box
  Future<List<LocationResult>> getLocationsInBoundingBox(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    if (_grid == null) {
      throw Exception('Spatial grid not initialized');
    }

    return _grid!.getLocationsInBoundingBox(minLat, minLng, maxLat, maxLng);
  }
}
