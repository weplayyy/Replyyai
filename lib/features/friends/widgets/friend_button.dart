import 'package:flutter/material.dart';
import '../models/friendship.dart';
import '../services/friend_service.dart';

/// A self-aware button that renders the correct CTA based on the live
/// friendship status with [otherUid]. Drop it anywhere — profile, chat
/// header, room members tile, search results.
class FriendButton extends StatefulWidget {
  final String otherUid;

  /// Compact mode shrinks padding and uses a pill instead of full button.
  final bool compact;

  const FriendButton({
    super.key,
    required this.otherUid,
    this.compact = false,
  });

  @override
  State<FriendButton> createState() => _FriendButtonState();
}

class _FriendButtonState extends State<FriendButton> {
  final _svc = FriendService();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Friendship?>(
      stream: _svc.watchFriendship(widget.otherUid),
      builder: (context, snap) {
        final f = snap.data;
        if (f == null) {
          return _btn(
            label: 'Add Friend',
            icon: Icons.person_add_alt_1_rounded,
            gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            onTap: () => _run(() => _svc.sendRequest(widget.otherUid)),
          );
        }
        switch (f.status) {
          case FriendStatus.pendingOutgoing:
            return _btn(
              label: 'Request Sent',
              icon: Icons.schedule_rounded,
              outlined: true,
              onTap: () =>
                  _run(() => _svc.declineOrCancel(widget.otherUid)),
            );
          case FriendStatus.pendingIncoming:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _btn(
                  label: 'Accept',
                  icon: Icons.check_rounded,
                  gradient: const [Color(0xFF22C55E), Color(0xFF10B981)],
                  onTap: () =>
                      _run(() => _svc.acceptRequest(widget.otherUid)),
                ),
                const SizedBox(width: 8),
                _btn(
                  label: 'Decline',
                  icon: Icons.close_rounded,
                  outlined: true,
                  onTap: () =>
                      _run(() => _svc.declineOrCancel(widget.otherUid)),
                ),
              ],
            );
          case FriendStatus.accepted:
            return _btn(
              label: 'Friends',
              icon: Icons.check_circle_rounded,
              outlined: true,
              onTap: () => _confirmRemove(),
            );
          case FriendStatus.blocked:
            return _btn(
              label: 'Unblock',
              icon: Icons.block_rounded,
              outlined: true,
              onTap: () => _run(() => _svc.unblock(widget.otherUid)),
            );
        }
      },
    );
  }

  Future<void> _confirmRemove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14092B),
        title: const Text('Remove friend?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You can add them again later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _svc.removeFriend(widget.otherUid));
    }
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    List<Color>? gradient,
    bool outlined = false,
  }) {
    final hPad = widget.compact ? 12.0 : 18.0;
    final vPad = widget.compact ? 7.0 : 11.0;
    final fontSize = widget.compact ? 12.0 : 13.0;
    final iconSize = widget.compact ? 14.0 : 16.0;

    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          gradient: outlined || gradient == null
              ? null
              : LinearGradient(colors: gradient),
          color: outlined ? Colors.white.withOpacity(0.06) : null,
          borderRadius: BorderRadius.circular(22),
          border: outlined
              ? Border.all(color: Colors.white.withOpacity(0.18))
              : null,
          boxShadow: gradient != null && !outlined
              ? [
                  BoxShadow(
                    color: gradient.last.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
