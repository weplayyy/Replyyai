class AppUser {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? email;
  final String? bio;
  final String? signature;

  final int coins;
  final int clanCoins;
  final int charms; // displayed as "Guard Points"
  final int level;

  // Clan
  final String? clanId;
  final String? clanName;
  final String? clanRole;

  // CP partner
  final String? cpPartnerUid;
  final String? cpPartnerName;
  final String? cpRingId;
  final DateTime? cpSince;

  // Tags equipped on the profile (max 3)
  final List<String> activeTags;

  // Activity (voice room / chat room / game)
  final Map<String, dynamic>? activity;

  AppUser({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.email,
    this.bio,
    this.signature,
    this.coins = 0,
    this.clanCoins = 0,
    this.charms = 0,
    this.level = 1,
    this.clanId,
    this.clanName,
    this.clanRole,
    this.cpPartnerUid,
    this.cpPartnerName,
    this.cpRingId,
    this.cpSince,
    this.activeTags = const [],
    this.activity,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    DateTime? _ts(dynamic v) {
      if (v == null) return null;
      try {
        // ignore: avoid_dynamic_calls
        return v.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return AppUser(
      uid: uid,
      displayName: (m['displayName'] ?? 'User') as String,
      photoURL: m['photoURL'] as String?,
      email: m['email'] as String?,
      bio: m['bio'] as String?,
      signature: m['signature'] as String?,
      coins: (m['coins'] ?? 0) as int,
      clanCoins: (m['clanCoins'] ?? 0) as int,
      charms: (m['charms'] ?? 0) as int,
      level: (m['level'] ?? 1) as int,
      clanId: m['clanId'] as String?,
      clanName: m['clanName'] as String?,
      clanRole: m['clanRole'] as String?,
      cpPartnerUid: m['cpPartnerUid'] as String?,
      cpPartnerName: m['cpPartnerName'] as String?,
      cpRingId: m['cpRingId'] as String?,
      cpSince: _ts(m['cpSince']),
      activeTags: ((m['activeTags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      activity: m['activity'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoURL': photoURL,
        'email': email,
        'bio': bio,
        'signature': signature,
        'coins': coins,
        'clanCoins': clanCoins,
        'charms': charms,
        'level': level,
        'clanId': clanId,
        'clanName': clanName,
        'clanRole': clanRole,
        'cpPartnerUid': cpPartnerUid,
        'cpPartnerName': cpPartnerName,
        'cpRingId': cpRingId,
        if (cpSince != null) 'cpSince': cpSince,
        'activeTags': activeTags,
        'activity': activity,
      };
}
