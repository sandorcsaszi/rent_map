class Place {
  final int id;
  final String userId;
  final String name;
  final String title;
  final double lat;
  final double lng;
  final String desc;
  final String? website;
  final String address;
  final int rentPrice;
  final int utilityPrice;
  final int commonCost;
  final int floor;
  final bool hasElevator;

  Place({
    required this.id,
    required this.userId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.title,
    required this.desc,
    this.website,
    required this.address,
    required this.rentPrice,
    required this.utilityPrice,
    required this.commonCost,
    required this.floor,
    required this.hasElevator,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from any type
    int _parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    // Helper function to safely parse double from any type
    double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? defaultValue;
      if (value is num) return value.toDouble();
      return defaultValue;
    }

    return Place(
      id: _parseInt(json['id']),
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      desc: json['description']?.toString() ?? json['desc']?.toString() ?? '',
      website: json['link']?.toString(),
      address: json['address']?.toString() ?? '',
      rentPrice: _parseInt(json['rent_price']),
      utilityPrice: _parseInt(json['utility_cost'] ?? json['utility_price']),
      commonCost: _parseInt(json['common_cost'] ?? json['Common_cost']),
      floor: _parseInt(json['floor']),
      hasElevator: json['has_elevator'] == true || json['has_elevator'] == 'true',
    );
  }
}
