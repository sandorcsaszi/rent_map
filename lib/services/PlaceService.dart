import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

class PlaceService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return response as Map<String, dynamic>?;
  }

  Future<void> updateProfileName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Place>> getUserPlaces() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final response = await _client
        .from('places')
        .select()
        .eq('user_id', user.id);

    // Debug: naplózzuk a nyers adatokat
    print('Places raw data: $response');

    try {
      final places = (response as List).map((json) {
        print('Parsing place: $json');
        return Place.fromJson(json);
      }).toList();

      print('Successfully parsed ${places.length} places');
      return places;
    } catch (e, stackTrace) {
      print('Error parsing places: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> createPlace({
    required String name,
    required String title,
    required String desc,
    required String? website,
    required String address,
    required double lat,
    required double lng,
    required int rentPrice,
    required int utilityPrice,
    required int commonCost,
    required int floor,
    required bool hasElevator,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final payload = {
      'user_id': user.id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'title': title,
      'description': desc,
      'link': website,
      'address': address,
      'rent_price': rentPrice,
      'utility_cost': utilityPrice,
      'common_cost': commonCost,
      'floor': floor,
      'has_elevator': hasElevator,
    };

    await _client.from('places').insert(payload).select().single();
  }
}
