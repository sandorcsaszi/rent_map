import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceService {
  final _client = Supabase.instance.client;

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

    final res = await _client.from('places').insert(payload).select().single();
  }
}
