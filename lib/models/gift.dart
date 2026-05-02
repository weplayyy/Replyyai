import 'package:flutter/material.dart';

class Gift {
  final String id;
  final String name;
  final String icon;
  final int price;
  final List<Color> gradient;
  final String? imageAsset;
  final String? videoAsset;
  final String? badge;
  final String description;         // ← ADD THIS

  const Gift({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.gradient,
    this.imageAsset,
    this.videoAsset,
    this.badge,
    this.description = 'A special gift just for you 💜',   // ← ADD THIS
  });
}

const List<Gift> kAllGifts = [
  Gift(
    id: 'galaxy_heart', name: 'Galaxy Heart', icon: '💜', price: 9999,
    gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    badge: 'Popular',
    description: 'A heart from another galaxy, just for you 🌌',
  ),
  Gift(
    id: 'starship', name: 'Starship', icon: '🚀', price: 8888,
    gradient: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
    badge: 'New',
    description: 'To infinity and beyond, with you 🚀',
  ),
  Gift(
    id: 'crystal_castle', name: 'Crystal Castle', icon: '🏰', price: 6666,
    gradient: [Color(0xFF22D3EE), Color(0xFF60A5FA)],
    description: 'A crystal castle built just for you 💎',
  ),
  Gift(
    id: 'dream_villa', name: 'Dream Villa', icon: '🏡', price: 5555,
    gradient: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
    description: 'Your dream home, wherever you are 🏡',
  ),
  Gift(
    id: 'forever_rose', name: 'Forever Rose', icon: '🌹', price: 2999,
    gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
    description: 'A rose that never wilts, like my feelings 🌹',
  ),
  Gift(
    id: 'love_wings', name: 'Love Wings', icon: '💖', price: 1999,
    gradient: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
    description: 'Wings to fly you straight to my heart 💖',
  ),
  Gift(
    id: 'fireworks', name: 'Fireworks Show', icon: '🎆', price: 1299,
    gradient: [Color(0xFFFBBF24), Color(0xFFEC4899)],
    description: 'You light up the sky like fireworks 🎆',
  ),
  Gift(
    id: 'vidvan', name: 'Vidhvan', icon: '☄️', price: 177799,
    gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    imageAsset: 'assets/gifts/vidvan.png',
    videoAsset: 'assets/gifts/vidvan.mp4',
    description: 'The rarest gift for the rarest person ☄️',
  ),
  Gift(
    id: 'heaven_palace', name: 'Heaven Palace', icon: '🏰', price: 500000,
    gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    imageAsset: 'assets/gifts/heaven_palace.png',
    videoAsset: 'assets/gifts/heaven_palace.mp4',
    description: 'A palace in heaven, fit for royalty 👑',
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
