import 'package:flutter/material.dart';
import '../models/charm_rank.dart';
import 'crown_emblem.dart';

class RankBadge extends StatelessWidget {
  final int charms;
  final double scale;
  final bool showName;

  const RankBadge({
    super.key,
    required this.charms,
    this.scale = 1.0,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    final rank = CharmRank.fromCharms(charms);
    if (rank.info.tier == RankTier.none) return const SizedBox.shrink();

    final isElite = rank.info.glyph == RankGlyph.crown;
    final isLegend = rank.info.tier.index >= RankTier.mahaShaktiPoorvaj.index;
    final isShaktiDev = rank.info.tier == RankTier.shaktiDev;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: (isElite ? 10 : 8) * scale,
          vertical: (isElite ? 4 : 3) * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rank.info.gradient,
        ),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: rank.info.glowColor.withOpacity(isElite ? 0.75 : 0.35),
            blurRadius: isLegend ? 22 : (isElite ? 14 : 6),
            spreadRadius: isLegend ? 2 : (isElite ? 1 : 0),
          ),
          if (isLegend)
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 4,
              spreadRadius: -1,
            ),
        ],
        border: Border.all(
          color: isShaktiDev
              ? Colors.white
              : Colors.white.withOpacity(isElite ? 0.85 : 0.7),
          width: (isElite ? 1.0 : 0.8) * scale,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rank.info.glyph == RankGlyph.emoji)
                Text(rank.info.emoji,
                    style: TextStyle(fontSize: 13 * scale)),
              if (rank.info.glyph == RankGlyph.crown)
                CrownEmblem(
                  size: 18 * scale,
                  gradient: rank.info.gradient,
                  glowColor: rank.info.glowColor,
                  gems: rank.info.crownGems,
                ),
              SizedBox(width: 5 * scale),
              Text(
                superscript(rank.stage),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                ),
              ),
              if (showName) ...[
                SizedBox(width: 5 * scale),
                Text(
                  rank.info.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ],
            ],
          ),
          // Sparkles only for legend tiers
          if (isLegend) ...[
            Positioned(
              top: -3 * scale,
              right: 2 * scale,
              child: Icon(Icons.auto_awesome,
                  size: 8 * scale, color: Colors.white),
            ),
            Positioned(
              bottom: -2 * scale,
              left: 4 * scale,
              child: Icon(Icons.auto_awesome,
                  size: 6 * scale, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
