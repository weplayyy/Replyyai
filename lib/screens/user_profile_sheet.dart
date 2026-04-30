import 'package:flutter/material.dart';
import 'user_profile_screen.dart';

Future<void> showUserProfileSheet(
  BuildContext context, {
  required String uid,
  String? roomId,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => UserProfileScreen(uid: uid, roomId: roomId),
    ),
  );
}
