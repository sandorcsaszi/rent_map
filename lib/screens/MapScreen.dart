import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../services/PlaceService.dart';
import 'AddPlaceScreen.dart';

class Mapscreen extends StatefulWidget {
  final Session session;

  const Mapscreen({super.key, required this.session});

  @override
  State<Mapscreen> createState() => _MapscreenState();
}

class _MapscreenState extends State<Mapscreen> {
  final PlaceService _placeService = PlaceService();
  final MapController _mapController = MapController();
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    try {
      print('Loading places...');
      final places = await _placeService.getUserPlaces();
      print('Loaded ${places.length} places');
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading places: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba a helyek betöltésekor: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albitérkép'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _places.isNotEmpty
                    ? LatLng(_places.first.lat, _places.first.lng)
                    : const LatLng(47.4979, 19.0402), // Budapest
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.rent_map',
                ),
                MarkerLayer(
                  markers: _places.map((place) {
                    return Marker(
                      point: LatLng(place.lat, place.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          _showPlaceDetails(place);
                        },
                        child: const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Get current map center or use default Budapest coordinates
          final center = _mapController.camera.center;
          final lat = center.latitude;
          final lng = center.longitude;

          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddPlaceScreen(lat: lat, lng: lng),
            ),
          );

          if (result == true) {
            _loadPlaces();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hely sikeresen hozzáadva')),
              );
            }
          }
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(place.address),
            const SizedBox(height: 8),
            Text(place.desc),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriceChip('Albérlet', place.rentPrice),
                _buildPriceChip('Rezsi', place.utilityPrice),
                _buildPriceChip('Közös költség', place.commonCost),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Emelet: ${place.floor}'),
                const SizedBox(width: 16),
                if (place.hasElevator)
                  const Row(
                    children: [
                      Icon(Icons.elevator, size: 16),
                      SizedBox(width: 4),
                      Text('Van lift'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, int price) {
    return Chip(
      label: Text('$label: ${price.toString()} Ft'),
    );
  }
}
