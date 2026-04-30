import 'package:flutter/material.dart';
import '../models/room_member.dart';
import '../models/room_role.dart';
import '../../../services/room_service.dart';

class RecipientPickerSheet extends StatelessWidget {
  final String roomId;
  const RecipientPickerSheet({super.key, required this.roomId});

  static Future<RoomMember?> show(BuildContext context, String roomId) {
    return showModalBottomSheet<RoomMember>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: RecipientPickerSheet(roomId: roomId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14092B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          const Text('Send gift to…',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Pick someone in the room',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<RoomMember>>(
              stream: RoomService().watchMembers(roomId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = [...snap.data!]..sort((a, b) {
                    if (a.isPresent != b.isPresent) {
                      return a.isPresent ? -1 : 1;
                    }
                    return b.charms.compareTo(a.charms);
                  });
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No members yet',
                          style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, m),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899)
                                    ]),
                                    image: m.photoUrl != null &&
                                            m.photoUrl!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(m.photoUrl!),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: m.photoUrl == null ||
                                          m.photoUrl!.isEmpty
                                      ? Center(
                                          child: Text(
                                            m.displayName.isNotEmpty
                                                ? m.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        )
                                      : null,
                                ),
                                if (m.isPresent)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color:
                                                const Color(0xFF14092B),
                                            width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(m.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                      if (m.role != RoomRole.member) ...[
                                        const SizedBox(width: 6),
                                        _badge(m.role),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite,
                                          color: Color(0xFFEC4899),
                                          size: 11),
                                      const SizedBox(width: 4),
                                      Text('${m.charms} charms',
                                          style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.card_giftcard,
                                color: Color(0xFFEC4899), size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(RoomRole role) {
    final colors = switch (role) {
      RoomRole.owner => const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      RoomRole.coOwner => const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      RoomRole.admin => const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      _ => const [Color(0xFF6B7280), Color(0xFF4B5563)],
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(role.label.toUpperCase(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}
