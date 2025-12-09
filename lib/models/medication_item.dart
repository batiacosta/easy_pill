import 'package:flutter/material.dart';

class MedicationItem {
  final String name;
  final String time;
  final IconData icon;
  final Color color;
  final Color bgColor;
  bool isTaken;

  MedicationItem({
    required this.name,
    required this.time,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isTaken,
  });
}
