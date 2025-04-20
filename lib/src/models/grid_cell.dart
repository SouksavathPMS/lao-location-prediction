import '../../models/models.dart';

/// Represents a cell in a spatial grid system used for location indexing.
///
/// Each grid cell contains geographic coordinates (x, y) that define its position
/// in the grid and a collection of [LocationResult] objects that fall within the
/// boundaries of this cell.
class GridCell {
  /// The x-coordinate (column) of this cell in the grid.
  final int x;

  /// The y-coordinate (row) of this cell in the grid.
  final int y;

  /// Collection of location results that are contained within this grid cell.
  final List<LocationResult> locations;

  /// Creates a new [GridCell] with the specified coordinates and locations.
  ///
  /// Parameters:
  /// - [x]: The x-coordinate (column) in the grid
  /// - [y]: The y-coordinate (row) in the grid
  /// - [locations]: List of [LocationResult] objects within this cell
  GridCell({required this.x, required this.y, required this.locations});
}
