import 'package:flutter/foundation.dart';
import '../models/room.dart';
import 'room_service.dart';

/// Tracks the room the user is "still in" but has minimized into the
/// floating bubble. Singleton, app-wide.
///
/// - enter()    : open room screen (joins membership + present=true)
/// - minimize() : back-press leaves screen but stays in room (present=false)
/// - resume()   : tap the bubble to come back (present=true)
/// - exit()     : Exit button → fully leaves and removes the bubble
class ActiveRoomService extends ChangeNotifier {
  ActiveRoomService._();
  static final ActiveRoomService instance = ActiveRoomService._();

  Room? _room;
  bool _fullscreen = false;

  Room? get room => _room;
  bool get isActive => _room != null;

  /// Bubble shows only when a room is active AND we're not currently
  /// looking at the room screen.
  bool get showBubble => _room != null && !_fullscreen;

  /// The room screen calls this to suppress / unsuppress the bubble.
  void setFullscreen(bool v) {
    if (_fullscreen == v) return;
    _fullscreen = v;
    notifyListeners();
  }

  Future<void> enter(Room room) async {
    if (_room != null && _room!.id != room.id) {
      // Switching rooms — leave the old one cleanly first.
      try {
        await RoomService().leaveRoom(_room!.id);
      } catch (_) {}
    }
    _room = room;
    notifyListeners();
    await RoomService().joinRoom(room.id);
    await RoomService().setPresent(room.id, true);
  }

  Future<void> minimize() async {
    if (_room == null) return;
    await RoomService().setPresent(_room!.id, false);
    notifyListeners();
  }

  Future<void> resume() async {
    if (_room == null) return;
    await RoomService().setPresent(_room!.id, true);
    notifyListeners();
  }

  Future<void> exit() async {
    if (_room == null) return;
    final id = _room!.id;
    _room = null;
    _fullscreen = false;
    notifyListeners();
    try {
      await RoomService().leaveRoom(id);
    } catch (_) {}
  }
}
