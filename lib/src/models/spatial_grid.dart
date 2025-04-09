import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import 'models.dart';

class SpatialGrid {
  final int gridSize; // in kilometers
  final Map<String, GridCell> cells = {};
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  // In-memory index for searching
  final Map<String, List<LocationResult>> _provinceIndex = {};
  final Map<String, List<LocationResult>> _districtIndex = {};
  final Map<String, List<LocationResult>> _villageIndex = {};

  SpatialGrid({
    required this.gridSize,
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  // Loads the spatial grid from compressed binary data
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

  // Loads initial data
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

  // Load a specific cell when needed
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

  // Calculate the size of one degree of longitude in km at a given latitude
  double _degreesPerKmLng() {
    // Approximate value at Laos latitude
    return 0.0089;
  }

  // Calculate the size of one degree of latitude in km
  double _degreesPerKmLat() {
    // Approximate value
    return 0.0089;
  }

  // Find the nearest locations to a point
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

  // Find locations within a radius
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

  // Search locations by name
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

  // Get locations within a bounding box
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

  // Calculate the distance in meters between two points
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

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
