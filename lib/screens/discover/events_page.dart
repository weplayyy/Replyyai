import 'dart:async';
import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      body: Column(children: [
        _topBar(context),
        Expanded(child: _eventsList()),
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
            const Text('🎁', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('Events',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _eventsList() {
    final events = [
      _EventData('Clan War Season',
          'Battle against other clans and earn epic rank rewards. Top 3 clans win exclusive trophies!',
          '⚔️', '2D 14:30:12',
          const Color(0xFF1C1A50), const Color(0xFF3730A3)),
      _EventData('Love Couple Festival',
          'Gift your CP partner special items and climb the couple leaderboard together!',
          '💕', '5D 08:12:45',
          const Color(0xFF3D1A3A), const Color(0xFF9D174D)),
      _EventData('Treasure Hunt',
          'Open mystery boxes hidden across rooms to win diamonds, coins, and rare frames.',
          '💎', '1D 06:45:20',
          const Color(0xFF162540), const Color(0xFF1E40AF)),
      _EventData('Room King',
          'The room with the most active users wins a featured spot and 10,000 clan coins!',
          '👑', '3D 22:10:00',
          const Color(0xFF2D1B00), const Color(0xFF92400E)),
      _EventData('Gifting Marathon',
          'Send the most gifts in 24 hours and earn the limited "Gift God" badge for your profile!',
          '🎀', '0D 11:30:00',
          const Color(0xFF1C1040), const Color(0xFF5B21B6)),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _EventCard(data: events[i]),
    );
  }
}

class _EventData {
  final String title;
  final String desc;
  final String emoji;
  final String timer;
  final Color bg;
  final Color borderColor;
  const _EventData(this.title, this.desc, this.emoji, this.timer,
      this.bg, this.borderColor);
}

class _EventCard extends StatefulWidget {
  final _EventData data;
  const _EventCard({required this.data});
  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  late int _seconds;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _seconds = _parse(widget.data.timer);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 1 << 30));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  int _parse(String s) {
    try {
      final parts = s.split(' ');
      final days = int.parse(parts[0].replaceAll('D', ''));
      final tp = parts[1].split(':');
      return days * 86400 +
          int.parse(tp[0]) * 3600 +
          int.parse(tp[1]) * 60 +
          int.parse(tp[2]);
    } catch (_) {
      return 0;
    }
  }

  String get _display {
    final d = _seconds ~/ 86400;
    final h = (_seconds % 86400) ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    return '${d}D ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: d.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: d.borderColor.withOpacity(0.65)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: d.borderColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
              child: Text(d.emoji,
                  style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(d.desc,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 13, color: Color(0xFFFBBF24)),
                const SizedBox(width: 5),
                Text(_display,
                    style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [d.borderColor, d.borderColor.withOpacity(0.6)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Join',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
