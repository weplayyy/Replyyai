import 'package:flutter/material.dart';

enum RankTier {
  none,
  eklavya,
  daksh,
  dhron,
  shaktiman,
  shaktiSamrat,
  shaktiPoorvaj,
  mahaShaktiPoorvaj,
  ardhVidhvaan,
  vidhvaan,
  shaktiDev,
}

enum RankGlyph { none, emoji, crown }

class RankInfo {
  final RankTier tier;
  final String name;
  final int minCharm;
  final int? nextCharm;
  final int maxStages;
  final RankGlyph glyph;
  final String emoji;
  final int crownGems;
  final List<Color> gradient;
  final Color glowColor;

  const RankInfo({
    required this.tier,
    required this.name,
    required this.minCharm,
    required this.nextCharm,
    required this.maxStages,
    required this.glyph,
    required this.emoji,
    required this.crownGems,
    required this.gradient,
    required this.glowColor,
  });
}

const List<RankInfo> kRanks = [
  RankInfo(
    tier: RankTier.none,
    name: '',
    minCharm: 0,
    nextCharm: 2000,
    maxStages: 0,
    glyph: RankGlyph.none,
    emoji: '',
    crownGems: 0,
    gradient: [Colors.transparent, Colors.transparent],
    glowColor: Colors.transparent,
  ),
  RankInfo(
    tier: RankTier.eklavya,
    name: 'Eklavya',
    minCharm: 2000,
    nextCharm: 40000,
    maxStages: 10,
    glyph: RankGlyph.emoji,
    emoji: '⭐',
    crownGems: 0,
    gradient: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
    glowColor: Color(0xFFFFFFFF),
  ),
  RankInfo(
    tier: RankTier.daksh,
    name: 'Daksh',
    minCharm: 40000,
    nextCharm: 300000,
    maxStages: 10,
    glyph: RankGlyph.emoji,
    emoji: '🌟',
    crownGems: 0,
    gradient: [Color(0xFFFFE082), Color(0xFFFFB300)],
    glowColor: Color(0xFFFFC107),
  ),
  RankInfo(
    tier: RankTier.dhron,
    name: 'Dhron',
    minCharm: 300000,
    nextCharm: 1000000,
    maxStages: 10,
    glyph: RankGlyph.emoji,
    emoji: '💠',
    crownGems: 0,
    gradient: [Color(0xFF93C5FD), Color(0xFF2563EB)],
    glowColor: Color(0xFF60A5FA),
  ),
  RankInfo(
    tier: RankTier.shaktiman,
    name: 'Shaktiman',
    minCharm: 1000000,
    nextCharm: 6000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 3,
    gradient: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    glowColor: Color(0xFFFFD700),
  ),
  RankInfo(
    tier: RankTier.shaktiSamrat,
    name: 'Shakti Samrat',
    minCharm: 6000000,
    nextCharm: 13000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 4,
    gradient: [Color(0xFFFCA5A5), Color(0xFFB91C1C)],
    glowColor: Color(0xFFEF4444),
  ),
  RankInfo(
    tier: RankTier.shaktiPoorvaj,
    name: 'Shakti Poorvaj',
    minCharm: 13000000,
    nextCharm: 30000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 5,
    gradient: [Color(0xFFC4B5FD), Color(0xFF6D28D9)],
    glowColor: Color(0xFFA78BFA),
  ),
  RankInfo(
    tier: RankTier.mahaShaktiPoorvaj,
    name: 'Maha Shakti Poorvaj',
    minCharm: 30000000,
    nextCharm: 80000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 5,
    gradient: [Color(0xFFFBCFE8), Color(0xFF831843)],
    glowColor: Color(0xFFEC4899),
  ),
  RankInfo(
    tier: RankTier.ardhVidhvaan,
    name: 'Ardh Vidhvaan',
    minCharm: 80000000,
    nextCharm: 200000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 6,
    gradient: [Color(0xFF99F6E4), Color(0xFF0E7490)],
    glowColor: Color(0xFF22D3EE),
  ),
  RankInfo(
    tier: RankTier.vidhvaan,
    name: 'Vidhvaan',
    minCharm: 200000000,
    nextCharm: 500000000,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 7,
    gradient: [Color(0xFFFFFFFF), Color(0xFF94A3B8), Color(0xFFFFFFFF)],
    glowColor: Color(0xFFE0F2FE),
  ),
  RankInfo(
    tier: RankTier.shaktiDev,
    name: 'Shakti Dev',
    minCharm: 500000000,
    nextCharm: null,
    maxStages: 10,
    glyph: RankGlyph.crown,
    emoji: '',
    crownGems: 9,
    gradient: [
      Color(0xFFFFD700),
      Color(0xFFFF1493),
      Color(0xFF00FFFF),
      Color(0xFFFFD700),
    ],
    glowColor: Color(0xFFFF1493),
  ),
];

class CharmRank {
  final RankInfo info;
  final int stage;
  final int charms;
  final int charmsIntoStage;
  final int charmsForStage;
  final int charmsToNextStage;

  const CharmRank({
    required this.info,
    required this.stage,
    required this.charms,
    required this.charmsIntoStage,
    required this.charmsForStage,
    required this.charmsToNextStage,
  });

  static CharmRank fromCharms(int charms) {
    if (charms < 2000) {
      return CharmRank(
        info: kRanks.first,
        stage: 0,
        charms: charms,
        charmsIntoStage: charms,
        charmsForStage: 2000,
        charmsToNextStage: 2000 - charms,
      );
    }
    final info = kRanks.lastWhere((r) => charms >= r.minCharm);
    final upper = info.nextCharm ?? (info.minCharm + 1000000000);
    final stageSize = ((upper - info.minCharm) / info.maxStages).round();
    final into = charms - info.minCharm;
    final stage = (into ~/ stageSize).clamp(0, info.maxStages - 1) + 1;
    final stageStart = info.minCharm + (stage - 1) * stageSize;
    return CharmRank(
      info: info,
      stage: stage,
      charms: charms,
      charmsIntoStage: charms - stageStart,
      charmsForStage: stageSize,
      charmsToNextStage: (stageStart + stageSize - charms).clamp(0, 1 << 31),
    );
  }

  String get fullName =>
      info.name.isEmpty ? 'Newcomer' : '${info.name} ${superscript(stage)}';

  double get stageProgress =>
      charmsForStage == 0 ? 0 : (charmsIntoStage / charmsForStage).clamp(0, 1);
}

String superscript(int n) {
  const map = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
    '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
  };
  return n.toString().split('').map((c) => map[c] ?? c).join();
}
