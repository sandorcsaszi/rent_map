import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

class PlaceService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      // Ensure we have a valid session
      final session = _client.auth.currentSession;
      if (session == null) {
        print('No active session');
        return null;
      }

      final user = _client.auth.currentUser;
      if (user == null) {
        print('No current user');
        return null;
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      // Return null instead of throwing to allow graceful fallback
      return null;
    }
  }

  Future<void> updateProfileName(String name) async {
    try {
      // Check session first
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session - please login again');
      }

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating profile: $e');
      // Re-throw with more context
      if (e.toString().contains('oauth_client_id') ||
          e.toString().contains('AuthRetryableFetchException')) {
        throw Exception('Session expired - please login again');
      }
      rethrow;
    }
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

    // Debug: log raw data
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

  Future<void> updatePlace({
    required String id,
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
    final payload = {
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
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('places').update(payload).eq('id', id);
  }

  Future<void> deletePlace(String id) async {
    await _client.from('places').delete().eq('id', id);
  }
}
