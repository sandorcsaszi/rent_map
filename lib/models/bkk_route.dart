import 'package:flutter/material.dart';

class BkkRoute {
  final String id;
  final String shortName;
  final Color color;
  final String? description;
  final String? type;

  BkkRoute({
    required this.id,
    required this.shortName,
    required this.color,
    this.description,
    this.type,
  });

  factory BkkRoute.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final shortName = json['shortName'] as String? ?? id;
    final description = json['description'] as String?;
    final type = json['type'] as String?;

    String? colorHex = json['color'] as String?;

    if (colorHex == null) {
      final style = json['style'] as Map<String, dynamic>?;
      colorHex = style?['color'] as String?;
    }

    final color = _parseColor(colorHex, id);

    return BkkRoute(
      id: id,
      shortName: shortName,
      color: color,
      description: description,
      type: type,
    );
  }

  static Color _parseColor(String? hexString, String routeId) {
    if (hexString == null || hexString.isEmpty) {
      return _getDefaultColorForRoute(routeId);
    }

    String hex = hexString.replaceAll('#', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return _getDefaultColorForRoute(routeId);
    }
  }

  static Color _getDefaultColorForRoute(String routeId) {
    final id = routeId.toUpperCase();

    if (id.startsWith('M1')) return const Color(0xFFFFD800);
    if (id.startsWith('M2')) return const Color(0xFFE71D73);
    if (id.startsWith('M3')) return const Color(0xFF007AC9);
    if (id.startsWith('M4')) return const Color(0xFF00A53F);

    if (id.contains('TRAM') || RegExp(r'^[1-6][0-9]?[A-Z]?$').hasMatch(id)) {
      return const Color(0xFFFF8800);
    }

    if (id.contains('TROLLEY') || id.startsWith('7')) {
      return const Color(0xFFFF0000);
    }

    if (id.contains('BUS') || RegExp(r'^\d{1,3}[A-Z]?$').hasMatch(id)) {
      return const Color(0xFF007AC9);
    }

    if (id.contains('HEV') || id.startsWith('H')) {
      return const Color(0xFF00A53F);
    }

    return const Color(0xFF007AC9);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shortName': shortName,
        'color': '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'description': description,
        'type': type,
      };
}
