import 'package:flutter/material.dart';

import '../services/PlaceService.dart';

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

  @override
  void dispose() {
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
        lat: widget.lat,
        lng: widget.lng,
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
}
