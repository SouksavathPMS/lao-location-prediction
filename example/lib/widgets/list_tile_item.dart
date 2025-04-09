import 'package:flutter/material.dart';
import 'package:lao_location_prediction/models/models.dart';

class ListTileItem extends StatelessWidget {
  const ListTileItem({super.key, required this.location});

  final LocationResult location;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "${location.province}, ${location.district}, ${location.village}",
      ),
      subtitle: Text("${location.latitude}, ${location.longitude}"),
      isThreeLine: true,
      leading: CircleAvatar(
        child: Text(
          "${(location.distance / 1000).toStringAsFixed(2)}\n Km",
          style: TextStyle(fontSize: 8),
        ),
      ),

      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
