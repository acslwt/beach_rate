import 'package:flutter/material.dart';
import 'crowd_level.dart';
import 'map_spot.dart';

class CoolSpot {
  final String name;
  final String description;
  final String query;
  final Color backgroundColor;
  final SpotType type;
  final Color iconColor;
  final CrowdLevel crowd;

  const CoolSpot({
    required this.name,
    required this.description,
    required this.query,
    required this.backgroundColor,
    required this.type,
    required this.iconColor,
    required this.crowd,
  });
}
