import 'package:flutter/material.dart';
import '../services/active_room_service.dart';
import '../data/room_presets.dart';
import '../screens/room_screen.dart';

/// Draggable circular PFP overlay for the currently-minimized room.
/// Tap → reopen room screen. Long-press → confirm exit.
class FloatingRoomBubble extends StatefulWidget {
  const FloatingRoomBubble({super.key});

  @override
  State<FloatingRoomBubble> createState() => _FloatingRoomBubbleState();
}

class _FloatingRoomBubbleState extends State<FloatingRoomBubble>
    with SingleTickerProviderStateMixin {
  Offset _pos = const Offset(20, 220);
  bool _hasInitialPos = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    ActiveRoomService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    ActiveRoomService.instance.removeListener(_onChange);
    _pulse.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _initPos(Size screen) {
    if (_hasInitialPos) return;
    _pos = Offset(screen.width - 80, screen.height * 0.35);
    _hasInitialPos = true;
  }

  Future<void> _open(BuildContext context) async {
    final r = ActiveRoomService.instance.room;
    if (r == null) return;
    await ActiveRoomService.instance.resume();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomScreen(room: r)),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final r = ActiveRoomService.instance.room;
    if (r == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14092B),
        title: const Text('Exit room?',
            style: TextStyle(color: Colors.white)),
        content: Text('You will leave "${r.name}" completely.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit',
                style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ActiveRoomService.instance.exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ActiveRoomService.instance.showBubble) {
      return const SizedBox.shrink();
    }
    final r = ActiveRoomService.instance.room!;
    final size = MediaQuery.of(context).size;
    _initPos(size);

    final photo = r.photoUrl ?? RoomPresets.firstFor(r.category);

    return Positioned(
      left: _pos.dx,
      top: _pos.dy,
      child: GestureDetector(
        onTap: () => _open(context),
        onLongPress: () => _confirmExit(context),
        onPanUpdate: (d) => setState(() {
          final nx = (_pos.dx + d.delta.dx).clamp(8.0, size.width - 72);
          final ny = (_pos.dy + d.delta.dy).clamp(40.0, size.height - 100);
          _pos = Offset(nx, ny);
        }),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final glow = 0.35 + 0.25 * _pulse.value;
            return Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEC4899).withOpacity(glow + 0.2),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(glow),
                    blurRadius: 18 + 6 * _pulse.value,
                    spreadRadius: 1,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                image: DecorationImage(
                  image: AssetImage(photo),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0A1F),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white24, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.chat_bubble,
                          color: Colors.white, size: 9),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
