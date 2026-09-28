// lib/app_widgets/app_data_table.dart

import 'package:flutter/material.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';

class AppTableColumn {
  final String label;
  final double? width;
  final bool center;

  const AppTableColumn({
    required this.label,
    this.width,
    this.center = false,
  });
}

class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final double rowHeight;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const Divider(color: Colors.white10, height: 1),
          // Rows
          ...rows.asMap().entries.map((e) => Column(
                children: [
                  _buildRow(e.value, e.key.isOdd),
                  if (e.key < rows.length - 1)
                    const Divider(color: Colors.white10, height: 1),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: columns.map((col) {
          final cell = Text(
            col.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            overflow: TextOverflow.ellipsis,
          );
          return col.width != null
              ? SizedBox(
                  width: col.width,
                  child: col.center ? Center(child: cell) : cell)
              : Expanded(child: col.center ? Center(child: cell) : cell);
        }).toList(),
      ),
    );
  }

  Widget _buildRow(List<Widget> cells, bool shaded) {
    return Container(
      height: rowHeight,
      color: shaded ? Colors.white.withOpacity(0.02) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: cells.asMap().entries.map((e) {
          final col = columns[e.key];
          return col.width != null
              ? SizedBox(
                  width: col.width,
                  child: col.center ? Center(child: e.value) : e.value)
              : Expanded(
                  child: col.center ? Center(child: e.value) : e.value);
        }).toList(),
      ),
    );
  }
}