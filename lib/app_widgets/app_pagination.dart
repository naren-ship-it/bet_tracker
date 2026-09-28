// lib/app_widgets/app_pagination.dart

import 'package:flutter/material.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';

class AppPagination extends StatelessWidget {
  final int currentPage;   // 1-based
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onScrollToTop;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onScrollToTop,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Go to top
          GestureDetector(
            onTap: onScrollToTop,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.keyboard_arrow_up,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Prev
          _PageBtn(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),

          // Page numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildPageNumbers(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Next
          _PageBtn(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),

          // Page count label
          const SizedBox(width: 10),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    // Show max 5 page numbers around current
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (start + 4).clamp(1, totalPages);
    if (end - start < 4) start = (end - 4).clamp(1, totalPages);

    if (start > 1) {
      pages.add(_pageNum(1));
      if (start > 2) pages.add(_ellipsis());
    }

    for (int i = start; i <= end; i++) {
      pages.add(_pageNum(i));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) pages.add(_ellipsis());
      pages.add(_pageNum(totalPages));
    }

    return pages;
  }

  Widget _pageNum(int page) {
    final isActive = page == currentPage;
    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: SizedBox(
          width: 24,
          child: Center(
            child: Text('...',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ),
      );
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary.withOpacity(0.3)),
      ),
    );
  }
}