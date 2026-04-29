import 'package:flutter/material.dart';

class Gift {
  final String id;
  final String name;
  final String icon;
  final int price;
  final List<Color> gradient;

  /// Optional PNG with transparent bg. e.g. 'assets/gifts/rose.png'
  final String? imageAsset;

  /// Optional fullscreen mp4. e.g. 'assets/gifts/royal_palace.mp4'
  final String? videoAsset;

  /// Optional corner badge: 'Popular', 'New', 'Hot', etc.
  final String? badge;

  const Gift({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.gradient,
    this.imageAsset,
    this.videoAsset,
    this.badge,
  });
}

const List<Gift> kAllGifts = [
  // Add your real gifts here. Examples below — replace freely.
  Gift(
    id: 'galaxy_heart', name: 'Galaxy Heart', icon: '💜', price: 9999,
    gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    badge: 'Popular',
  ),
  Gift(
    id: 'starship', name: 'Starship', icon: '🚀', price: 8888,
    gradient: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
    badge: 'New',
  ),
  Gift(
    id: 'crystal_castle', name: 'Crystal Castle', icon: '🏰', price: 6666,
    gradient: [Color(0xFF22D3EE), Color(0xFF60A5FA)],
  ),
  Gift(
    id: 'dream_villa', name: 'Dream Villa', icon: '🏡', price: 5555,
    gradient: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
  ),
  Gift(
    id: 'forever_rose', name: 'Forever Rose', icon: '🌹', price: 2999,
    gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
  ),
  Gift(
    id: 'love_wings', name: 'Love Wings', icon: '💖', price: 1999,
    gradient: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
  ),
  Gift(
    id: 'fireworks', name: 'Fireworks Show', icon: '🎆', price: 1299,
    gradient: [Color(0xFFFBBF24), Color(0xFFEC4899)],
  ),
  Gift(
    id: 'lucky_cat', name: 'Lucky Cat', icon: '🐱', price: 799,
    gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  ),
  Gift(
    id: 'royal_palace', name: 'Royal Palace', icon: '🏰', price: 50000,
    gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    imageAsset: 'assets/gifts/royal_palace.png',
    videoAsset: 'assets/gifts/royal_palace.mp4',
  ),
];

Gift? giftById(String? id) {
  if (id == null) return null;
  for (final g in kAllGifts) {
    if (g.id == id) return g;
  }
  return null;
}

class GiftIcon extends StatelessWidget {
  final Gift? gift;
  final String? id;
  final String? fallbackEmoji;
  final double size;

  const GiftIcon({
    super.key,
    this.gift,
    this.id,
    this.fallbackEmoji,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final g = gift ?? giftById(id);
    final img = g?.imageAsset;
    if (img != null && img.isNotEmpty) {
      return Image.asset(
        img,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Text(g?.icon ?? fallbackEmoji ?? '🎁', style: TextStyle(fontSize: size * 0.85)),
      );
    }
    return Text(
      g?.icon ?? fallbackEmoji ?? '🎁',
      style: TextStyle(fontSize: size * 0.85),
    );
  }
}
