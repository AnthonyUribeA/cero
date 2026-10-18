import 'package:flutter/material.dart';
import 'icons.dart';

const Color kFijo = Color(0xFF4FC3F7);
const Color kVar = Color(0xFFB39DFF);
const Color kHormiga = Color(0xFFF7C948);

IconData catIcon(String c) {
  switch (c) {
    case 'Delivery':
      return Ic.delivery;
    case 'Café':
      return Ic.coffee;
    case 'Snacks':
      return Ic.snack;
    case 'Taxi':
      return Ic.taxi;
    case 'Comida':
      return Ic.food;
    case 'Transporte':
      return Ic.bus;
    case 'Salud':
      return Ic.health;
    default:
      return Ic.other;
  }
}

IconData fixedIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('alquiler')) return Ic.house;
  if (n.contains('luz')) return Ic.bolt;
  if (n.contains('agua')) return Ic.drop;
  if (n.contains('internet')) return Ic.wifi;
  if (n.contains('celular')) return Ic.phone;
  return Ic.receipt;
}
