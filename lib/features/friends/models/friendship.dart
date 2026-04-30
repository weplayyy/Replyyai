import 'package:cloud_firestore/cloud_firestore.dart';

/// Friendship state between the current user and another user.
///
/// Stored at `users/{me}/friends/{otherUid}`.
/// The same document is mirrored on the other user's side with the
/// inverse status (e.g. my `pendingOutgoing` == their `pendingIncoming`).
enum FriendStatus {
  pendingOutgoing, // I sent the request, waiting on them.
  pendingIncoming, // They sent the request, waiting on me.
  accepted,        // We are friends.
  blocked,         // I blocked them. They cannot DM or send requests.
}

extension FriendStatusX on FriendStatus {
  String toRaw() => switch (this) {
        FriendStatus.pendingOutgoing => 'pending_outgoing',
        FriendStatus.pendingIncoming => 'pending_incoming',
        FriendStatus.accepted => 'accepted',
        FriendStatus.blocked => 'blocked',
      };

  static FriendStatus fromRaw(String? raw) => switch (raw) {
        'pending_outgoing' => FriendStatus.pendingOutgoing,
        'pending_incoming' => FriendStatus.pendingIncoming,
        'accepted' => FriendStatus.accepted,
        'blocked' => FriendStatus.blocked,
        _ => FriendStatus.pendingOutgoing,
      };
}

class Friendship {
  /// The other user's uid (NOT the current user's).
  final String uid;

  /// Denormalized snapshot of the other user — refreshed on accept and on
  /// any explicit "refresh friends" action. Slightly stale data is OK.
  final String displayName;
  final String? photoUrl;
  final int charms;

  final FriendStatus status;
  final DateTime addedAt;

  const Friendship({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.charms,
    required this.status,
    required this.addedAt,
  });

  factory Friendship.fromMap(String otherUid, Map<String, dynamic> m) {
    DateTime ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return Friendship(
      uid: otherUid,
      displayName: (m['displayName'] ?? 'User') as String,
      photoUrl: m['photoUrl'] as String?,
      charms: (m['charms'] ?? 0) as int,
      status: FriendStatusX.fromRaw(m['status'] as String?),
      addedAt: ts(m['addedAt']),
    );
  }
}
