import 'package:flutter/material.dart';
import 'bkk_route.dart';

class BkkStop {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? direction;
  final List<String> routeIds;
  final List<BkkRoute> routes;

  BkkStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.direction,
    this.routeIds = const [],
    this.routes = const [],
  });

  Color get primaryColor {
    if (routes.isNotEmpty) {
      return routes.first.color;
    }
    return const Color(0xFF007AC9);
  }

  factory BkkStop.fromJson(Map<String, dynamic> json, Map<String, dynamic>? routesData) {
    final lat = json['lat'] as double? ?? 0.0;
    final lon = json['lon'] as double? ?? 0.0;
    final name = json['name'] as String? ?? 'Unknown';
    final id = json['id'] as String? ?? '';
    final direction = json['direction'] as String?;

    final routeIds = <String>[];
    if (json['routeIds'] != null) {
      final routes = json['routeIds'] as List;
      routeIds.addAll(routes.map((e) => e.toString()));
    }

    final routesList = <BkkRoute>[];
    if (routesData != null) {
      for (final routeId in routeIds) {
        final routeData = routesData[routeId];
        if (routeData != null) {
          try {
            routesList.add(BkkRoute.fromJson(routeData as Map<String, dynamic>));
          } catch (_) {
            continue;
          }
        }
      }
    }

    return BkkStop(
      id: id,
      name: name,
      lat: lat,
      lon: lon,
      direction: direction,
      routeIds: routeIds,
      routes: routesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'direction': direction,
        'routeIds': routeIds,
        'routes': routes.map((r) => r.toJson()).toList(),
      };
}
