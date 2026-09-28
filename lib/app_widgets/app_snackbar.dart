// lib/app_widgets/app_snackbar.dart

import 'package:flutter/material.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';

enum SnackbarType { error, success, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove any existing snackbar first to avoid stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final Color bgColor = switch (type) {
      SnackbarType.error   => const Color(0xFFB00020),
      SnackbarType.success => const Color(0xFF2E7D32),
      SnackbarType.info    => AppColors.primary,
    };

    final IconData icon = switch (type) {
      SnackbarType.error   => Icons.error_outline_rounded,
      SnackbarType.success => Icons.check_circle_outline_rounded,
      SnackbarType.info    => Icons.info_outline_rounded,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white70,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Convenience shortcuts
  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.error);

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.success);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackbarType.info);
}