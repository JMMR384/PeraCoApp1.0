enum PointType { pickup, delivery, me }

class MapPoint {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final PointType type;

  const MapPoint({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.type,
  });
}
