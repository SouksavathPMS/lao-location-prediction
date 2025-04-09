import '../../models/models.dart';
import '../models/models.dart';

/// {@template location_predictor}
/// A singleton class responsible for predicting and searching for locations.
///
/// This class utilizes a spatial grid to efficiently perform location-based
/// queries such as finding the nearest locations, locations within a radius,
/// and searching by name or within a bounding box.
///
/// **Singleton Implementation:**
/// This class implements the Singleton design pattern, ensuring that only one
/// instance of `LocationPredictor` exists throughout the application.
/// Access the instance using the default constructor: `LocationPredictor()`.
///
/// **Initialization:**
/// Before using the prediction or search methods, you must call the `initialize()`
/// method. This loads the spatial grid from a data source.
///
/// **Usage Examples:**
///
/// ```dart
/// // Get the singleton instance
/// final predictor = LocationPredictor();
///
/// // Initialize the predictor
/// await predictor.initialize();
///
/// // Predict the 5 nearest locations to a given coordinate
/// final nearest = await predictor.predict(13.7563, 100.5018);
///
/// // Find locations within a 10km radius
/// final withinRadius = await predictor.findWithinRadius(13.7563, 100.5018, 10.0);
///
/// // Search for locations by name
/// final searchResults = await predictor.searchByName("Bangkok");
/// ```
/// {@endtemplate}
class LocationPredictor {
  static const int _gridSize = 100; // Grid size in kilometers
  static final LocationPredictor _instance = LocationPredictor._internal();

  /// Returns the single instance of the [LocationPredictor] class.
  factory LocationPredictor() {
    return _instance;
  }

  LocationPredictor._internal();

  SpatialGrid? _grid;
  bool _initialized = false;

  /// Initializes the [LocationPredictor] by loading the spatial grid.
  ///
  /// This method must be called before using any of the prediction or
  /// search methods.
  ///
  /// Throws an [Exception] if the spatial grid fails to load.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _grid = await SpatialGrid.load(_gridSize);
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize LocationPredictor: $e');
    }
  }

  /// Predicts the nearest locations to a given latitude and longitude.
  ///
  /// Requires the predictor to be initialized.
  ///
  /// Parameters:
  ///   - [latitude]: The latitude of the query point.
  ///   - [longitude]: The longitude of the query point.
  ///   - [limit]: The maximum number of results to return (default is 5).
  ///
  /// Returns a [Future] that resolves to a [List] of [LocationResult] objects.
  ///
  /// Throws an [Exception] if the predictor is not initialized or the
  /// spatial grid is null.
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

  /// Finds all locations within a specified radius (in kilometers) of a
  /// given latitude and longitude.
  ///
  /// Requires the predictor to be initialized.
  ///
  /// Parameters:
  ///   - [latitude]: The latitude of the center point.
  ///   - [longitude]: The longitude of the center point.
  ///   - [radiusKm]: The radius in kilometers.
  ///
  /// Returns a [Future] that resolves to a [List] of [LocationResult] objects.
  ///
  /// Throws an [Exception] if the predictor is not initialized or the
  /// spatial grid is null.
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

  /// Searches for locations by name (province, district, or village).
  ///
  /// Requires the predictor to be initialized.
  ///
  /// Parameters:
  ///   - [query]: The search string.
  ///
  /// Returns a [Future] that resolves to a [List] of [LocationResult] objects
  /// matching the query.
  ///
  /// Throws an [Exception] if the predictor is not initialized or the
  /// spatial grid is null.
  Future<List<LocationResult>> searchByName(String query) async {
    if (!_initialized) {
      await initialize();
    }

    if (_grid == null) {
      throw Exception('Spatial grid not initialized');
    }

    return _grid!.searchByName(query);
  }

  /// Gets all locations within a specified bounding box.
  ///
  /// Requires the predictor to be initialized.
  ///
  /// Parameters:
  ///   - [minLat]: The minimum latitude of the bounding box.
  ///   - [minLng]: The minimum longitude of the bounding box.
  ///   - [maxLat]: The maximum latitude of the bounding box.
  ///   - [maxLng]: The maximum longitude of the bounding box.
  ///
  /// Returns a [Future] that resolves to a [List] of [LocationResult] objects
  /// within the bounding box.
  ///
  /// Throws an [Exception] if the predictor is not initialized or the
  /// spatial grid is null.
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
