import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../models/app_user.dart';
import '../services/tag_service.dart';
import 'cp_propose_sheet.dart';

class UseItemPickerScreen extends StatefulWidget {
  final ShopItem item;
  const UseItemPickerScreen({super.key, required this.item});

  @override
  State<UseItemPickerScreen> createState() => _UseItemPickerScreenState();
}

class _UseItemPickerScreenState extends State<UseItemPickerScreen> {
  static const _bg = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _purple = Color(0xFF7C5CFF);

  final _myUid = FirebaseAuth.instance.currentUser!.uid;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isRing = widget.item.type == ShopItemType.ring;
    final actionLabel = isRing ? 'Propose to' : 'Send to';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '$actionLabel...',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _itemHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase().trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: _card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(200)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }
                final users = snap.data!.docs
                    .map((d) => AppUser.fromMap(d.id, d.data()))
                    .where((u) => u.uid != _myUid)
                    .where((u) => _query.isEmpty
                        ? true
                        : u.displayName.toLowerCase().contains(_query) ||
                            u.uid.toLowerCase().contains(_query))
                    .toList();
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _userTile(users[i], isRing),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemHeader() {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: item.gradient),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.type == ShopItemType.ring
                      ? 'Pick someone to propose to with this ring'
                      : 'Pick someone to send this tag to',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(AppUser u, bool isRing) {
    return GestureDetector(
      onTap: () => _onUserTap(u, isRing),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white12,
              backgroundImage:
                  (u.photoURL != null && u.photoURL!.isNotEmpty)
                      ? NetworkImage(u.photoURL!)
                      : null,
              child: (u.photoURL == null || u.photoURL!.isEmpty)
                  ? Text(
                      u.displayName.isNotEmpty
                          ? u.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              u.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _purple.withOpacity(0.6)),
              ),
              child: Text(
                isRing ? 'Propose 💍' : 'Send 🏷️',
                style: const TextStyle(
                  color: _purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onUserTap(AppUser u, bool isRing) async {
    if (isRing) {
      await showCpProposeSheet(
        context,
        toUid: u.uid,
        toName: u.displayName,
        preselectedRingId: widget.item.id,
      );
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Send "${widget.item.name}" to ${u.displayName}?',
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            'They will receive this tag and can wear it on their profile.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Send',
                style: TextStyle(color: _purple),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await TagService().sendTag(
          fromUid: _myUid,
          toUid: u.uid,
          tagId: widget.item.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag sent to ${u.displayName}!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'.replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }
}
