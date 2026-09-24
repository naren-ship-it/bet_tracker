import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Bet Tracker',
          style: TextStyle(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await context
                  .read<AuthProvider>()
                  .logout();

              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                );
              }
            },
            icon: const Icon(
              Icons.logout,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Authentication successful',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}