import '../../models/models.dart';

class GridCell {
  final int x;
  final int y;
  final List<LocationResult> locations;

  GridCell({required this.x, required this.y, required this.locations});
}
