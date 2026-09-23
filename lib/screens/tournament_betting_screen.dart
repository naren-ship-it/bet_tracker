import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class TournamentBettingScreen extends StatelessWidget {
  const TournamentBettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.insights_outlined,
                size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tournament Betting',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track odds, bets, and live betting activity.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}