import 'package:flutter/material.dart';

enum ShopItemType { ring, tag, badge, seat, frame, effect, other }
enum ShopCurrency { coins, clanCoins }
enum ShopCategory { relationship, decorations, voiceRoom, effects, other }

class ShopItem {
  final String id;
  final ShopItemType type;
  final ShopCategory category;
  final String subCategory; // 'wedding_ring', 'couple_badge', 'lover_seat', etc.
  final String name;
  final int price;
  final ShopCurrency currency;
  final String emoji;
  final List<Color> gradient;
  final String? badge; // 'New' | 'Hot' | null
  final String? description;

  const ShopItem({
    required this.id,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.price,
    required this.currency,
    required this.emoji,
    required this.gradient,
    this.badge,
    this.description,
  });
}

// =========================================================================
// CATALOG
// =========================================================================

const List<ShopItem> kAllShopItems = [
  // ----- Relationship: Wedding Ring -----
  ShopItem(
    id: 'ring_starlight',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Starlight Oath',
    price: 12888,
    currency: ShopCurrency.clanCoins,
    emoji: '💍',
    gradient: [Color(0xFFA78BFA), Color(0xFFFBBF24)],
    badge: 'New',
  ),
  ShopItem(
    id: 'ring_hope_arc',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Hope Arc',
    price: 9999,
    currency: ShopCurrency.clanCoins,
    emoji: '🕊️',
    gradient: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
  ),
  ShopItem(
    id: 'ring_eternal_devotion',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Eternal Devotion',
    price: 9999,
    currency: ShopCurrency.clanCoins,
    emoji: '💎',
    gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  ),
  ShopItem(
    id: 'ring_platinum_promise',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Platinum Promise',
    price: 13142,
    currency: ShopCurrency.coins,
    emoji: '💍',
    gradient: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
  ),
  ShopItem(
    id: 'ring_blooming_love',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Blooming Love',
    price: 5200,
    currency: ShopCurrency.coins,
    emoji: '🌸',
    gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
    badge: 'Hot',
  ),
  ShopItem(
    id: 'ring_royal_crown',
    type: ShopItemType.ring,
    category: ShopCategory.relationship,
    subCategory: 'wedding_ring',
    name: 'Royal Crown',
    price: 520920,
    currency: ShopCurrency.coins,
    emoji: '👑',
    gradient: [Color(0xFFA78BFA), Color(0xFFEC4899)],
  ),

  // ----- Relationship: Couple Badge -----
  ShopItem(
    id: 'badge_lovebirds',
    type: ShopItemType.badge,
    category: ShopCategory.relationship,
    subCategory: 'couple_badge',
    name: 'Lovebirds',
    price: 2999,
    currency: ShopCurrency.coins,
    emoji: '💕',
    gradient: [Color(0xFFEC4899), Color(0xFFEF4444)],
  ),
  ShopItem(
    id: 'badge_eternity',
    type: ShopItemType.badge,
    category: ShopCategory.relationship,
    subCategory: 'couple_badge',
    name: 'Eternity Knot',
    price: 7777,
    currency: ShopCurrency.coins,
    emoji: '♾️',
    gradient: [Color(0xFF8B5CF6), Color(0xFF60A5FA)],
  ),

  // ----- Relationship: Lover Seat -----
  ShopItem(
    id: 'seat_moonlight',
    type: ShopItemType.seat,
    category: ShopCategory.relationship,
    subCategory: 'lover_seat',
    name: 'Moonlight Sofa',
    price: 19999,
    currency: ShopCurrency.coins,
    emoji: '🛋️',
    gradient: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
  ),

  // ----- Tags (kept under "other") -----
  ShopItem(
    id: 'tag_living', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Living', price: 199, currency: ShopCurrency.coins,
    emoji: '✨', gradient: [Color(0xFF22D3EE), Color(0xFF60A5FA)]),
  ShopItem(
    id: 'tag_laughing', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Laughing', price: 199, currency: ShopCurrency.coins,
    emoji: '😄', gradient: [Color(0xFFFBBF24), Color(0xFFF472B6)]),
  ShopItem(
    id: 'tag_gaming', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Gaming', price: 299, currency: ShopCurrency.coins,
    emoji: '🎮', gradient: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
  ShopItem(
    id: 'tag_singing', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Singing', price: 299, currency: ShopCurrency.coins,
    emoji: '🎤', gradient: [Color(0xFFEF4444), Color(0xFFF472B6)]),
  ShopItem(
    id: 'tag_dancing', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Dancing', price: 299, currency: ShopCurrency.coins,
    emoji: '💃', gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
  ShopItem(
    id: 'tag_chilling', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Chilling', price: 199, currency: ShopCurrency.coins,
    emoji: '🌴', gradient: [Color(0xFF10B981), Color(0xFF22D3EE)]),
  ShopItem(
    id: 'tag_traveling', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Traveling', price: 399, currency: ShopCurrency.coins,
    emoji: '✈️', gradient: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
  ShopItem(
    id: 'tag_dreaming', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Dreaming', price: 199, currency: ShopCurrency.coins,
    emoji: '💭', gradient: [Color(0xFFA78BFA), Color(0xFF60A5FA)]),
  ShopItem(
    id: 'tag_loving', type: ShopItemType.tag,
    category: ShopCategory.other, subCategory: 'tag',
    name: 'Loving', price: 499, currency: ShopCurrency.coins,
    emoji: '💖', gradient: [Color(0xFFEC4899), Color(0xFFEF4444)]),
];

// Helpers --------------------------------------------------------------

ShopItem? shopItemById(String? id) {
  if (id == null) return null;
  for (final i in kAllShopItems) {
    if (i.id == id) return i;
  }
  return null;
}

List<ShopItem> shopItemsBy({
  ShopCategory? category,
  String? subCategory,
  ShopItemType? type,
}) {
  return kAllShopItems.where((i) {
    if (category != null && i.category != category) return false;
    if (subCategory != null && i.subCategory != subCategory) return false;
    if (type != null && i.type != type) return false;
    return true;
  }).toList();
}

// Back-compat for existing code (cp_propose_sheet, profile, etc.)
List<ShopItem> get kRings =>
    shopItemsBy(type: ShopItemType.ring);
List<ShopItem> get kTags =>
    shopItemsBy(type: ShopItemType.tag);

// Sub-categories shown as chips inside each tab
const Map<ShopCategory, List<String>> kSubCategories = {
  ShopCategory.relationship: ['wedding_ring', 'couple_badge', 'lover_seat'],
  ShopCategory.decorations: ['frame', 'background'],
  ShopCategory.voiceRoom: ['theme', 'entry_effect'],
  ShopCategory.effects: ['gift_effect', 'chat_effect'],
  ShopCategory.other: ['tag'],
};

const Map<String, String> kSubCategoryLabels = {
  'wedding_ring': 'Wedding Ring',
  'couple_badge': 'Couple Badge',
  'lover_seat': 'Lover Seat',
  'frame': 'Frame',
  'background': 'Background',
  'theme': 'Theme',
  'entry_effect': 'Entry Effect',
  'gift_effect': 'Gift Effect',
  'chat_effect': 'Chat Effect',
  'tag': 'Tag',
};

const Map<ShopCategory, String> kCategoryLabels = {
  ShopCategory.relationship: 'Relationship',
  ShopCategory.decorations: 'Decorations',
  ShopCategory.voiceRoom: 'Voice Room',
  ShopCategory.effects: 'Effects',
  ShopCategory.other: 'Other',
};
