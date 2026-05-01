import 'package:flutter/material.dart';
import '../models/cp_heart_rank.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CpHeartBadge
//
// Usage:
//   CpHeartBadge(growth: couple['cpGrowthCharms'] ?? 0)          // normal
//   CpHeartBadge(growth: 40000, size: 18)                        // small (chat)
//   CpHeartBadge(growth: 100000, size: 48, showLabel: true)      // large (profile)
// ─────────────────────────────────────────────────────────────────────────────

class CpHeartBadge extends StatelessWidget {
  final int growth;
  final double size;
  final bool showLabel;   // show level name below the heart
  final bool showGlow;    // glow effect (off for tiny sizes)

  const CpHeartBadge({
    super.key,
    required this.growth,
    this.size       = 24,
    this.showLabel  = false,
    this.showGlow   = true,
  });

  @override
  Widget build(BuildContext context) {
    final rank = CpHeartRank.fromGrowth(growth);
    final info = rank.levelInfo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeartStack(info: info, size: size, showGlow: showGlow),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            info.name,
            style: TextStyle(
              color: info.glowColor,
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Lv.${info.level}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: size * 0.22,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: stacks heart + wings + halo + crown
// ─────────────────────────────────────────────────────────────────────────────

class _HeartStack extends StatelessWidget {
  final CpHeartLevel info;
  final double size;
  final bool showGlow;

  const _HeartStack({
    required this.info,
    required this.size,
    required this.showGlow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size * (info.hasWings ? 2.2 : 1.4),
      height: size * (info.hasHalo  ? 1.6 : 1.4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Glow behind everything ──
          if (showGlow)
            Container(
              width:  size * 1.1,
              height: size * 1.1,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:       info.glowColor.withOpacity(0.5),
                    blurRadius:  size * 0.7,
                    spreadRadius: size * 0.1,
                  ),
                ],
              ),
            ),

          // ── Wings (behind heart) ──
          if (info.hasWings)
            Positioned(
              top: size * (info.hasHalo ? 0.4 : 0.1),
              child: _WingsWidget(size: size, color: info.glowColor),
            ),

          // ── Heart (on top of wings) ──
          Positioned(
            top: info.hasHalo ? size * 0.3 : 0,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: info.gradient,
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(
                Icons.favorite,
                size:  size,
                color: Colors.white, // masked by gradient
              ),
            ),
          ),

          // ── Halo (above heart) ──
          if (info.hasHalo)
            Positioned(
              top: 0,
              child: _HaloWidget(size: size, color: info.glowColor),
            ),

          // ── Crown (top-most, level 10 only) ──
          if (info.hasCrown)
            Positioned(
              top: 0,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF1493)],
                ).createShader(bounds),
                child: Icon(
                  Icons.workspace_premium,
                  size:  size * 0.5,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wings
// ─────────────────────────────────────────────────────────────────────────────

class _WingsWidget extends StatelessWidget {
  final double size;
  final Color color;
  const _WingsWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left wing (mirrored)
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: _Wing(size: size, color: color),
        ),
        SizedBox(width: size * 0.6), // gap for heart
        // Right wing
        _Wing(size: size, color: color),
      ],
    );
  }
}

class _Wing extends StatelessWidget {
  final double size;
  final Color color;
  const _Wing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.7, size * 0.7),
      painter: _WingPainter(color: color),
    );
  }
}

class _WingPainter extends CustomPainter {
  final Color color;
  _WingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.9), color.withOpacity(0.2)],
        begin:  Alignment.centerLeft,
        end:    Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, size.height * 0.5)
      ..cubicTo(
        size.width * 0.6, size.height * 0.0,
        size.width * 0.0, size.height * 0.1,
        size.width * 0.0, size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.0, size.height * 0.7,
        size.width * 0.5, size.height * 0.9,
        size.width,       size.height * 0.5,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Wing feather line
    final linePaint = Paint()
      ..color       = color.withOpacity(0.4)
      ..strokeWidth = 0.8
      ..style       = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.9, size.height * 0.5)
        ..cubicTo(
          size.width * 0.5, size.height * 0.2,
          size.width * 0.1, size.height * 0.3,
          size.width * 0.05, size.height * 0.45,
        ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Halo
// ─────────────────────────────────────────────────────────────────────────────

class _HaloWidget extends StatelessWidget {
  final double size;
  final Color color;
  const _HaloWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size * 0.7,
      height: size * 0.18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: color.withOpacity(0.85),
          width: size * 0.06,
        ),
        boxShadow: [
          BoxShadow(
            color:      color.withOpacity(0.5),
            blurRadius: size * 0.25,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CpGrowthBar  — progress bar showing growth within current level
// Use this on couple profile screen below the heart badge
//
// Usage:
//   CpGrowthBar(growth: couple['cpGrowthCharms'] ?? 0)
// ─────────────────────────────────────────────────────────────────────────────

class CpGrowthBar extends StatelessWidget {
  final int growth;
  const CpGrowthBar({super.key, required this.growth});

  @override
  Widget build(BuildContext context) {
    final rank  = CpHeartRank.fromGrowth(growth);
    final info  = rank.levelInfo;
    final prog  = rank.progress;
    final isMax = info.nextGrowth == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              info.name,
              style: TextStyle(
                color:      info.glowColor,
                fontSize:   12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isMax
                  ? 'MAX'
                  : '${_fmt(rank.growthIntoLevel)} / ${_fmt(rank.growthForLevel)}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value:           isMax ? 1.0 : prog,
            minHeight:       7,
            backgroundColor: Colors.white12,
            valueColor:      AlwaysStoppedAnimation<Color>(info.glowColor),
          ),
        ),
        const SizedBox(height: 4),
        if (!isMax)
          Text(
            '${_fmt(rank.growthToNext)} growth to Lv.${info.level + 1}',
            style:
                const TextStyle(color: Colors.white38, fontSize: 10),
          ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
