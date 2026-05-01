import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cp_service.dart';

class CoupleProfileScreen extends StatelessWidget {
  final String coupleId;
  const CoupleProfileScreen({super.key, required this.coupleId});

  static const _bg   = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: CpService().watchCouple(coupleId),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          final couple = snap.data;
          if (couple == null) {
            return const Center(
                child: Text('Couple not found',
                    style: TextStyle(color: Colors.white70)));
          }

          final a          = couple['partnerA'] as Map;
          final b          = couple['partnerB'] as Map;
          final status     = CpStatusX.fromRaw(couple['status'] as String?);
          final since      = (couple['engagedAt'] as Timestamp?)?.toDate();
          final married    = (couple['marriedAt'] as Timestamp?)?.toDate();
          final level      = (couple['level'] ?? 1) as int;
          final lovePoints = (couple['lovePoints'] ?? 0) as int;
          final xp         = (couple['xp'] ?? 0) as int;
          final trust      = (couple['trustScore'] ?? 50) as int;
          final sharedBio  = (couple['sharedBio'] ?? '') as String;
          final gifts      = (couple['giftsExchanged'] ?? 0) as int;
          final daysTogether = since == null
              ? 0
              : DateTime.now().difference(since).inDays;
          final partnerIsA = (a['uid'] as String) == myUid;
          final me      = partnerIsA ? a : b;
          final partner = partnerIsA ? b : a;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: _bg,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(
                    me: me,
                    partner: partner,
                    status: status,
                    daysTogether: daysTogether,
                    married: married,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsRow(
                        level: level,
                        love: lovePoints,
                        xp: xp,
                        gifts: gifts,
                        trust: trust),
                    const SizedBox(height: 16),
                    _SharedBioCard(
                        myUid: myUid,
                        coupleId: coupleId,
                        bio: sharedBio),
                    const SizedBox(height: 16),
                    _MilestonesSection(coupleId: coupleId),
                    const SizedBox(height: 16),
                    _MissionsSection(coupleId: coupleId),
                    const SizedBox(height: 24),
                    if (status == CpStatus.conflict)
                      _DivorceResponseCard(
                          myUid: myUid, coupleId: coupleId),
                    if (status != CpStatus.conflict) ...[
                      if (status == CpStatus.engaged)
                        _ActionButton(
                          label: 'Get Married 💒',
                          color: _pink,
                          onTap: () =>
                              _marry(context, myUid, coupleId),
                        ),
                      if (status == CpStatus.married)
                        _ActionButton(
                          label: 'Request Divorce 💔',
                          color: Colors.redAccent,
                          onTap: () =>
                              _requestDivorce(context, myUid, coupleId),
                        ),
                      if (status == CpStatus.engaged)
                        _ActionButton(
                          label: 'Break Engagement',
                          color: Colors.grey.shade700,
                          onTap: () =>
                              _break(context, myUid, coupleId),
                        ),
                    ],
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Marriage ────────────────────────────────────────────────────────────────

  Future<void> _marry(
      BuildContext context, String uid, String cid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Get Married? 💒',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You must have been engaged for at least 7 days. '
          'Are you both ready?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not yet',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: _pink),
              child: const Text('Yes, Get Married!')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await CpService().getMarried(myUid: uid, coupleId: cid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Congratulations! 🎉 You are married!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  // ── Divorce Request ─────────────────────────────────────────────────────────

  Future<void> _requestDivorce(
      BuildContext context, String uid, String cid) async {
    final reasonC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Request Divorce?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your partner has 48h to accept or decline.\n'
              '30-day cooldown applies. You lose 20% love points.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason (required)',
                hintStyle:
                    const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              child: const Text('Request Divorce')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (reasonC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason')),
      );
      return;
    }
    try {
      await CpService().requestDivorce(
          myUid: uid,
          coupleId: cid,
          reason: reasonC.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Divorce request sent. Partner has 48h to respond.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  // ── Break Engagement ────────────────────────────────────────────────────────

  Future<void> _break(
      BuildContext context, String uid, String cid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Break Engagement?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will notify your partner and apply a 7-day cooldown '
          'before you can enter a new CP.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700),
              child: const Text('Break It Off')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await CpService()
          .breakEngagement(myUid: uid, coupleId: cid);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final Map me;
  final Map partner;
  final CpStatus status;
  final int daysTogether;
  final DateTime? married;

  const _HeroHeader({
    required this.me,
    required this.partner,
    required this.status,
    required this.daysTogether,
    required this.married,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B0764), Color(0xFF0B0717)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _avatar(me['photo'] as String?,
                    me['name'] as String? ?? 'Me'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child:
                      Text('💕', style: TextStyle(fontSize: 36)),
                ),
                _avatar(partner['photo'] as String?,
                    partner['name'] as String? ?? 'Partner'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${me['name']} & ${partner['name']}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _statusColor(status)),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$daysTogether days together',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13),
            ),
            if (married != null) ...[
              const SizedBox(height: 4),
              Text(
                'Anniversary: ${_fmtDate(married!)}',
                style: const TextStyle(
                    color: Color(0xFFEC4899), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? photo, String name) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white12,
      backgroundImage:
          photo != null && photo.isNotEmpty
              ? NetworkImage(photo)
              : null,
      child: (photo == null || photo.isEmpty)
          ? Text(name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold))
          : null,
    );
  }

  Color _statusColor(CpStatus s) => switch (s) {
        CpStatus.engaged  => Colors.amber,
        CpStatus.married  => const Color(0xFFEC4899),
        CpStatus.conflict => Colors.orange,
        CpStatus.divorced => Colors.grey,
      };

  String _statusLabel(CpStatus s) => switch (s) {
        CpStatus.engaged  => '💍 Engaged',
        CpStatus.married  => '💒 Married',
        CpStatus.conflict => '⚡ In Conflict',
        CpStatus.divorced => '💔 Divorced',
      };

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int level, love, xp, gifts, trust;
  const _StatsRow(
      {required this.level,
      required this.love,
      required this.xp,
      required this.gifts,
      required this.trust});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF181028),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('Lv.$level', 'Level', Colors.amber),
          _stat('$love', 'Love Pts', const Color(0xFFEC4899)),
          _stat('$xp', 'XP', Colors.purpleAccent),
          _stat('$gifts', 'Gifts', Colors.cyan),
          _stat('$trust%', 'Trust', Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED BIO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SharedBioCard extends StatelessWidget {
  final String myUid, coupleId, bio;
  const _SharedBioCard(
      {required this.myUid,
      required this.coupleId,
      required this.bio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _editBio(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF181028),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                bio.isEmpty
                    ? 'Tap to add a shared bio...'
                    : '"$bio"',
                style: TextStyle(
                    color: bio.isEmpty
                        ? Colors.white38
                        : Colors.white70,
                    fontStyle: bio.isEmpty
                        ? FontStyle.normal
                        : FontStyle.italic),
              ),
            ),
            const Icon(Icons.edit,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _editBio(BuildContext context) async {
    final c = TextEditingController(text: bio);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181028),
        title: const Text('Shared Bio',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          maxLength: 100,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write something together...',
            hintStyle:
                const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await CpService()
        .updateSharedBio(coupleId: coupleId, bio: c.text.trim());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONES SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _MilestonesSection extends StatelessWidget {
  final String coupleId;
  const _MilestonesSection({required this.coupleId});

  static const _milestones = [
    (days: 7,   label: '1 Week',  icon: '🌱'),
    (days: 30,  label: '1 Month', icon: '🌸'),
    (days: 100, label: '100 Days',icon: '💫'),
    (days: 365, label: '1 Year',  icon: '🏆'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Milestones',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('milestones')
              .snapshots(),
          builder: (_, snap) {
            final achieved = snap.data?.docs
                    .map((d) => d.id)
                    .toSet() ??
                {};
            return Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: _milestones.map((m) {
                final done =
                    achieved.contains('day_${m.days}');
                return Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFFEC4899)
                                .withOpacity(0.15)
                            : Colors.white10,
                        border: Border.all(
                          color: done
                              ? const Color(0xFFEC4899)
                              : Colors.white24,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        done ? m.icon : '🔒',
                        style: const TextStyle(
                            fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(m.label,
                        style: TextStyle(
                            color: done
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 10)),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSIONS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _MissionsSection extends StatelessWidget {
  final String coupleId;
  const _MissionsSection({required this.coupleId});

  static const _missions = [
    (id: 'send_first_gift', label: 'Send each other a gift',  xp: 50,  love: 20),
    (id: 'married_7d',      label: 'Stay married for 7 days', xp: 100, love: 50),
    (id: 'share_bio',       label: 'Write a shared bio',       xp: 30,  love: 10),
    (id: 'reach_level_5',   label: 'Reach couple level 5',     xp: 200, love: 100),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Missions',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('missions')
              .snapshots(),
          builder: (_, snap) {
            final done = snap.data?.docs
                    .where((d) =>
                        d.data()['completed'] == true)
                    .map((d) => d.id)
                    .toSet() ??
                {};
            return Column(
              children: _missions.map((m) {
                final complete = done.contains(m.id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    complete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: complete
                        ? const Color(0xFFEC4899)
                        : Colors.white38,
                  ),
                  title: Text(
                    m.label,
                    style: TextStyle(
                        color: complete
                            ? Colors.white54
                            : Colors.white,
                        decoration: complete
                            ? TextDecoration.lineThrough
                            : null),
                  ),
                  trailing: Text(
                    '+${m.xp}XP  +${m.love}💕',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVORCE RESPONSE CARD  (shown when status == conflict)
// ─────────────────────────────────────────────────────────────────────────────

class _DivorceResponseCard extends StatelessWidget {
  final String myUid, coupleId;
  const _DivorceResponseCard(
      {required this.myUid, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('divorce_requests')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final req     = snap.data!.docs.first;
        final reqData = req.data();
        final isMe    = req.id == myUid;
        final reason  = (reqData['reason'] ?? '') as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.orange.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚡ Divorce Request Pending',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Reason: "$reason"',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 12),
              if (isMe)
                // I sent the request — show cancel option
                OutlinedButton.icon(
                  onPressed: () =>
                      _decline(context), // reuse decline to cancel
                  icon: const Icon(Icons.undo,
                      color: Colors.white70),
                  label: const Text('Cancel My Request',
                      style:
                          TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(22)),
                  ),
                )
              else
                // Partner sent the request — accept or decline
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _decline(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.white24),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      22)),
                        ),
                        child: const Text('Decline',
                            style: TextStyle(
                                color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _accept(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      22)),
                        ),
                        child: const Text('Accept Divorce',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _accept(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181028),
        title: const Text('Accept Divorce?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This is final. Both of you will lose 20% love points '
          'and have a 30-day cooldown.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              child: const Text('Accept')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await CpService()
          .acceptDivorce(myUid: myUid, coupleId: coupleId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _decline(BuildContext context) async {
    try {
      await CpService()
          .declineDivorce(myUid: myUid, coupleId: coupleId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ),
    );
  }
}
