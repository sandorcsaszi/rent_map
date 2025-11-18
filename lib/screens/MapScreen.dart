import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/bkk_stop.dart';
import '../services/PlaceService.dart';
import '../services/BkkService.dart';
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
  final BkkService _bkkService = BkkService();
  final MapController _mapController = MapController();
  List<Place> _places = [];
  List<BkkStop> _bkkStops = [];
  bool _isLoading = true;
  bool _loadingBkk = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    // Load BKK stops after a short delay to ensure map is initialized
    if (widget.showBkkStops) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadBkkStops();
        }
      });
    }
  }

  @override
  void didUpdateWidget(Mapscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload BKK stops when toggle changes
    if (widget.showBkkStops != oldWidget.showBkkStops) {
      if (widget.showBkkStops) {
        _loadBkkStops();
      } else {
        setState(() {
          _bkkStops = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleBkkStopsLoad() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Schedule new load after 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadBkkStops();
      }
    });
  }

  Future<void> _loadBkkStops() async {
    if (!widget.showBkkStops) return;

    final zoom = _mapController.camera.zoom;

    // Don't load stops if zoom is below 14
    if (!_bkkService.shouldShowStopsAtZoom(zoom)) {
      if (mounted) {
        setState(() {
          _bkkStops = [];
        });
      }
      return;
    }

    setState(() => _loadingBkk = true);
    try {
      final center = _mapController.camera.center;
      final radius = _bkkService.getRadiusForZoom(zoom);

      if (radius < 0) {
        // Zoom too low, clear stops
        if (mounted) {
          setState(() {
            _bkkStops = [];
          });
        }
        return;
      }

      final stops = await _bkkService.getStopsForLocation(
        lat: center.latitude,
        lon: center.longitude,
        radius: radius,
      );

      if (mounted) {
        setState(() {
          _bkkStops = stops;
        });
      }
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
    } catch (e) {
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
                    initialZoom: 16.0,
                    onMapEvent: (MapEvent event) {
                      // Schedule BKK stops reload with 500ms debounce
                      if (widget.showBkkStops &&
                          (event is MapEventMoveEnd || event is MapEventScrollWheelZoom)) {
                        _scheduleBkkStopsLoad();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rent_map',
                    ),
                    // BKK stops layer (shown behind place markers)
                    if (widget.showBkkStops && _bkkStops.isNotEmpty)
                      MarkerLayer(
                        markers: _bkkStops.map((stop) {
                          // Use the primary route color for the marker
                          final markerColor = stop.primaryColor;

                          return Marker(
                            point: LatLng(stop.lat, stop.lon),
                            width: 32,
                            height: 32,
                            child: GestureDetector(
                              onTap: () => _onBkkStopTap(stop),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: markerColor.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_transit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    // Place markers layer (shown on top)
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

  void _onBkkStopTap(BkkStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stop.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_transit,
                    color: stop.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stop.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stop.direction != null) ...[
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop.direction!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (stop.routes.isNotEmpty) ...[
              const Text(
                'Járatok:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stop.routes.where((route) => route.shortName.isNotEmpty).map((route) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: route.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: route.color.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      route.shortName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else if (stop.routeIds.isNotEmpty) ...[
              // Fallback if routes are not parsed properly
              const Text(
                'Járatok:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stop.routeIds.map((routeId) {
                  return Chip(
                    label: Text(routeId),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
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
