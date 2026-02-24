import 'package:flutter/material.dart';

class ServiceUtils {
  static Color getServiceColor(String? tag, [String? label]) {
    final t = (tag ?? '').toUpperCase();
    final l = (label ?? '').toUpperCase();

    if (t == 'E' || t.contains('ENERGIA') || l.contains('ENERGIA')) {
      return Colors.red;
    }
    if (t == 'A' || t.contains('AGUA') || l.contains('AGUA')) {
      return Colors.blue;
    }
    if (t == 'I' || t.contains('INTERNET') || l.contains('INTERNET')) {
      return Colors.purple;
    }
    if (t == 'S' ||
        t.contains('SEPELIO') ||
        l.contains('SEPELIO') ||
        l.contains('SOCIAL')) {
      return Colors.yellow[700]!;
    }
    if (t == 'G' || t.contains('GAS') || l.contains('GAS')) {
      return Colors.orange;
    }

    return Colors.green;
  }

  static IconData getServiceIcon(String? tag, [String? label]) {
    final t = (tag ?? '').toUpperCase();
    final l = (label ?? '').toUpperCase();

    if (t == 'E' || t.contains('ENERGIA') || l.contains('ENERGIA')) {
      return Icons.bolt;
    }
    if (t == 'A' || t.contains('AGUA') || l.contains('AGUA')) {
      return Icons.water_drop;
    }
    if (t == 'I' || t.contains('INTERNET') || l.contains('INTERNET')) {
      return Icons.public;
    }
    if (t == 'S' ||
        t.contains('SEPELIO') ||
        l.contains('SEPELIO') ||
        l.contains('SOCIAL')) {
      return Icons.volunteer_activism;
    }
    if (t == 'G' || t.contains('GAS') || l.contains('GAS')) {
      return Icons.propane_tank;
    }

    return Icons.design_services;
  }
}
