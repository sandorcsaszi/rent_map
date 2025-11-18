import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/bkk_stop.dart';

class BkkService {
  final String _baseUrl = dotenv.env['BKK_FUTAR_API_URL'] ?? 'https://futar.bkk.hu/api/query/v1/ws/otp/api/where';
  final String _apiKey = dotenv.env['BKK_FUTAR_API_KEY'] ?? '';

  Future<List<BkkStop>> getStopsForLocation({
    required double lat,
    required double lon,
    int radius = 200,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/stops-for-location')
          .replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radius.toString(),
        'key': _apiKey,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final dataSection = data['data'] as Map<String, dynamic>?;
        if (dataSection == null) {
          return [];
        }

        final list = dataSection['list'] as List?;
        if (list == null || list.isEmpty) {
          return [];
        }

        final references = dataSection['references'] as Map<String, dynamic>?;
        final routes = references?['routes'] as Map<String, dynamic>?;

        final bkkStops = <BkkStop>[];
        for (final stopData in list) {
          try {
            bkkStops.add(BkkStop.fromJson(
              stopData as Map<String, dynamic>,
              routes,
            ));
          } catch (_) {
            continue;
          }
        }

        return bkkStops;
      } else {
        throw Exception('Failed to load BKK stops: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching BKK stops: $e');
    }
  }

  int getRadiusForZoom(double zoom) {
    if (zoom < 14) return -1;

    if (zoom >= 17) return 200;
    if (zoom >= 16) return 300;
    if (zoom >= 15) return 500;
    if (zoom >= 14) return 800;

    return -1;
  }

  bool shouldShowStopsAtZoom(double zoom) {
    return zoom >= 14;
  }
}
