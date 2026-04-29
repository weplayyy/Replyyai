import 'package:flutter/material.dart';

class Gift {
  final String id;
  final String name;
  final String icon;
  final int price;
  final List<Color> gradient;

  /// Optional fullscreen animation (e.g. mp4 in assets/gifts/...).
  final String? videoAsset;

  const Gift({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.gradient,
    this.videoAsset,
  });
}

const List<Gift> kAllGifts = [
  Gift(id: 'rose', name: 'Rose', icon: '🌹', price: 10,
      gradient: [Color(0xFFEC4899), Color(0xFFF472B6)]),
  Gift(id: 'heart', name: 'Heart', icon: '💖', price: 50,
      gradient: [Color(0xFFEF4444), Color(0xFFF87171)]),
  Gift(id: 'crown', name: 'Crown', icon: '👑', price: 200,
      gradient: [Color(0xFFFBBF24), Color(0xFFFDE047)]),
  Gift(id: 'diamond', name: 'Diamond', icon: '💎', price: 1000,
      gradient: [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
  Gift(id: 'rocket', name: 'Rocket', icon: '🚀', price: 5000,
      gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
  Gift(
    id: 'royal_palace',
    name: 'Royal Palace',
    icon: '🏰',
    price: 50000,
    gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    videoAsset: 'assets/gifts/royal_palace.mp4',
  ),
];
