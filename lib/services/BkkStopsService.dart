import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/bkk_stop.dart';

class BkkStopsService {
  static const _endpoint = 'https://futar.bkk.hu/api/query/v1/ws/otp/api/where/stops-for-location.json';
  List<BkkStop>? _cache;
  DateTime? _cacheTime;

  Future<List<BkkStop>> loadStops({required double lat, required double lng, double radius = 3000}) async {
    if (_cache != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age.inMinutes < 15) {
        return _cache!;
      }
    }

    final apiKey = dotenv.env['BKK_FUTAR_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Hiányzó BKK_FUTAR_API_KEY az .env fájlban');
    }

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'radius': radius.toString(),
      'routeTypes': 'bus,tram,metro,rail,ship',
      'includeReferences': 'false',
      'apiKey': apiKey,
    });

    final response = await http.get(uri, headers: {'accept': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('BKK API hiba: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final list = decoded['data']?['list'] as List<dynamic>?;
    if (list == null) {
      throw Exception('Érvénytelen BKK válasz: ${response.body}');
    }

    final stops = list.map((item) => BkkStop.fromJson(item as Map<String, dynamic>)).toList();
    _cache = stops;
    _cacheTime = DateTime.now();
    return stops;
  }
}

