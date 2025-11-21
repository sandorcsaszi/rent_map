import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceListSheet extends StatelessWidget {
  final List<Place> places;
  final Future<void> Function()? onRefresh;
  final void Function(Place)? onPlaceTap;
  final double maxChildSize;
  final double initialChildSize;
  final double minChildSize;

  const PlaceListSheet({
    super.key,
    required this.places,
    this.onRefresh,
    this.onPlaceTap,
    this.maxChildSize = 0.9,
    this.initialChildSize = 0.15,
    this.minChildSize = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: const [0.15, 0.5, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SheetHeaderDelegate(placeCount: places.length),
                      ),
                      if (places.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyPlacesPlaceholder(),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final place = places[index];
                              return _PlaceListTile(
                                place: place,
                                onTap: () => onPlaceTap?.call(place),
                              );
                            },
                            childCount: places.length,
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
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

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int placeCount;

  const _SheetHeaderDelegate({required this.placeCount});

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.apartment, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Talált helyek: $placeCount',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) =>
      oldDelegate.placeCount != placeCount;
}

class _EmptyPlacesPlaceholder extends StatelessWidget {
  const _EmptyPlacesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Még nincsenek helyek',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Koppints a + gombra új hely hozzáadásához',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
