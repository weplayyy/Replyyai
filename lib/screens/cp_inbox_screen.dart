// lib/screens/cp_inbox_screen.dart
// COMPLETE FILE — delete everything and paste this

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../services/cp_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CpInboxScreen extends StatelessWidget {
  const CpInboxScreen({super.key});

  static const _bg     = Color(0xFF0B0717);
  static const _purple = Color(0xFF7C5CFF);
  static const _pink   = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'CP Proposals',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: _pink,
            unselectedLabelColor: Colors.white54,
            indicatorColor: _pink,
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReceivedProposalsTab(myUid: me.uid),
            _SentProposalTab(myUid: me.uid),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — RECEIVED PROPOSALS  (this is your original CpInboxScreen logic)
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedProposalsTab extends StatelessWidget {
  final String myUid;
  const _ReceivedProposalsTab({required this.myUid});

  static const _bg   = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('cp_proposals')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFF)));
        }
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['createdAt'] as Timestamp?;
            final tb = b.data()['createdAt'] as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
        if (docs.isEmpty) return _empty();
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _proposalCard(context, docs[i]),
        );
      },
    );
  }

  Widget _proposalCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d        = doc.data();
    final fromUid  = doc.id;
    final fromName = (d['fromName'] ?? 'User') as String;
    final fromPhoto = d['fromPhoto'] as String?;
    final ringId   = d['ringId'] as String?;
    final message  = d['message'] as String?;
    final ring     = ringId == null ? null : shopItemById(ringId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white12,
                backgroundImage:
                    fromPhoto != null && fromPhoto.isNotEmpty
                        ? NetworkImage(fromPhoto)
                        : null,
                child: (fromPhoto == null || fromPhoto.isEmpty)
                    ? Text(
                        fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fromName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('wants to be your CP 💖',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              if (ring != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: ring.gradient),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(ring.emoji, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
          if (ring != null) ...[
            const SizedBox(height: 10),
            Text('Ring: ${ring.name}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('"$message"',
                  style: const TextStyle(
                      color: Colors.white, fontStyle: FontStyle.italic)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _decline(context, fromUid),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Decline',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _accept(context, fromUid, fromName),
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: const Text('Accept',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _accept(
      BuildContext context, String fromUid, String fromName) async {
    try {
      await CpService().acceptProposal(myUid: myUid, fromUid: fromUid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and $fromName are now CPs! 💖')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _decline(BuildContext context, String fromUid) async {
    try {
      await CpService().declineProposal(myUid: myUid, fromUid: fromUid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal declined')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('💌', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text('No CP proposals yet',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                "When someone proposes to you with a ring, you'll see it here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — SENT PROPOSALS  (NEW)
// ─────────────────────────────────────────────────────────────────────────────

class _SentProposalTab extends StatelessWidget {
  final String myUid;
  const _SentProposalTab({required this.myUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFF)));
        }
        final data    = snap.data!.data() ?? {};
        final toUid   = data['cpSentProposalTo'] as String?;
        final toName  = data['cpSentProposalToName'] as String?;
        final toPhoto = data['cpSentProposalToPhoto'] as String?;
        final sentAt  = data['cpSentProposalAt'] as Timestamp?;

        if (toUid == null || toUid.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('💌', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text("You haven't sent any proposal",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181028),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFEC4899).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      toPhoto != null ? NetworkImage(toPhoto) : null,
                  backgroundColor: Colors.white12,
                  child: toPhoto == null
                      ? Text(
                          toName?[0].toUpperCase() ?? '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Proposal sent to $toName',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                if (sentAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${_formatTime(sentAt.toDate())}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Waiting for their response...',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      _cancel(context, toUid, toName ?? 'this person'),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: const Text('Cancel Proposal',
                      style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _cancel(
      BuildContext context, String toUid, String toName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181028),
        title: const Text('Cancel Proposal?',
            style: TextStyle(color: Colors.white)),
        content: Text('Cancel your proposal to $toName?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Color(0xFFEC4899))),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await CpService().cancelProposal(fromUid: myUid, toUid: toUid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal cancelled')),
      );
    }
  }
}
