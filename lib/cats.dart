import 'package:flutter/material.dart';

const Color kFijo = Color(0xFF4FC3F7);
const Color kVar = Color(0xFFB39DFF);
const Color kHormiga = Color(0xFFF7C948);

IconData catIcon(String c) {
  switch (c) {
    case 'Delivery':
      return Icons.delivery_dining;
    case 'Café':
      return Icons.local_cafe_outlined;
    case 'Snacks':
      return Icons.cookie_outlined;
    case 'Taxi':
      return Icons.local_taxi_outlined;
    case 'Comida':
      return Icons.restaurant_outlined;
    case 'Transporte':
      return Icons.directions_bus_outlined;
    case 'Salud':
      return Icons.medical_services_outlined;
    default:
      return Icons.more_horiz;
  }
}

IconData fixedIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('alquiler')) return Icons.home_outlined;
  if (n.contains('luz')) return Icons.bolt;
  if (n.contains('agua')) return Icons.water_drop_outlined;
  if (n.contains('internet')) return Icons.wifi;
  if (n.contains('celular')) return Icons.smartphone;
  return Icons.receipt_long_outlined;
}
