// dart
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
    // Do not capture Theme here; resolve it inside the DraggableScrollableSheet
    // builder so the sheet reacts to runtime theme changes immediately.
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: const [0.15, 0.5, 0.9],
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        final surface = theme.colorScheme.surface;
        final shadowColor = theme.shadowColor.withAlpha((0.2 * 255).round());
        // Pass a small theme hash into the header delegate so the sliver header
        // knows to rebuild when theme changes (otherwise it only compares
        // placeCount and might not rebuild on theme updates).
        final themeHash = theme.colorScheme.hashCode;

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: shadowColor)],
          ),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: onRefresh ?? () async {},
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SheetHeaderDelegate(placeCount: places.length, themeHash: themeHash),
                      ),
                      if (places.isEmpty)
                        SliverFillRemaining(
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
  final int themeHash;

  _SheetHeaderDelegate({required this.placeCount, required this.themeHash});

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final handleColor = theme.dividerColor;
    final textStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: onSurface);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.apartment, size: 18, color: onSurface),
                const SizedBox(width: 8),
                Text(
                  'Talált helyek: $placeCount',
                  style: textStyle,
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
      oldDelegate.placeCount != placeCount || oldDelegate.themeHash != themeHash;
}

class _EmptyPlacesPlaceholder extends StatelessWidget {
  const _EmptyPlacesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withAlpha((0.4 * 255).round());
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.9 * 255).round()), fontSize: 16);
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()), fontSize: 14);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(
            'Még nincsenek helyek',
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Koppints a + gombra új hely hozzáadásához',
            style: subtitleStyle,
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
    final theme = Theme.of(context);
    final price = '${place.rentPrice} Ft/hó';
    final extraCosts = (place.utilityPrice + place.commonCost) > 0 ? ' + rezsi' : '';
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).round()));
    final trailingStyle = theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface);

    return ListTile(
      title: Text(place.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
      subtitle: Text(
        '${place.address}\n$price$extraCosts',
        style: subtitleStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      leading: Icon(place.hasElevator ? Icons.elevator : Icons.stairs, color: theme.iconTheme.color),
      trailing: Text(
        place.floor == 0 ? 'Földszint' : '${place.floor}. emelet',
        style: trailingStyle,
      ),
      onTap: onTap,
    );
  }
}
