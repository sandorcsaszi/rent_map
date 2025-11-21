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
  final BkkService _bkk_service = BkkService();
  final MapController _mapController = MapController();
  List<Place> _places = [];
  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  List<BkkStop> _bkkStops = [];
  bool _isLoading = true;
  bool _loadingBkk = false;
  Timer? _debounceTimer;

  // Filter state
  static const int _defaultMaxPrice = 200000;
  RangeValues _rentRange = RangeValues(0, _defaultMaxPrice.toDouble());
  RangeValues _utilityRange = RangeValues(0, _defaultMaxPrice.toDouble());
  RangeValues _commonRange = RangeValues(0, _defaultMaxPrice.toDouble());
  bool _filterElevator = false;
  int? _selectedFloor; // null means 'egyik sem'

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    // Live search: listen to controller and debounce changes
    _searchController.addListener(_onSearchChanged);
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
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
    if (!_bkk_service.shouldShowStopsAtZoom(zoom)) {
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
      final radius = _bkk_service.getRadiusForZoom(zoom);

      if (radius < 0) {
        // Zoom too low, clear stops
        if (mounted) {
          setState(() {
            _bkkStops = [];
          });
        }
        return;
      }

      final stops = await _bkk_service.getStopsForLocation(
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

  void _onSearchChanged() {
    // Debounce typing to avoid excessive setState calls
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      if (q != _searchQuery) {
        setState(() {
          _searchQuery = q;
        });
      }
    });
  }

  // Open filter modal sheet
  void _openFilterSheet() {
    // Temporary values so changes are applied only when user confirms
    RangeValues tmpRent = _rentRange;
    RangeValues tmpUtility = _utilityRange;
    RangeValues tmpCommon = _commonRange;
    bool tmpElevator = _filterElevator;
    int? tmpFloor = _selectedFloor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Szűrők', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRangeFilterSection(
                  label: 'Bérleti díj (Ft)',
                  values: tmpRent,
                  maxLimit: _defaultMaxPrice.toDouble(),
                  onChanged: (v) => setModalState(() => tmpRent = v),
                ),
                const SizedBox(height: 8),
                _buildRangeFilterSection(
                  label: 'Rezsi költség (Ft)',
                  values: tmpUtility,
                  maxLimit: _defaultMaxPrice.toDouble(),
                  onChanged: (v) => setModalState(() => tmpUtility = v),
                ),
                const SizedBox(height: 8),
                _buildRangeFilterSection(
                  label: 'Közös költség (Ft)',
                  values: tmpCommon,
                  maxLimit: _defaultMaxPrice.toDouble(),
                  onChanged: (v) => setModalState(() => tmpCommon = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Van lift'),
                  value: tmpElevator,
                  onChanged: (v) => setModalState(() => tmpElevator = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Emelet:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: tmpFloor,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('egyik sem')),
                          for (var f = 0; f <= 10; f++)
                            DropdownMenuItem<int?>(
                              value: f,
                              child: Text(f == 0 ? '0 — földszint' : '$f. emelet'),
                            ),
                        ],
                        onChanged: (v) => setModalState(() => tmpFloor = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tmpRent = RangeValues(0, _defaultMaxPrice.toDouble());
                          tmpUtility = RangeValues(0, _defaultMaxPrice.toDouble());
                          tmpCommon = RangeValues(0, _defaultMaxPrice.toDouble());
                          tmpElevator = false;
                          tmpFloor = null;
                        });
                      },
                      child: const Text('Alaphelyzet'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _rentRange = tmpRent;
                          _utilityRange = tmpUtility;
                          _commonRange = tmpCommon;
                          _filterElevator = tmpElevator;
                          _selectedFloor = tmpFloor;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Alkalmaz'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRangeFilterSection({
    required String label,
    required RangeValues values,
    required double maxLimit,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('${values.start.round()} Ft'),
            const Spacer(),
            Text('${values.end.round()} Ft'),
          ],
        ),
        RangeSlider(
          values: values,
          min: 0,
          max: maxLimit < 1 ? _defaultMaxPrice.toDouble() : maxLimit,
          divisions: 20,
          labels: RangeLabels('${values.start.round()}', '${values.end.round()}'),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // compute filtered places based on live search query and active filters
    final filteredPlaces = _places.where((p) {
      if (_searchQuery.isNotEmpty && !p.title.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      if (p.rentPrice < _rentRange.start.round() || p.rentPrice > _rentRange.end.round()) return false;
      if (p.utilityPrice < _utilityRange.start.round() || p.utilityPrice > _utilityRange.end.round()) return false;
      if (p.commonCost < _commonRange.start.round() || p.commonCost > _commonRange.end.round()) return false;
      if (_filterElevator && !p.hasElevator) return false;
      if (_selectedFloor != null && p.floor != _selectedFloor) return false;
      return true;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albitérkép'),
        // Add a visible, non-functional search bar under the title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha((0.04 * 255).round()),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.iconTheme.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      enabled: true,
                      decoration: InputDecoration(
                        hintText: 'Keresés...',
                        border: InputBorder.none,
                        isDense: true,
                        filled: true,
                        // use surfaceContainerHighest to contrast with the outer container across themes
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round())),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  // Filter button placed next to the search field
                  IconButton(
                    tooltip: 'Szűrők',
                    icon: Icon(
                      Icons.filter_list,
                      color: (_filterElevator || _selectedFloor != null || _rentRange.start > 0 || _rentRange.end < _defaultMaxPrice || _utilityRange.start > 0 || _utilityRange.end < _defaultMaxPrice || _commonRange.start > 0 || _commonRange.end < _defaultMaxPrice)
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Prefer centering on the first filtered place (if any),
                    // otherwise fall back to the first loaded place or the default coords.
                    initialCenter: filteredPlaces.isNotEmpty
                        ? LatLng(filteredPlaces.first.lat, filteredPlaces.first.lng)
                        : (_places.isNotEmpty
                            ? LatLng(_places.first.lat, _places.first.lng)
                            : const LatLng(47.4979, 19.0402)),
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
                    // Place markers layer (shown on top) — show only filtered places
                    MarkerLayer(
                      markers: filteredPlaces.map((place) {
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
                  places: filteredPlaces,
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
