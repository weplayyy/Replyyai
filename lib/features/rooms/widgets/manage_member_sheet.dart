import 'package:flutter/material.dart';
import '../../../models/room.dart';
import '../../../services/room_service.dart';
import '../models/room_member.dart';
import '../models/room_role.dart';

/// Long-press / trailing-menu sheet shown to moderators on another member.
/// Enforces the charm rule: you cannot act on a target with strictly higher charms.
class ManageMemberSheet extends StatelessWidget {
  final Room room;
  final RoomMember me;
  final RoomMember target;
  final RoomService svc;

  const ManageMemberSheet({
    super.key,
    required this.room,
    required this.me,
    required this.target,
    required this.svc,
  });

  static Future<void> show({
    required BuildContext context,
    required Room room,
    required RoomMember me,
    required RoomMember target,
    required RoomService svc,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14092B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ManageMemberSheet(
        room: room, me: me, target: target, svc: svc,
      ),
    );
  }

  bool get _outranksByCharms => me.charms > target.charms;
  bool get _iCanModerate => me.role.canModerate;
  bool get _iAmOwner => me.role == RoomRole.owner;
  bool get _targetIsOwner => target.role == RoomRole.owner;

  /// Final gate: owner cannot be touched, you must outrank by charms,
  /// and you must have moderator role.
  bool get _canActOnTarget =>
      _iCanModerate && !_targetIsOwner && _outranksByCharms;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1F0B3F),
              backgroundImage: (target.photoUrl != null &&
                      target.photoUrl!.isNotEmpty)
                  ? NetworkImage(target.photoUrl!)
                  : null,
              child: (target.photoUrl == null || target.photoUrl!.isEmpty)
                  ? Text(target.displayName.isNotEmpty
                      ? target.displayName[0].toUpperCase()
                      : '?',
                      style: const TextStyle(color: Colors.white))
                  : null,
            ),
            title: Text(target.displayName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${target.role.label} • ${target.charms} charms',
                style: const TextStyle(color: Colors.white54)),
          ),
          const Divider(color: Colors.white12, height: 1),

          if (!_canActOnTarget)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _targetIsOwner
                    ? 'You cannot moderate the room owner.'
                    : !_iCanModerate
                        ? 'Only owner / co-owner / admin can moderate.'
                        : 'You need more charms than this user to moderate them.',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Owner-only role management
            if (_iAmOwner && target.role != RoomRole.coOwner)
              ListTile(
                leading: const Icon(Icons.workspace_premium,
                    color: Color(0xFFEC4899)),
                title: const Text('Make Co-Owner',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _do(context, () async {
                  await svc.setMemberRole(
                      room.id, target.uid, RoomRole.coOwner);
                }, 'Promoted to Co-Owner'),
              ),
            if (_iAmOwner && target.role != RoomRole.admin)
              ListTile(
                leading: const Icon(Icons.shield, color: Color(0xFF8B5CF6)),
                title: const Text('Make Admin',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _do(context, () async {
                  await svc.setMemberRole(
                      room.id, target.uid, RoomRole.admin);
                }, 'Promoted to Admin'),
              ),
            if (_iAmOwner &&
                (target.role == RoomRole.admin ||
                    target.role == RoomRole.coOwner))
              ListTile(
                leading: const Icon(Icons.remove_moderator,
                    color: Colors.white70),
                title: const Text('Demote to Member',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _do(context, () async {
                  await svc.setMemberRole(
                      room.id, target.uid, RoomRole.member);
                }, 'Demoted'),
              ),

            // Mute options (any moderator)
            if (!target.isMuted)
              ListTile(
                leading: const Icon(Icons.volume_off, color: Colors.amber),
                title: const Text('Mute for 10 min',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _do(context, () async {
                  await svc.muteMember(
                      room.id, target.uid,
                      const Duration(minutes: 10));
                }, 'Muted for 10 min'),
              )
            else
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.amber),
                title: const Text('Unmute',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _do(context, () async {
                  await svc.unmuteMember(room.id, target.uid);
                }, 'Unmuted'),
              ),

            // Kick (any moderator)
            ListTile(
              leading:
                  const Icon(Icons.person_remove, color: Color(0xFFEF4444)),
              title: const Text('Kick from room',
                  style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () => _do(context, () async {
                await svc.kickMember(room.id, target.uid);
              }, 'Kicked'),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _do(BuildContext ctx, Future<void> Function() action,
      String okMsg) async {
    Navigator.pop(ctx);
    try {
      await action();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(okMsg)));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
