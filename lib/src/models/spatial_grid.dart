import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import 'models.dart';

/// A spatial grid system that indexes geographic locations for efficient querying.
///
/// The [SpatialGrid] divides geographical space into a grid of cells, each covering
/// a square area of [gridSize] x [gridSize] kilometers. It provides methods for finding
/// nearby locations, searching by name, and querying within geometric boundaries.
///
/// The grid maintains in-memory indices for administrative divisions (provinces,
/// districts, villages) to support fast text-based searches.
class SpatialGrid {
  /// The size of each grid cell in kilometers.
  final int gridSize;

  /// Map of grid cells indexed by their coordinates in "x:y" string format.
  final Map<String, GridCell> cells = {};

  /// The minimum latitude of the entire grid coverage area.
  final double minLat;

  /// The minimum longitude of the entire grid coverage area.
  final double minLng;

  /// The maximum latitude of the entire grid coverage area.
  final double maxLat;

  /// The maximum longitude of the entire grid coverage area.
  final double maxLng;

  /// Index of locations by province name (lowercase) for fast text searching.
  final Map<String, List<LocationResult>> _provinceIndex = {};

  /// Index of locations by district name (lowercase) for fast text searching.
  final Map<String, List<LocationResult>> _districtIndex = {};

  /// Index of locations by village name (lowercase) for fast text searching.
  final Map<String, List<LocationResult>> _villageIndex = {};

  /// Creates a new [SpatialGrid] with the specified parameters.
  ///
  /// Parameters:
  /// - [gridSize]: Size of each grid cell in kilometers
  /// - [minLat]: Minimum latitude of the grid coverage
  /// - [minLng]: Minimum longitude of the grid coverage
  /// - [maxLat]: Maximum latitude of the grid coverage
  /// - [maxLng]: Maximum longitude of the grid coverage
  SpatialGrid({
    required this.gridSize,
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  /// Loads a [SpatialGrid] from asset data with the specified grid cell size.
  ///
  /// This factory method loads grid metadata and initial location data from
  /// bundled assets. The actual grid cells are loaded on demand when needed.
  ///
  /// Parameters:
  /// - [gridSize]: Size of each grid cell in kilometers
  ///
  /// Returns: A [Future] that completes with a fully initialized [SpatialGrid]
  static Future<SpatialGrid> load(int gridSize) async {
    // In practice, you would load your actual data here
    // For very large datasets, consider splitting into multiple files

    // This is a placeholder for how you'd load the grid
    final String rawData = await rootBundle.loadString(
      'packages/lao_location_prediction/assets/grid_metadata.json',
    );
    final metadata = jsonDecode(rawData);

    final grid = SpatialGrid(
      gridSize: gridSize,
      minLat: metadata['min_lat'],
      minLng: metadata['min_lng'],
      maxLat: metadata['max_lat'],
      maxLng: metadata['max_lng'],
    );

    // Load each grid cell on demand
    await grid._loadInitialData();

    return grid;
  }

  /// Loads initial location data into the grid.
  ///
  /// This method loads a default set of locations from the assets bundle
  /// and adds them to the grid and search indices.
  Future<void> _loadInitialData() async {
    final String jsonData = await rootBundle.loadString(
      'packages/lao_location_prediction/assets/default_data.json',
    );
    final List<dynamic> locations = jsonDecode(jsonData);

    for (var locationJson in locations) {
      final location = LocationResult.fromJson(locationJson);
      _addLocationToGrid(location);
      _addLocationToIndices(location);
    }
  }

  /// Loads data for a specific grid cell if it hasn't been loaded yet.
  ///
  /// This method attempts to load location data for the cell at coordinates (x,y)
  /// from the assets bundle. If the cell data file doesn't exist, an empty cell
  /// is created instead.
  ///
  /// Parameters:
  /// - [x]: The x-coordinate of the cell to load
  /// - [y]: The y-coordinate of the cell to load
  Future<void> _loadCell(int x, int y) async {
    final cellKey = '$x:$y';
    if (cells.containsKey(cellKey)) return;

    try {
      // In practice, you'd load cell data from a file or database
      final String jsonData = await rootBundle.loadString(
        'packages/lao_location_prediction/assets/cells/$cellKey.json',
      );
      final List<dynamic> locationList = jsonDecode(jsonData);

      final List<LocationResult> locations =
          locationList.map((json) => LocationResult.fromJson(json)).toList();

      cells[cellKey] = GridCell(x: x, y: y, locations: locations);

      // Add to indices
      for (var location in locations) {
        _addLocationToIndices(location);
      }
    } catch (e) {
      // Cell might not exist, which is fine
      cells[cellKey] = GridCell(x: x, y: y, locations: []);
    }
  }

  /// Adds a location to the appropriate grid cell.
  ///
  /// Calculates which cell the location belongs to based on its coordinates
  /// and adds it to that cell's list of locations.
  ///
  /// Parameters:
  /// - [location]: The [LocationResult] to add to the grid
  void _addLocationToGrid(LocationResult location) {
    final cellX =
        ((location.longitude - minLng) / _degreesPerKmLng() / gridSize).floor();
    final cellY =
        ((location.latitude - minLat) / _degreesPerKmLat() / gridSize).floor();
    final cellKey = '$cellX:$cellY';

    if (!cells.containsKey(cellKey)) {
      cells[cellKey] = GridCell(x: cellX, y: cellY, locations: []);
    }

    cells[cellKey]!.locations.add(location);
  }

  /// Adds a location to the text search indices.
  ///
  /// This method adds the location to the province, district, and village indices
  /// to enable fast text-based searches.
  ///
  /// Parameters:
  /// - [location]: The [LocationResult] to add to the indices
  void _addLocationToIndices(LocationResult location) {
    // Add to province index
    if (!_provinceIndex.containsKey(location.province.toLowerCase())) {
      _provinceIndex[location.province.toLowerCase()] = [];
    }
    _provinceIndex[location.province.toLowerCase()]!.add(location);

    // Add to district index
    if (!_districtIndex.containsKey(location.district.toLowerCase())) {
      _districtIndex[location.district.toLowerCase()] = [];
    }
    _districtIndex[location.district.toLowerCase()]!.add(location);

    // Add to village index
    if (!_villageIndex.containsKey(location.village.toLowerCase())) {
      _villageIndex[location.village.toLowerCase()] = [];
    }
    _villageIndex[location.village.toLowerCase()]!.add(location);
  }

  /// Calculates the number of degrees per kilometer of longitude.
  ///
  /// This is an approximation used for the Laos region.
  ///
  /// Returns: The number of degrees per kilometer of longitude
  double _degreesPerKmLng() {
    // Approximate value at Laos latitude
    return 0.0089;
  }

  /// Calculates the number of degrees per kilometer of latitude.
  ///
  /// This is an approximation that doesn't vary with longitude.
  ///
  /// Returns: The number of degrees per kilometer of latitude
  double _degreesPerKmLat() {
    // Approximate value
    return 0.0089;
  }

  /// Finds the nearest locations to a given point.
  ///
  /// This method searches for locations in the current cell and adjacent cells,
  /// calculates their distances from the specified point, and returns the
  /// closest ones.
  ///
  /// Parameters:
  /// - [latitude]: The latitude of the reference point
  /// - [longitude]: The longitude of the reference point
  /// - [limit]: The maximum number of results to return (default: 5)
  ///
  /// Returns: A list of [LocationResult] objects sorted by distance
  Future<List<LocationResult>> findNearest(
    double latitude,
    double longitude, {
    int limit = 5,
  }) async {
    final cellX =
        ((longitude - minLng) / _degreesPerKmLng() / gridSize).floor();
    final cellY = ((latitude - minLat) / _degreesPerKmLat() / gridSize).floor();

    // Load the cell and adjacent cells
    await _loadCell(cellX, cellY);
    await _loadCell(cellX + 1, cellY);
    await _loadCell(cellX - 1, cellY);
    await _loadCell(cellX, cellY + 1);
    await _loadCell(cellX, cellY - 1);
    await _loadCell(cellX + 1, cellY + 1);
    await _loadCell(cellX - 1, cellY - 1);
    await _loadCell(cellX + 1, cellY - 1);
    await _loadCell(cellX - 1, cellY + 1);

    // Collect all locations from loaded cells
    final allLocations = <LocationResult>[];
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final key = '${cellX + dx}:${cellY + dy}';
        if (cells.containsKey(key)) {
          allLocations.addAll(cells[key]!.locations);
        }
      }
    }

    // Calculate distances for all locations
    final locationsWithDistance =
        allLocations.map((location) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            location.latitude,
            location.longitude,
          );
          return LocationResult(
            latitude: location.latitude,
            longitude: location.longitude,
            province: location.province,
            district: location.district,
            village: location.village,
            distance: distance,
            id: location.id,
          );
        }).toList();

    // Sort by distance and return the top results
    locationsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return locationsWithDistance.take(limit).toList();
  }

  /// Finds all locations within a specified radius of a point.
  ///
  /// This method calculates which cells might contain locations within the
  /// given radius, loads those cells, and then filters the locations based
  /// on their actual distance.
  ///
  /// Parameters:
  /// - [latitude]: The latitude of the center point
  /// - [longitude]: The longitude of the center point
  /// - [radiusKm]: The search radius in kilometers
  ///
  /// Returns: A list of [LocationResult] objects within the radius, sorted by distance
  Future<List<LocationResult>> findWithinRadius(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    // Calculate the approximate cell range to check
    final cellRange = (radiusKm / gridSize).ceil() + 1;
    final cellX =
        ((longitude - minLng) / _degreesPerKmLng() / gridSize).floor();
    final cellY = ((latitude - minLat) / _degreesPerKmLat() / gridSize).floor();

    // Load all cells in the range
    for (var dx = -cellRange; dx <= cellRange; dx++) {
      for (var dy = -cellRange; dy <= cellRange; dy++) {
        await _loadCell(cellX + dx, cellY + dy);
      }
    }

    // Collect all locations from loaded cells
    final allLocations = <LocationResult>[];
    for (var dx = -cellRange; dx <= cellRange; dx++) {
      for (var dy = -cellRange; dy <= cellRange; dy++) {
        final key = '${cellX + dx}:${cellY + dy}';
        if (cells.containsKey(key)) {
          allLocations.addAll(cells[key]!.locations);
        }
      }
    }

    // Filter by radius and add distance
    final withinRadius =
        allLocations
            .map((location) {
              final distance = _calculateDistance(
                latitude,
                longitude,
                location.latitude,
                location.longitude,
              );
              return LocationResult(
                latitude: location.latitude,
                longitude: location.longitude,
                province: location.province,
                district: location.district,
                village: location.village,
                distance: distance,
                id: location.id,
              );
            })
            .where((location) => location.distance <= radiusKm * 1000)
            .toList();

    // Sort by distance
    withinRadius.sort((a, b) => a.distance.compareTo(b.distance));
    return withinRadius;
  }

  /// Searches for locations by name.
  ///
  /// This method searches the province, district, and village indices for
  /// matches containing the given query string.
  ///
  /// Parameters:
  /// - [query]: The search string to look for in location names
  ///
  /// Returns: A list of [LocationResult] objects that match the query
  Future<List<LocationResult>> searchByName(String query) async {
    if (query.isEmpty) return [];

    query = query.toLowerCase();
    final results = <LocationResult>{};

    // Search in province index
    _provinceIndex.forEach((province, locations) {
      if (province.contains(query)) {
        results.addAll(locations);
      }
    });

    // Search in district index
    _districtIndex.forEach((district, locations) {
      if (district.contains(query)) {
        results.addAll(locations);
      }
    });

    // Search in village index
    _villageIndex.forEach((village, locations) {
      if (village.contains(query)) {
        results.addAll(locations);
      }
    });

    return results.toList();
  }

  /// Retrieves all locations within a specified bounding box.
  ///
  /// This method calculates which cells might contain locations within the
  /// given bounding box, loads those cells, and then filters the locations
  /// based on their actual coordinates.
  ///
  /// Parameters:
  /// - [minLat]: The minimum latitude of the bounding box
  /// - [minLng]: The minimum longitude of the bounding box
  /// - [maxLat]: The maximum latitude of the bounding box
  /// - [maxLng]: The maximum longitude of the bounding box
  ///
  /// Returns: A list of [LocationResult] objects within the bounding box
  Future<List<LocationResult>> getLocationsInBoundingBox(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
  ) async {
    final minCellX =
        ((minLng - this.minLng) / _degreesPerKmLng() / gridSize).floor();
    final minCellY =
        ((minLat - this.minLat) / _degreesPerKmLat() / gridSize).floor();
    final maxCellX =
        ((maxLng - this.minLng) / _degreesPerKmLng() / gridSize).ceil();
    final maxCellY =
        ((maxLat - this.minLat) / _degreesPerKmLat() / gridSize).ceil();

    // Load all cells in the bounding box
    for (var x = minCellX; x <= maxCellX; x++) {
      for (var y = minCellY; y <= maxCellY; y++) {
        await _loadCell(x, y);
      }
    }

    // Collect all locations within the bounding box
    final results = <LocationResult>[];

    for (var x = minCellX; x <= maxCellX; x++) {
      for (var y = minCellY; y <= maxCellY; y++) {
        final key = '$x:$y';
        if (cells.containsKey(key)) {
          results.addAll(
            cells[key]!.locations.where(
              (location) =>
                  location.latitude >= minLat &&
                  location.latitude <= maxLat &&
                  location.longitude >= minLng &&
                  location.longitude <= maxLng,
            ),
          );
        }
      }
    }

    return results;
  }

  /// Calculates the distance in meters between two geographic points.
  ///
  /// This method uses the Haversine formula to calculate the great-circle
  /// distance between two points on the Earth's surface.
  ///
  /// Parameters:
  /// - [lat1]: Latitude of the first point in decimal degrees
  /// - [lon1]: Longitude of the first point in decimal degrees
  /// - [lat2]: Latitude of the second point in decimal degrees
  /// - [lon2]: Longitude of the second point in decimal degrees
  ///
  /// Returns: The distance in meters between the two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Converts degrees to radians.
  ///
  /// Parameters:
  /// - [degrees]: The angle in degrees
  ///
  /// Returns: The angle in radians
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
