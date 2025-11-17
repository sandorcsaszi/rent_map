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

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as int,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    title: json['title'] as String,
    desc: json['desc'] as String,
    website: json['website'] as String?,
    address: json['address'] as String,
    rentPrice: json['rent_price'] as int,
    utilityPrice: json['utility_price'] as int,
    commonCost: json['Common_cost'] as int,
    floor: json['floor'] as int,
    hasElevator: json['has_elevator'] == true,
  );
}
