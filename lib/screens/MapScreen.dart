import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/bkk_stop.dart';
import '../services/PlaceService.dart';
import '../services/BkkStopsService.dart';
import '../widgets/placeListSheet.dart';
import 'AddPlaceScreen.dart';

class Mapscreen extends StatefulWidget {
  final Session session;
  final bool showBkkStops;

  const Mapscreen({super.key, required this.session, required this.showBkkStops});

  @override
  State<Mapscreen> createState() => _MapscreenState();
}

class _MapscreenState extends State<Mapscreen> {
  final PlaceService _placeService = PlaceService();
  final BkkStopsService _bkkService = BkkStopsService();
  final MapController _mapController = MapController();
  List<Place> _places = [];
  List<BkkStop> _bkkStops = [];
  bool _isLoading = true;
  bool _loadingBkk = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    if (widget.showBkkStops) {
      _loadBkkStops();
    }
  }

  @override
  void didUpdateWidget(Mapscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBkkStops != widget.showBkkStops) {
      if (widget.showBkkStops && _bkkStops.isEmpty) {
        _loadBkkStops();
      }
      setState(() {});
    }
  }

  Future<void> _loadBkkStops() async {
    setState(() => _loadingBkk = true);
    try {
      final center = _mapController.camera.center;
      final stops = await _bkkService.loadStops(lat: center.latitude, lng: center.longitude);
      setState(() => _bkkStops = stops);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nem sikerült betölteni a BKK megállókat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingBkk = false);
      }
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    try {
      final places = await _placeService.getUserPlaces();
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba a helyek betöltésekor: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      debugPrint('Error loading places: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albitérkép'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _places.isNotEmpty
                        ? LatLng(_places.first.lat, _places.first.lng)
                        : const LatLng(47.4979, 19.0402),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rent_map',
                    ),
                    if (widget.showBkkStops)
                      MarkerLayer(
                        markers: _bkkStops.map((stop) {
                          return Marker(
                            point: LatLng(stop.lat, stop.lng),
                            width: 24,
                            height: 24,
                            child: Tooltip(
                              message: stop.name,
                              child: const Icon(
                                Icons.directions_transit,
                                size: 22,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    MarkerLayer(
                      markers: _places.map((place) {
                        return Marker(
                          point: LatLng(place.lat, place.lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _onPlaceMarkerTap(place),
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
                if (widget.showBkkStops && _loadingBkk)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Chip(
                      avatar: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: Text('BKK betöltése...'),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 140,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final center = _mapController.camera.center;
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AddPlaceScreen(
                            lat: center.latitude,
                            lng: center.longitude,
                          ),
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
                ),
                PlaceListSheet(
                  places: _places,
                  onRefresh: _loadPlaces,
                  onPlaceTap: _onPlaceMarkerTap,
                  maxChildSize: 0.9,
                  initialChildSize: 0.15,
                  minChildSize: 0.15,
                ),
              ],
            ),
    );
  }

  void _onPlaceMarkerTap(Place place) {
    _mapController.move(LatLng(place.lat, place.lng), 16.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 100),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(place.address)),
              ],
            ),
            const SizedBox(height: 12),
            Text(place.desc, style: const TextStyle(fontSize: 15)),
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

  Widget _buildPriceChip(String label, int price) => Chip(label: Text('$label: $price Ft'));
}
