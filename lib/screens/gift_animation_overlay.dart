import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Future<void> playGiftAnimation(BuildContext context, String asset) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _GiftAnimationOverlay(asset: asset),
    ),
  );
}

class _GiftAnimationOverlay extends StatefulWidget {
  final String asset;
  const _GiftAnimationOverlay({required this.asset});

  @override
  State<_GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
}

class _GiftAnimationOverlayState extends State<_GiftAnimationOverlay> {
  late VideoPlayerController _ctrl;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset(widget.asset);
    _ctrl.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _ctrl
        ..setLooping(false)
        ..setVolume(1.0)
        ..play();
      _ctrl.addListener(_onTick);
    }).catchError((e, st) {
      debugPrint('GIFT VIDEO ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _error = '$e');
    });
  }

  void _onTick() {
    if (!mounted) return;
    final v = _ctrl.value;
    if (v.hasError) {
      setState(() => _error = v.errorDescription ?? 'unknown video error');
      return;
    }
    if (v.isInitialized &&
        !v.isPlaying &&
        v.position >= v.duration &&
        v.duration > Duration.zero) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Video error:\n${widget.asset}\n\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : _ready
                  ? LayoutBuilder(
                      builder: (context, c) {
                        final ar = _ctrl.value.aspectRatio;
                        final safeAr =
                            (ar.isFinite && ar > 0) ? ar : 9 / 16;
                        return FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _ctrl.value.size.width > 0
                                ? _ctrl.value.size.width
                                : 720,
                            height: _ctrl.value.size.height > 0
                                ? _ctrl.value.size.height
                                : (720 / safeAr),
                            child: VideoPlayer(_ctrl),
                          ),
                        );
                      },
                    )
                  : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
