import 'package:flutter/material.dart';
import 'floating_room_bubble.dart';

/// Wraps any screen and overlays the floating room bubble on top.
/// Applied via MaterialApp's `builder` so the bubble persists across all
/// navigation, not just the home tab.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: FloatingRoomBubble(),
          ),
        ),
      ],
    );
  }
}
