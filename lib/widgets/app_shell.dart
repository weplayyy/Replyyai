import 'package:flutter/material.dart';
import 'floating_room_bubble.dart';

/// Wraps any screen and overlays the floating room bubble on top.
/// Applied via MaterialApp's `builder` so the bubble persists across
/// every navigation, not just the home tab.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const FloatingRoomBubble(),
      ],
    );
  }
}
