import 'package:flutter/material.dart';

class ClanPage extends StatelessWidget {
  const ClanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      body: Column(children: [
        _topBar(context),
        Expanded(child: _comingSoon()),
      ]),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF1A0B2E), Color(0xFF0F0A1F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('🛡️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('Clan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _comingSoon() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1040),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.4)),
          ),
          child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 42))),
        ),
        const SizedBox(height: 20),
        const Text('Clan Coming Soon',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Create and join clans to battle together!',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14)),
      ]),
    );
  }
}
