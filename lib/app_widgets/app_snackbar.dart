// lib/app_widgets/app_snackbar.dart
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';

enum SnackbarType { error, success, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _entry;

  /// Shows a toast in the root overlay (above dialogs, drawers and the footer).
  static void show(
  BuildContext context,
  String message, {
  SnackbarType type = SnackbarType.error,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  _remove(); // only one toast at a time

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 32,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: _AppToast(
            message: message,
            type: type,
            duration: duration,
            onDismiss: () {
              if (_entry == entry) _remove();
            },
          ),
        ),
      ),
    ),
  );
  _entry = entry;
  overlay.insert(entry);
}
  static void _remove() {
    _entry?.remove();
    _entry = null;
  }

  // Convenience shortcuts
  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.error);

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.success);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.info);
}

class _AppToast extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _closing = false;

  Color get _accent => switch (widget.type) {
        SnackbarType.success => const Color(0xFF22C55E),
        SnackbarType.warning => const Color(0xFFF59E0B),
        SnackbarType.error => const Color(0xFFEF4444),
        SnackbarType.info => AppColors.primary,
      };

  IconData get _icon => switch (widget.type) {
        SnackbarType.success => Icons.check_circle_outline_rounded,
        SnackbarType.warning => Icons.warning_amber_rounded,
        SnackbarType.error => Icons.error_outline_rounded,
        SnackbarType.info => Icons.info_outline_rounded,
      };

  String get _title => switch (widget.type) {
        SnackbarType.success => 'Success',
        SnackbarType.warning => 'Warning',
        SnackbarType.error => 'Error',
        SnackbarType.info => 'Info',
      };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    _timer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _ctrl.reverse();
    } catch (_) {
      // controller disposed mid-animation; nothing to do
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 460),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080F1E).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.08),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: _accent.withValues(alpha: 0.25)),
                        ),
                        child: Icon(_icon, color: _accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _close,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.40),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}