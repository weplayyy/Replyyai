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

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: rank.info.gradient),
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: [
          BoxShadow(
            color: rank.info.glowColor.withOpacity(isElite ? 0.7 : 0.35),
            blurRadius: isElite ? 14 : 6,
            spreadRadius: isElite ? 1 : 0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 0.8 * scale,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank.info.glyph == RankGlyph.emoji)
            Text(rank.info.emoji,
                style: TextStyle(fontSize: 12 * scale)),
          if (rank.info.glyph == RankGlyph.crown)
            CrownEmblem(
              size: 16 * scale,
              gradient: rank.info.gradient,
              glowColor: rank.info.glowColor,
              gems: rank.info.crownGems,
            ),
          SizedBox(width: 4 * scale),
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
                fontSize: 11 * scale,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
