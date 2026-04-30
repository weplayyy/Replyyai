import 'package:flutter/material.dart';
import '../models/charm_rank.dart';
import 'crown_emblem.dart';

class RankAvatarFrame extends StatelessWidget {
  final int charms;
  final double size;
  final Widget child;
  final bool showCrown;

  const RankAvatarFrame({
    super.key,
    required this.charms,
    required this.size,
    required this.child,
    this.showCrown = true,
  });

  @override
  Widget build(BuildContext context) {
    final rank = CharmRank.fromCharms(charms);
    final info = rank.info;

    if (info.tier == RankTier.none) {
      return SizedBox(width: size, height: size, child: ClipOval(child: child));
    }

    final isElite = info.glyph == RankGlyph.crown;
    final isLegend = info.tier.index >= RankTier.mahaShaktiPoorvaj.index;
    final ringWidth = isElite ? 3.5 : 2.5;

    return SizedBox(
      width: size + (isElite ? 16 : 8),
      height: size + (isElite ? 22 : 10),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isLegend)
            Container(
              width: size + 14,
              height: size + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: info.glowColor.withOpacity(0.7),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          Container(
            width: size + 8,
            height: size + 8,
            padding: EdgeInsets.all(ringWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  ...info.gradient,
                  info.gradient.first,
                ],
              ),
              boxShadow: isElite
                  ? [
                      BoxShadow(
                        color: info.glowColor.withOpacity(0.6),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A0B2E),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(child: child),
            ),
          ),
          if (isElite && showCrown)
            Positioned(
              top: -2,
              child: Transform.rotate(
                angle: -0.05,
                child: CrownEmblem(
                  size: size * 0.34,
                  gradient: info.gradient,
                  glowColor: info.glowColor,
                  gems: info.crownGems,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
