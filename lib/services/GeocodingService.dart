import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressSuggestion {
  final String displayName;
  final double lat;
  final double lng;
  final String? houseNumber;
  final String? road;
  final String? city;
  final String? country;

  AddressSuggestion({
    required this.displayName,
    required this.lat,
    required this.lng,
    this.houseNumber,
    this.road,
    this.city,
    this.country,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    return AddressSuggestion(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lon'] as String),
      houseNumber: address?['house_number'] as String?,
      road: address?['road'] as String?,
      city: address?['city'] as String? ?? address?['town'] as String? ?? address?['village'] as String?,
      country: address?['country'] as String?,
    );
  }

  String get shortAddress {
    final parts = <String>[];
    if (road != null) parts.add(road!);
    if (houseNumber != null) parts.add(houseNumber!);
    if (city != null) parts.add(city!);
    return parts.isEmpty ? displayName : parts.join(', ');
  }
}

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'AlbiterkapApp/1.0';

  Future<List<AddressSuggestion>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'hu',
      });

      final response = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AddressSuggestion.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  Future<AddressSuggestion?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AddressSuggestion.fromJson(data);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
