import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HEART LEVEL DEFINITIONS
// Each level is earned by accumulating cpGrowthCharms (charms from gifting
// your CP partner). Matches the same pattern as charm_rank.dart.
// ─────────────────────────────────────────────────────────────────────────────

class CpHeartLevel {
  final int level;
  final String name;
  final int minGrowth;   // minimum cpGrowthCharms to reach this level
  final int? nextGrowth; // null = max level
  final List<Color> gradient;
  final Color glowColor;
  final bool hasWings;
  final bool hasHalo;
  final bool hasCrown;

  const CpHeartLevel({
    required this.level,
    required this.name,
    required this.minGrowth,
    required this.nextGrowth,
    required this.gradient,
    required this.glowColor,
    this.hasWings = false,
    this.hasHalo  = false,
    this.hasCrown = false,
  });
}

const List<CpHeartLevel> kCpHeartLevels = [
  // Lv 1 — plain red heart
  CpHeartLevel(
    level:       1,
    name:        'New Love',
    minGrowth:   0,
    nextGrowth:  1000,
    gradient:    [Color(0xFFFF6B6B), Color(0xFFEE0979)],
    glowColor:   Color(0xFFEE0979),
  ),
  // Lv 2 — pink glow
  CpHeartLevel(
    level:       2,
    name:        'Warm Love',
    minGrowth:   1000,
    nextGrowth:  5000,
    gradient:    [Color(0xFFFF9EC4), Color(0xFFEC4899)],
    glowColor:   Color(0xFFEC4899),
  ),
  // Lv 3 — deeper pink pulse
  CpHeartLevel(
    level:       3,
    name:        'Blooming Love',
    minGrowth:   5000,
    nextGrowth:  15000,
    gradient:    [Color(0xFFF472B6), Color(0xFFBE185D)],
    glowColor:   Color(0xFFF472B6),
  ),
  // Lv 4 — purple tint
  CpHeartLevel(
    level:       4,
    name:        'Devoted Love',
    minGrowth:   15000,
    nextGrowth:  40000,
    gradient:    [Color(0xFFC084FC), Color(0xFF7C3AED)],
    glowColor:   Color(0xFFC084FC),
  ),
  // Lv 5 — wings appear
  CpHeartLevel(
    level:       5,
    name:        'Soaring Love',
    minGrowth:   40000,
    nextGrowth:  100000,
    gradient:    [Color(0xFFFCA5A5), Color(0xFFEC4899)],
    glowColor:   Color(0xFFEC4899),
    hasWings:    true,
  ),
  // Lv 6 — full wings, cyan glow
  CpHeartLevel(
    level:       6,
    name:        'Angelic Love',
    minGrowth:   100000,
    nextGrowth:  300000,
    gradient:    [Color(0xFF67E8F9), Color(0xFF06B6D4)],
    glowColor:   Color(0xFF67E8F9),
    hasWings:    true,
  ),
  // Lv 7 — wings + halo
  CpHeartLevel(
    level:       7,
    name:        'Divine Love',
    minGrowth:   300000,
    nextGrowth:  1000000,
    gradient:    [Color(0xFFFDE68A), Color(0xFFF59E0B)],
    glowColor:   Color(0xFFFDE68A),
    hasWings:    true,
    hasHalo:     true,
  ),
  // Lv 8 — golden wings + halo
  CpHeartLevel(
    level:       8,
    name:        'Sacred Love',
    minGrowth:   1000000,
    nextGrowth:  3000000,
    gradient:    [Color(0xFFFFD700), Color(0xFFFF8C00)],
    glowColor:   Color(0xFFFFD700),
    hasWings:    true,
    hasHalo:     true,
  ),
  // Lv 9 — diamond/ice
  CpHeartLevel(
    level:       9,
    name:        'Eternal Love',
    minGrowth:   3000000,
    nextGrowth:  10000000,
    gradient:    [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF7DD3FC)],
    glowColor:   Color(0xFF38BDF8),
    hasWings:    true,
    hasHalo:     true,
  ),
  // Lv 10 — rainbow crown, max level
  CpHeartLevel(
    level:       10,
    name:        'Legendary Love',
    minGrowth:   10000000,
    nextGrowth:  null,
    gradient:    [Color(0xFFFFD700), Color(0xFFFF1493),
                  Color(0xFF00FFFF), Color(0xFFFFD700)],
    glowColor:   Color(0xFFFF1493),
    hasWings:    true,
    hasHalo:     true,
    hasCrown:    true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPER CLASS  — resolved level + progress for a given cpGrowthCharms value
// ─────────────────────────────────────────────────────────────────────────────

class CpHeartRank {
  final CpHeartLevel levelInfo;
  final int growth;            // raw cpGrowthCharms
  final int growthIntoLevel;   // charms since level start
  final int growthForLevel;    // total charms needed to pass this level
  final int growthToNext;      // remaining charms to next level

  const CpHeartRank({
    required this.levelInfo,
    required this.growth,
    required this.growthIntoLevel,
    required this.growthForLevel,
    required this.growthToNext,
  });

  /// Resolve a CpHeartRank from a raw cpGrowthCharms value.
  static CpHeartRank fromGrowth(int growth) {
    final info = kCpHeartLevels.lastWhere(
      (l) => growth >= l.minGrowth,
      orElse: () => kCpHeartLevels.first,
    );
    final upper = info.nextGrowth ?? (info.minGrowth + 1000000000);
    final into  = growth - info.minGrowth;
    final span  = upper - info.minGrowth;
    return CpHeartRank(
      levelInfo:       info,
      growth:          growth,
      growthIntoLevel: into,
      growthForLevel:  span,
      growthToNext:    (span - into).clamp(0, 1 << 31),
    );
  }

  double get progress =>
      growthForLevel == 0 ? 1.0 : (growthIntoLevel / growthForLevel).clamp(0.0, 1.0);

  String get displayName => '${levelInfo.name}  Lv.${levelInfo.level}';
}
