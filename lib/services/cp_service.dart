import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_service.dart';

/// All states a couple relationship can be in.
enum CpStatus { engaged, married, conflict, divorced }

extension CpStatusX on CpStatus {
  String toRaw() => switch (this) {
    CpStatus.engaged   => 'engaged',
    CpStatus.married   => 'married',
    CpStatus.conflict  => 'conflict',
    CpStatus.divorced  => 'divorced',
  };
  static CpStatus fromRaw(String? s) => switch (s) {
    'married'  => CpStatus.married,
    'conflict' => CpStatus.conflict,
    'divorced' => CpStatus.divorced,
    _          => CpStatus.engaged,
  };
}

/// Thrown when either user is already in a CP.
class AlreadyInCpException implements Exception {
  final String message;
  AlreadyInCpException(this.message);
  @override String toString() => message;
}

/// Thrown when a divorce cooldown is still active.
class DivorceColdownException implements Exception {
  final DateTime unlockAt;
  DivorceColdownException(this.unlockAt);
  @override String toString() =>
      'You cannot enter a CP yet. Cooldown ends on '
      '${unlockAt.toLocal().toString().substring(0, 10)}.';
}

class CpService {
  final FirebaseFirestore _db;
  CpService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _couples => _db.collection('couples');

  /// Write a notification doc to a user's subcollection.
  Future<void> _notify({
    required String toUid,
    required String type,
    required String title,
    required String body,
    String? fromUid,
    String? fromName,
    String? fromPhoto,
    String? coupleId,
  }) async {
    await _users.doc(toUid).collection('notifications').add({
      'type': type,
      'title': title,
      'body': body,
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhoto': fromPhoto,
      'coupleId': coupleId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete all pending CP proposals for a user (incoming).
  Future<void> _clearAllIncomingProposals(
    WriteBatch batch,
    String uid,
  ) async {
    final proposals = await _users.doc(uid).collection('cp_proposals').get();
    for (final doc in proposals.docs) {
      batch.delete(doc.reference);
    }
  }

  // ─── PROPOSE ────────────────────────────────────────────────────────────────

  /// Send a CP proposal. Validates:
  ///   • Not proposing to self
  ///   • Sender is not already in a CP
  ///   • Receiver is not already in a CP
  ///   • Sender is not in a divorce cooldown
  ///   • Sender owns the ring
  ///   • Sender has not already sent a proposal to this person
  Future<void> proposeCp({
    required String fromUid,
    required String toUid,
    required String ringId,
    String? message,
  }) async {
    // ① Self-proposal guard
    if (fromUid == toUid) {
      throw Exception("You can't propose to yourself 😅");
    }

    final meSnap   = await _users.doc(fromUid).get();
    final themSnap = await _users.doc(toUid).get();
    final me    = meSnap.data() ?? {};
    final them  = themSnap.data() ?? {};

    // ② Already in a CP guard — sender
    if (me['cpPartnerUid'] != null && (me['cpPartnerUid'] as String).isNotEmpty) {
      throw AlreadyInCpException(
          "You're already in a CP. Break up first before proposing.");
    }

    // ③ Divorce cooldown guard — sender
    final cooldown = me['cpDivorceCooldownUntil'];
    if (cooldown is Timestamp && cooldown.toDate().isAfter(DateTime.now())) {
      throw DivorceColdownException(cooldown.toDate());
    }

    // ④ Already in a CP guard — receiver
    if (them['cpPartnerUid'] != null && (them['cpPartnerUid'] as String).isNotEmpty) {
      throw AlreadyInCpException("${them['displayName'] ?? 'This user'} is already in a CP.");
    }

    // ⑤ Ring ownership guard
    final inv = await _users.doc(fromUid).collection('inventory').doc(ringId).get();
    if (!inv.exists || ((inv.data()?['quantity'] ?? 0) as int) < 1) {
      throw Exception("You don't own this ring");
    }

    // ⑥ Duplicate proposal guard
    final existing = await _users
        .doc(toUid)
        .collection('cp_proposals')
        .doc(fromUid)
        .get();
    if (existing.exists) {
      throw Exception("You've already sent a proposal to this person");
    }

    // ⑦ Write the proposal + mark sender's outgoing
    final batch = _db.batch();

    batch.set(
      _users.doc(toUid).collection('cp_proposals').doc(fromUid),
      {
        'fromUid':   fromUid,
        'fromName':  me['displayName'] ?? 'User',
        'fromPhoto': me['photoURL'],
        'ringId':    ringId,
        'message':   message,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // Track outgoing so sender can see/cancel it
    batch.update(_users.doc(fromUid), {
      'cpSentProposalTo': toUid,
      'cpSentProposalToName': them['displayName'] ?? 'User',
      'cpSentProposalToPhoto': them['photoURL'],
      'cpSentProposalAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Notify receiver (outside batch is fine — notification loss is acceptable)
    await _notify(
      toUid:     toUid,
      type:      'cp_proposal',
      title:     '💍 New CP Proposal!',
      body:      '${me['displayName'] ?? 'Someone'} wants to be your CP partner!',
      fromUid:   fromUid,
      fromName:  me['displayName'] as String?,
      fromPhoto: me['photoURL'] as String?,
    );
  }

  // ─── CANCEL OUTGOING PROPOSAL ───────────────────────────────────────────────

  Future<void> cancelProposal({
    required String fromUid,
    required String toUid,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _users.doc(toUid).collection('cp_proposals').doc(fromUid),
    );

    batch.update(_users.doc(fromUid), {
      'cpSentProposalTo':      FieldValue.delete(),
      'cpSentProposalToName':  FieldValue.delete(),
      'cpSentProposalToPhoto': FieldValue.delete(),
      'cpSentProposalAt':      FieldValue.delete(),
    });

    await batch.commit();
  }

  // ─── DECLINE ────────────────────────────────────────────────────────────────

  Future<void> declineProposal({
    required String myUid,
    required String fromUid,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _users.doc(myUid).collection('cp_proposals').doc(fromUid),
    );

    // Clear sender's outgoing marker
    batch.update(_users.doc(fromUid), {
      'cpSentProposalTo':      FieldValue.delete(),
      'cpSentProposalToName':  FieldValue.delete(),
      'cpSentProposalToPhoto': FieldValue.delete(),
      'cpSentProposalAt':      FieldValue.delete(),
    });

    await batch.commit();
  }

  // ─── ACCEPT ─────────────────────────────────────────────────────────────────

  /// Fully atomic acceptance:
  ///  1. Reads proposal + both user docs + inventory in a transaction
  ///  2. Validates sender still owns the ring
  ///  3. Deducts ring in the SAME transaction
  ///  4. Creates /couples doc
  ///  5. Updates both user docs
  ///  6. Deletes ALL pending proposals for both users
  ///  7. Sends acceptance notification
  Future<void> acceptProposal({
    required String myUid,
    required String fromUid,
  }) async {
    final propRef   = _users.doc(myUid).collection('cp_proposals').doc(fromUid);
    final meRef     = _users.doc(myUid);
    final themRef   = _users.doc(fromUid);
    final coupleRef = _couples.doc();               // pre-generate couple ID

    // Use a transaction so ring deduction + CP creation is fully atomic.
    late String ringId;
    late Map<String, dynamic> meData;
    late Map<String, dynamic> themData;

    await _db.runTransaction((tx) async {
      final propSnap = await tx.get(propRef);
      if (!propSnap.exists) throw Exception('Proposal no longer exists');

      final meSnap   = await tx.get(meRef);
      final themSnap = await tx.get(themRef);
      meData   = meSnap.data() ?? {};
      themData = themSnap.data() ?? {};

      // Guard: neither user has been partnered since the proposal was sent
      if ((meData['cpPartnerUid'] as String?)?.isNotEmpty == true) {
        throw AlreadyInCpException("You're already in a CP.");
      }
      if ((themData['cpPartnerUid'] as String?)?.isNotEmpty == true) {
        throw AlreadyInCpException("${themData['displayName']} is already in a CP.");
      }

      ringId = propSnap.data()!['ringId'] as String;

      final invRef  = _users.doc(fromUid).collection('inventory').doc(ringId);
      final invSnap = await tx.get(invRef);
      final qty     = (invSnap.data()?['quantity'] ?? 0) as int;
      if (qty < 1) throw Exception("The sender no longer owns this ring");

      // ① Deduct ring (atomic with everything else)
      if (qty == 1) {
        tx.delete(invRef);
      } else {
        tx.update(invRef, {'quantity': qty - 1});
      }

      // ② Create couple doc
      tx.set(coupleRef, {
        'partnerA': {
          'uid':   fromUid,
          'name':  themData['displayName'] ?? 'User',
          'photo': themData['photoURL'],
        },
        'partnerB': {
          'uid':   myUid,
          'name':  meData['displayName'] ?? 'User',
          'photo': meData['photoURL'],
        },
        'ringId':          ringId,
        'status':          CpStatus.engaged.toRaw(),
        'engagedAt':       FieldValue.serverTimestamp(),
        'marriedAt':       null,
        'anniversaryDate': null,
        'divorceAt':       null,
        'xp':              0,
        'level':           1,
        'sharedBio':       '',
        'lovePoints':      0,
        'giftsExchanged':  0,
        'trustScore':      50,
      });

      // ③ Update both user docs
      final since = FieldValue.serverTimestamp();

      tx.update(meRef, {
        'cpPartnerUid':   fromUid,
        'cpPartnerName':  themData['displayName'] ?? 'User',
        'cpPartnerPhoto': themData['photoURL'],
        'cpRingId':       ringId,
        'cpSince':        since,
        'cpCoupleId':     coupleRef.id,
        'cpStatus':       CpStatus.engaged.toRaw(),
        // Clear any outgoing proposal marker
        'cpSentProposalTo':      FieldValue.delete(),
        'cpSentProposalToName':  FieldValue.delete(),
        'cpSentProposalToPhoto': FieldValue.delete(),
        'cpSentProposalAt':      FieldValue.delete(),
      });

      tx.update(themRef, {
        'cpPartnerUid':   myUid,
        'cpPartnerName':  meData['displayName'] ?? 'User',
        'cpPartnerPhoto': meData['photoURL'],
        'cpRingId':       ringId,
        'cpSince':        since,
        'cpCoupleId':     coupleRef.id,
        'cpStatus':       CpStatus.engaged.toRaw(),
        'cpSentProposalTo':      FieldValue.delete(),
        'cpSentProposalToName':  FieldValue.delete(),
        'cpSentProposalToPhoto': FieldValue.delete(),
        'cpSentProposalAt':      FieldValue.delete(),
      });

      // ④ Delete the accepted proposal inside the transaction
      tx.delete(propRef);
    });

    // ⑤ Clean up ALL other pending proposals for both users (outside tx — best effort)
    // This is safe because any stale proposal that gets accepted later will
    // be rejected by the AlreadyInCpException guard inside the transaction.
    final batch = _db.batch();
    await _clearAllIncomingProposals(batch, myUid);
    await _clearAllIncomingProposals(batch, fromUid);
    await batch.commit();

    // ⑥ Notify the proposer
    await _notify(
      toUid:     fromUid,
      type:      'cp_accepted',
      title:     '💖 CP Proposal Accepted!',
      body:      '${meData['displayName'] ?? 'Someone'} accepted your proposal!',
      fromUid:   myUid,
      fromName:  meData['displayName'] as String?,
      fromPhoto: meData['photoURL'] as String?,
      coupleId:  coupleRef.id,
    );
  }

  // ─── MARRIAGE (Engaged → Married) ───────────────────────────────────────────

  /// Either partner can trigger marriage after being engaged for at least 7 days.
  Future<void> getMarried({
    required String myUid,
    required String coupleId,
  }) async {
    final coupleRef  = _couples.doc(coupleId);
    final coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists) throw Exception('Couple not found');

    final data   = coupleSnap.data()!;
    final status = CpStatusX.fromRaw(data['status'] as String?);
    if (status != CpStatus.engaged) {
      throw Exception('You must be engaged before getting married');
    }

    final engagedAt = (data['engagedAt'] as Timestamp?)?.toDate();
    if (engagedAt == null ||
        DateTime.now().difference(engagedAt).inDays < 7) {
      throw Exception(
          'You must be engaged for at least 7 days before marrying');
    }

    final partnerUid = _getPartnerUid(data, myUid);
    final now        = FieldValue.serverTimestamp();
    final batch      = _db.batch();

    batch.update(coupleRef, {
      'status':          CpStatus.married.toRaw(),
      'marriedAt':       now,
      'anniversaryDate': now,
    });

    batch.update(_users.doc(myUid),      {'cpStatus': CpStatus.married.toRaw()});
    batch.update(_users.doc(partnerUid), {'cpStatus': CpStatus.married.toRaw()});
    await batch.commit();

    await _notify(
      toUid:    partnerUid,
      type:     'cp_married',
      title:    '💒 You Are Married!',
      body:     'Congratulations! Your relationship has levelled up to married.',
      fromUid:  myUid,
      coupleId: coupleId,
    );
  }

  // ─── MUTUAL DIVORCE REQUEST ──────────────────────────────────────────────────

  /// Step 1: request a divorce (stored in /couples/{id}/divorce_requests/{uid}).
  Future<void> requestDivorce({
    required String myUid,
    required String coupleId,
    required String reason,
  }) async {
    final coupleSnap = await _couples.doc(coupleId).get();
    if (!coupleSnap.exists) throw Exception('Couple not found');
    final data       = coupleSnap.data()!;
    final partnerUid = _getPartnerUid(data, myUid);
    final meSnap     = await _users.doc(myUid).get();
    final me         = meSnap.data() ?? {};

    await _couples.doc(coupleId).collection('divorce_requests').doc(myUid).set({
      'uid':       myUid,
      'reason':    reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Flip couple to 'conflict' status
    await _couples.doc(coupleId).update({'status': CpStatus.conflict.toRaw()});
    await _users.doc(myUid).update({'cpStatus': CpStatus.conflict.toRaw()});
    await _users.doc(partnerUid).update({'cpStatus': CpStatus.conflict.toRaw()});

    await _notify(
      toUid:     partnerUid,
      type:      'cp_divorce_request',
      title:     '💔 Divorce Requested',
      body:      '${me['displayName'] ?? 'Your partner'} has requested a divorce. You have 48h to respond.',
      fromUid:   myUid,
      fromName:  me['displayName'] as String?,
      fromPhoto: me['photoURL'] as String?,
      coupleId:  coupleId,
    );
  }

  /// Step 2a: partner declines — relationship goes back to married/engaged.
  Future<void> declineDivorce({
    required String myUid,
    required String coupleId,
  }) async {
    final coupleSnap = await _couples.doc(coupleId).get();
    if (!coupleSnap.exists) throw Exception('Couple not found');
    final data       = coupleSnap.data()!;
    final partnerUid = _getPartnerUid(data, myUid);

    // Remove the divorce request doc
    final requests = await _couples.doc(coupleId).collection('divorce_requests').get();
    final batch = _db.batch();
    for (final doc in requests.docs) {
      batch.delete(doc.reference);
    }

    // Restore previous status
    final prev = data['marriedAt'] != null
        ? CpStatus.married.toRaw()
        : CpStatus.engaged.toRaw();
    batch.update(_couples.doc(coupleId), {'status': prev});
    batch.update(_users.doc(myUid),      {'cpStatus': prev});
    batch.update(_users.doc(partnerUid), {'cpStatus': prev});
    await batch.commit();
  }

  /// Step 2b: partner accepts — finalise the divorce with penalties.
  Future<void> acceptDivorce({
    required String myUid,
    required String coupleId,
  }) => _finaliseDivorce(myUid: myUid, coupleId: coupleId, forced: false);

  /// Forced divorce — triggered after 48h of no response, or by admin.
  Future<void> forceDivorce({
    required String initiatorUid,
    required String coupleId,
  }) => _finaliseDivorce(myUid: initiatorUid, coupleId: coupleId, forced: true);

  Future<void> _finaliseDivorce({
    required String myUid,
    required String coupleId,
    required bool forced,
  }) async {
    final coupleRef  = _couples.doc(coupleId);
    final coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists) throw Exception('Couple not found');

    final data       = coupleSnap.data()!;
    final partnerUid = _getPartnerUid(data, myUid);

    // Penalty: lose 20% of love points
    final lovePoints  = (data['lovePoints'] ?? 0) as int;
    final penalty     = (lovePoints * 0.2).round();
    final cooldownEnd = DateTime.now().add(const Duration(days: 30));

    final batch = _db.batch();

    // Update couple doc to divorced
    batch.update(coupleRef, {
      'status':    CpStatus.divorced.toRaw(),
      'divorceAt': FieldValue.serverTimestamp(),
      'lovePoints': (lovePoints - penalty).clamp(0, double.infinity),
    });

    // Clear both user docs
    for (final uid in [myUid, partnerUid]) {
      batch.update(_users.doc(uid), {
        'cpPartnerUid':              FieldValue.delete(),
        'cpPartnerName':             FieldValue.delete(),
        'cpPartnerPhoto':            FieldValue.delete(),
        'cpRingId':                  FieldValue.delete(),
        'cpSince':                   FieldValue.delete(),
        'cpCoupleId':                FieldValue.delete(),
        'cpStatus':                  FieldValue.delete(),
        'cpDivorceCooldownUntil':    Timestamp.fromDate(cooldownEnd),
      });
    }

    await batch.commit();

    // Notify partner
    await _notify(
      toUid:    partnerUid,
      type:     'cp_breakup',
      title:    forced ? '💔 Divorce Finalised' : '💔 Divorce Accepted',
      body:     forced
          ? 'Your relationship has ended due to no response.'
          : 'Your partner has accepted the divorce.',
      fromUid:  myUid,
      coupleId: coupleId,
    );
  }

  // ─── ANNIVERSARY MILESTONES ──────────────────────────────────────────────────

  /// Call this periodically (e.g. on app open or a background job).
  /// Checks and awards milestones: 7d, 30d, 100d, 365d.
  Future<void> checkAndAwardMilestones({
    required String coupleId,
  }) async {
    final coupleRef  = _couples.doc(coupleId);
    final coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists) return;

    final data        = coupleSnap.data()!;
    final anniversary = (data['anniversaryDate'] as Timestamp?)?.toDate();
    if (anniversary == null) return;

    final days = DateTime.now().difference(anniversary).inDays;
    const milestones = [7, 30, 100, 365];

    for (final m in milestones) {
      if (days < m) break;
      final milestoneRef = coupleRef.collection('milestones').doc('day_$m');
      final existing     = await milestoneRef.get();
      if (existing.exists) continue;

      // Award milestone
      final batch = _db.batch();
      batch.set(milestoneRef, {
        'days':      m,
        'awardedAt': FieldValue.serverTimestamp(),
        'xpAwarded': m * 10,
      });
      batch.update(coupleRef, {
        'xp':         FieldValue.increment(m * 10),
        'lovePoints': FieldValue.increment(m * 5),
      });
      await batch.commit();

      // Notify both partners
      final partnerA = (data['partnerA'] as Map)['uid'] as String;
      final partnerB = (data['partnerB'] as Map)['uid'] as String;
      for (final uid in [partnerA, partnerB]) {
        await _notify(
          toUid:    uid,
          type:     'cp_anniversary',
          title:    '🎉 ${m}d Anniversary!',
          body:     "You and your partner have been together for $m days! 💕",
          coupleId: coupleId,
        );
      }
    }
  }

  // ─── LOVE POINTS / SHARED CURRENCY ──────────────────────────────────────────

  /// Award love points to the couple (e.g. when gifts are exchanged between CPs).
  Future<void> awardLovePoints({
    required String coupleId,
    required int points,
  }) async {
    await _couples.doc(coupleId).update({
      'lovePoints':     FieldValue.increment(points),
      'giftsExchanged': FieldValue.increment(1),
      'xp':             FieldValue.increment(points ~/ 2),
    });

    // Recalculate level (every 1000 XP = 1 level)
    final snap = await _couples.doc(coupleId).get();
    final xp   = (snap.data()?['xp'] ?? 0) as int;
    final level = (xp ~/ 1000).clamp(1, 100);
    await _couples.doc(coupleId).update({'level': level});
  }

  // ─── MISSIONS ───────────────────────────────────────────────────────────────

  /// Complete a couple mission and award its XP + love points.
  Future<void> completeMission({
    required String coupleId,
    required String missionId,
    required int xpReward,
    required int loveReward,
  }) async {
    final missionRef = _couples.doc(coupleId).collection('missions').doc(missionId);
    final existing   = await missionRef.get();
    if (existing.exists && (existing.data()?['completed'] ?? false) == true) {
      throw Exception('Mission already completed');
    }

    final batch = _db.batch();
    batch.set(missionRef, {
      'missionId':   missionId,
      'completed':   true,
      'completedAt': FieldValue.serverTimestamp(),
      'xpAwarded':   xpReward,
      'loveAwarded': loveReward,
    }, SetOptions(merge: true));
    batch.update(_couples.doc(coupleId), {
      'xp':         FieldValue.increment(xpReward),
      'lovePoints': FieldValue.increment(loveReward),
    });
    await batch.commit();
  }

  // ─── COUPLE PROFILE ──────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchCouple(String coupleId) {
    return _couples.doc(coupleId).snapshots().map(
          (s) => s.exists ? {...s.data()!, 'id': s.id} : null,
        );
  }

  Future<void> updateSharedBio({
    required String coupleId,
    required String bio,
  }) async {
    await _couples.doc(coupleId).update({'sharedBio': bio});
  }

  // ─── UTILITIES ───────────────────────────────────────────────────────────────

  String _getPartnerUid(Map<String, dynamic> coupleData, String myUid) {
    final a = (coupleData['partnerA'] as Map?)?['uid'] as String? ?? '';
    return a == myUid
        ? ((coupleData['partnerB'] as Map?)?['uid'] as String? ?? '')
        : a;
  }
}
