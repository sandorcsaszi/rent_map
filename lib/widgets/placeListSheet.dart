import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceListSheet extends StatelessWidget {
  final List<Place> places;
  final Future<void> Function()? onRefresh;
  final void Function(Place)? onPlaceTap;

  const PlaceListSheet({
    super.key,
    required this.places,
    this.onRefresh,
    this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apartment, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Talált helyek: ${places.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: ListView.builder(
                    controller: scrollController, // important!
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final p = places[index];
                      return _PlaceListTile(
                        place: p,
                        onTap: () => onPlaceTap?.call(p),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;

  const _PlaceListTile({required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = '${place.rentPrice} Ft/hó';
    final extraCosts = (place.utilityPrice + place.commonCost) > 0
        ? ' + rezsi'
        : '';

    return ListTile(
      title: Text(place.name),
      subtitle: Text(
        '${place.address}\n$price$extraCosts',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      leading: Icon(place.hasElevator ? Icons.elevator : Icons.stairs),
      trailing: Text(
        '${place.floor}. emelet',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
