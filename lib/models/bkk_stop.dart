class BkkStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String type;

  const BkkStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });

  factory BkkStop.fromJson(Map<String, dynamic> json) {
    final latValue = json['lat'] ?? json['latitude'] ?? json['position']?['lat'];
    final lngValue = json['lon'] ?? json['lng'] ?? json['longitude'] ?? json['position']?['lon'];
    if (latValue == null || lngValue == null) {
      throw ArgumentError('Missing coordinates for stop ${json['id']}');
    }

    return BkkStop(
      id: json['id']?.toString() ?? json['stopId']?.toString() ?? 'unknown',
      name: json['name']?.toString() ?? json['stopName']?.toString() ?? 'Ismeretlen megálló',
      lat: (latValue as num).toDouble(),
      lng: (lngValue as num).toDouble(),
      type: json['type']?.toString() ?? json['stopType']?.toString() ?? 'stop',
    );
  }
}

