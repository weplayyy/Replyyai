import 'package:flutter/material.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('You\'re all caught up',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}
