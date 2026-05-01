class AppUser {
  final String uid;
  final String displayName;
  final String username;
  final String? photoURL;
  final String? email;
  final String bio;
  final String signature;
  final bool isVerified;

  final int coins;
  final int clanCoins;
  final int charms; // shown as "Guard Points"
  final int level;

  final int friendsCount;
  final int momentsCount;
  final int visitorsCount;
  final int followingCount;

  // Clan
  final String? clanId;
  final String? clanName;
  final String? clanRole;

  // CP partner
  final String? cpPartnerUid;
  final String? cpPartnerName;
  final String? cpRingId;
  final DateTime? cpSince;

  final String? cpPartnerPhoto;
  final String? cpCoupleId;
  final String? cpStatus;
  final DateTime? cpDivorceCooldownUntil;

  // Equipped tags (max 3)
  final List<String> activeTags;

  // Activity (voice/chat room/game)
  final Map<String, dynamic>? activity;

  AppUser({
    required this.uid,
    required this.displayName,
    this.username = '',
    this.photoURL,
    this.email,
    this.bio = '',
    this.signature = '',
    this.isVerified = false,
    this.coins = 0,
    this.clanCoins = 0,
    this.charms = 0,
    this.level = 1,
    this.friendsCount = 0,
    this.momentsCount = 0,
    this.visitorsCount = 0,
    this.followingCount = 0,
    this.clanId,
    this.clanName,
    this.cpPartnerPhoto,
    this.cpCoupleId,
    this.cpStatus,
    this.cpDivorceCooldownUntil,
    this.clanRole,
    this.cpPartnerUid,
    this.cpPartnerName,
    this.cpRingId,
    this.cpSince,
    this.activeTags = const [],
    this.activity,
  });

  /// Accepts either `AppUser.fromMap(map)` (uid inside the map)
  /// or `AppUser.fromMap(map, uid)`.
  factory AppUser.fromMap(Map<String, dynamic> m, [String? uid]) {
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
      uid: uid ?? (m['uid'] as String? ?? ''),
      displayName: (m['displayName'] ?? 'User') as String,
      username: (m['username'] ?? '') as String,
      photoURL: m['photoURL'] as String?,
      email: m['email'] as String?,
      bio: (m['bio'] ?? '') as String,
      signature: (m['signature'] ?? '') as String,
      isVerified: (m['isVerified'] ?? false) as bool,
      coins: (m['coins'] ?? 0) as int,
      clanCoins: (m['clanCoins'] ?? 0) as int,
      charms: (m['charms'] ?? 0) as int,
      level: (m['level'] ?? 1) as int,
      friendsCount: (m['friendsCount'] ?? 0) as int,
      momentsCount: (m['momentsCount'] ?? 0) as int,
      visitorsCount: (m['visitorsCount'] ?? 0) as int,
      followingCount: (m['followingCount'] ?? 0) as int,
      clanId: m['clanId'] as String?,
      clanName: m['clanName'] as String?,
      clanRole: m['clanRole'] as String?,
      cpPartnerUid: m['cpPartnerUid'] as String?,
      cpPartnerName: m['cpPartnerName'] as String?,
      cpRingId: m['cpRingId'] as String?,
      cpSince: _ts(m['cpSince']),
      cpPartnerPhoto: m['cpPartnerPhoto'] as String?,
      cpCoupleId: m['cpCoupleId'] as String?,
      cpStatus: m['cpStatus'] as String?,
      cpDivorceCooldownUntil: _ts(m['cpDivorceCooldownUntil']),
      activeTags: ((m['activeTags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      activity: m['activity'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'username': username,
        'photoURL': photoURL,
        'email': email,
        'bio': bio,
        'signature': signature,
        'isVerified': isVerified,
        'coins': coins,
        'clanCoins': clanCoins,
        'charms': charms,
        'level': level,
        'friendsCount': friendsCount,
        'momentsCount': momentsCount,
        'visitorsCount': visitorsCount,
        'followingCount': followingCount,
        'clanId': clanId,
        'clanName': clanName,
        'clanRole': clanRole,
        'cpPartnerUid': cpPartnerUid,
        'cpPartnerName': cpPartnerName,
        'cpRingId': cpRingId,
        if (cpSince != null) 'cpSince': cpSince,
            'cpPartnerPhoto': cpPartnerPhoto,
        'cpCoupleId': cpCoupleId,
        'cpStatus': cpStatus,
        if (cpDivorceCooldownUntil != null)
       'cpDivorceCooldownUntil': cpDivorceCooldownUntil,
        'activeTags': activeTags,
        'activity': activity,
      };
}
