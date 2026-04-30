import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../services/cp_service.dart';

class CpInboxScreen extends StatelessWidget {
  const CpInboxScreen({super.key});

  static const _bg = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _purple = Color(0xFF7C5CFF);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('CP Proposals',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(me.uid)
            .collection('cp_proposals')
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _purple));
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
            itemBuilder: (_, i) => _proposalCard(context, me.uid, docs[i]),
          );
        },
      ),
    );
  }

  Widget _proposalCard(
    BuildContext context,
    String myUid,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final fromUid = doc.id;
    final fromName = (d['fromName'] ?? 'User') as String;
    final fromPhoto = d['fromPhoto'] as String?;
    final ringId = d['ringId'] as String?;
    final message = d['message'] as String?;
    final ring = ringId == null ? null : shopItemById(ringId);

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
                    ? Text(fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))
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
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                  child: Text(ring.emoji, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
          if (ring != null) ...[
            const SizedBox(height: 10),
            Text('Ring: ${ring.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                  onPressed: () => _decline(context, myUid, fromUid),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
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
                  onPressed: () => _accept(context, myUid, fromUid, fromName),
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: const Text('Accept',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
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
      BuildContext context, String myUid, String fromUid, String fromName) async {
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

  Future<void> _decline(
      BuildContext context, String myUid, String fromUid) async {
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
