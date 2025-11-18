import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import '../services/PlaceService.dart';
import '../services/GeocodingService.dart';

class AddPlaceScreen extends StatefulWidget {
  final double lat;
  final double lng;

  const AddPlaceScreen({super.key, required this.lat, required this.lng});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _rentController = TextEditingController();
  final _utilityController = TextEditingController();
  final _commonCostController = TextEditingController();
  final _floorController = TextEditingController();

  bool _hasElevator = true;
  bool _loading = false;
  String? _error;

  final _placeService = PlaceService();
  final _geocodingService = GeocodingService();
  final _mapController = MapController();
  final _addressFocusNode = FocusNode();

  // Map and geocoding state
  late double _currentLat;
  late double _currentLng;
  List<AddressSuggestion> _addressSuggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.lat;
    _currentLng = widget.lng;

    // Listen to address field changes for autocomplete
    _addressController.addListener(_onAddressChanged);

    // Get initial address from coordinates
    _loadInitialAddress();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressFocusNode.dispose();
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _utilityController.dispose();
    _commonCostController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialAddress() async {
    final suggestion = await _geocodingService.reverseGeocode(_currentLat, _currentLng);
    if (suggestion != null && mounted) {
      // Remove listener temporarily to avoid triggering search
      _addressController.removeListener(_onAddressChanged);
      _addressController.text = suggestion.displayName;
      _addressController.addListener(_onAddressChanged);
    }
  }

  void _onAddressChanged() {
    final text = _addressController.text;

    // Debounce the search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (text.length >= 3) {
        _searchAddress(text);
      } else {
        if (mounted) {
          setState(() {
            _addressSuggestions = [];
            _showSuggestions = false;
          });
        }
      }
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);

    final suggestions = await _geocodingService.searchAddress(query);

    if (mounted) {
      setState(() {
        _addressSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
        _isSearching = false;
      });
    }
  }

  void _selectAddress(AddressSuggestion suggestion) {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    setState(() {
      _currentLat = suggestion.lat;
      _currentLng = suggestion.lng;
      _showSuggestions = false;
      _addressSuggestions = [];
    });

    // Set text after hiding suggestions to avoid retriggering search
    _addressController.text = suggestion.displayName;

    // Animate map to new location
    _mapController.move(LatLng(suggestion.lat, suggestion.lng), 16.0);
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    // Cancel any pending search
    _debounceTimer?.cancel();

    setState(() {
      _currentLat = latlng.latitude;
      _currentLng = latlng.longitude;
      _showSuggestions = false;
      _addressSuggestions = [];
    });

    // Get address for tapped location
    _geocodingService.reverseGeocode(latlng.latitude, latlng.longitude).then((suggestion) {
      if (suggestion != null && mounted) {
        // Remove listener temporarily to avoid triggering search
        _addressController.removeListener(_onAddressChanged);
        _addressController.text = suggestion.displayName;
        _addressController.addListener(_onAddressChanged);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _placeService.createPlace(
        name: _nameController.text.trim(),
        title: _nameController.text.trim(),
        desc: _descController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        address: _addressController.text.trim(),
        lat: _currentLat,
        lng: _currentLng,
        rentPrice: int.tryParse(_rentController.text.trim()) ?? 0,
        utilityPrice: int.tryParse(_utilityController.text.trim()) ?? 0,
        commonCost: int.tryParse(_commonCostController.text.trim()) ?? 0,
        floor: int.tryParse(_floorController.text.trim()) ?? 0,
        hasElevator: _hasElevator,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // indicate success to caller
    } catch (e) {
      setState(() {
        _error = 'Hiba mentés közben: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Új hely hozzáadása'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],

              // Interactive Map
              _buildSectionCard(
                title: 'Hely kiválasztása',
                emoji: '🗺️',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Koppints a térképre a pontos hely kijelöléséhez',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_currentLat, _currentLng),
                            initialZoom: 15.0,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.rent_map',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_currentLat, _currentLng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Address Search with Autocomplete
              _buildAddressSearchField(),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameController,
                label: 'Név / címke',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Kötelező mező' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descController,
                label: 'Leírás',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _websiteController,
                label: 'Link (weboldal URL)',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Részletes költségek
              _buildSectionCard(
                title: 'Részletes költségek',
                emoji: '💰',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _rentController,
                      label: 'Bérleti díj (Ft/hó)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _utilityController,
                      label: 'Rezsi költség (Ft/hó)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _commonCostController,
                      label: 'Közös költség (Ft/hó)',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ingatlan részletek
              _buildSectionCard(
                title: 'Ingatlan részletek',
                emoji: '📚',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _floorController,
                      label: 'Emelet (pl: 3)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _elevatorButton(
                            label: 'Van lift',
                            selected: _hasElevator,
                            onTap: () => setState(() => _hasElevator = true),
                            icon: Icons.elevator,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _elevatorButton(
                            label: 'Nincs lift',
                            selected: !_hasElevator,
                            onTap: () => setState(() => _hasElevator = false),
                            icon: Icons.block,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: const Icon(Icons.check_box),
                      label: const Text('Hozzáadás'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Mégse'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String emoji,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji  $title',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _elevatorButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1976D2) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _showSuggestions
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _addressController,
                focusNode: _addressFocusNode,
                decoration: InputDecoration(
                  labelText: '📍 Cím keresése',
                  hintText: 'Írj be legalább 3 karaktert...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _addressController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _addressController.clear();
                                setState(() {
                                  _showSuggestions = false;
                                  _addressSuggestions = [];
                                });
                              },
                            )
                          : const Icon(Icons.search),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Kötelező mező' : null,
                onTap: () {
                  // Show suggestions again if we have text
                  if (_addressController.text.length >= 3 && _addressSuggestions.isNotEmpty) {
                    setState(() {
                      _showSuggestions = true;
                    });
                  }
                },
              ),
              if (_showSuggestions && _addressSuggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _addressSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _addressSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 20),
                        title: Text(
                          suggestion.shortAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          suggestion.displayName,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectAddress(suggestion),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_showSuggestions && _addressSuggestions.isEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Nincs találat',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
