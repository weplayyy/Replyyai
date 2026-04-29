import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Visitors', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(me.uid)
            .collection('visitors')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load visitors.\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final aTs = a.data()['visitedAt'] as Timestamp?;
              final bTs = b.data()['visitedAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });
          if (docs.isEmpty) return _empty();
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) => _visitorTile(docs[i]),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
              ),
              child: const Icon(Icons.visibility_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('No visitors yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('When people view your profile, they\'ll show up here 👀',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.55))),
          ],
        ),
      ),
    );
  }

  Widget _visitorTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final visitorUid = doc.id;
    final ts = doc.data()['visitedAt'] as Timestamp?;
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(visitorUid)
          .get(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 70);
        }
        final u = AppUser.fromMap(snap.data!.data() ?? {'uid': visitorUid});
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              ),
              alignment: Alignment.center,
              child: Text(
                u.displayName.isNotEmpty
                    ? u.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            title: Text(u.displayName,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              ts == null ? 'Recently' : _timeAgo(ts.toDate()),
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
