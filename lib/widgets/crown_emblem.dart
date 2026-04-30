import 'package:flutter/material.dart';

class CrownEmblem extends StatelessWidget {
  final double size;
  final List<Color> gradient;
  final Color glowColor;
  final int gems;

  const CrownEmblem({
    super.key,
    required this.size,
    required this.gradient,
    required this.glowColor,
    this.gems = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrownPainter(
          gradient: gradient,
          glowColor: glowColor,
          gems: gems,
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final List<Color> gradient;
  final Color glowColor;
  final int gems;

  _CrownPainter({
    required this.gradient,
    required this.glowColor,
    required this.gems,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Path();
    final n = gems.clamp(3, 9);
    final stepX = w * 0.84 / (n - 1);
    final startX = w * 0.08;
    final topY = h * 0.18;
    final dipY = h * 0.55;
    final bottomY = h * 0.78;

    body.moveTo(startX, bottomY);
    for (int i = 0; i < n; i++) {
      final px = startX + i * stepX;
      body.lineTo(px, topY);
      if (i < n - 1) body.lineTo(px + stepX / 2, dipY);
    }
    body.lineTo(startX + (n - 1) * stepX, bottomY);
    body.close();

    canvas.drawPath(
      body,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = glowColor.withOpacity(0.65),
    );

    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..color = Colors.white.withOpacity(0.9),
    );

    final band = Rect.fromLTWH(startX, bottomY, (n - 1) * stepX, h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(w * 0.05)),
      Paint()
        ..shader = LinearGradient(
          colors: [gradient.last, gradient.first],
        ).createShader(band),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(w * 0.05)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..color = Colors.white.withOpacity(0.9),
    );

    for (int i = 0; i < n; i++) {
      final cx = startX + i * stepX;
      final cy = topY + h * 0.04;
      canvas.drawCircle(Offset(cx, cy), w * 0.07,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, cy), w * 0.05,
          Paint()..color = glowColor);
    }

    canvas.drawCircle(
      Offset(w * 0.5, bottomY + h * 0.06),
      w * 0.06,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.5, bottomY + h * 0.06),
      w * 0.04,
      Paint()..color = glowColor,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) =>
      old.gradient != gradient ||
      old.glowColor != glowColor ||
      old.gems != gems;
}
