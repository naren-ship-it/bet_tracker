// lib/app_widgets/app_search_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:bet_tracker/models/player_choice.dart';

class PlayerFilterState {
  final String query;
  final int? roleId;
  final int? battingStyleId;
  final int? bowlingStyleId;
  final String? country;
  final int? jerseyNumber;
  final bool ascending;

  const PlayerFilterState({
    this.query = '',
    this.roleId,
    this.battingStyleId,
    this.bowlingStyleId,
    this.country,
    this.jerseyNumber,
    this.ascending = true,
  });

  PlayerFilterState copyWith({
    String? query,
    int? roleId,
    int? battingStyleId,
    int? bowlingStyleId,
    String? country,
    int? jerseyNumber,
    bool? ascending,
    bool clearRole = false,
    bool clearBatting = false,
    bool clearBowling = false,
    bool clearCountry = false,
    bool clearJersey = false,
  }) =>
      PlayerFilterState(
        query: query ?? this.query,
        roleId: clearRole ? null : roleId ?? this.roleId,
        battingStyleId:
            clearBatting ? null : battingStyleId ?? this.battingStyleId,
        bowlingStyleId:
            clearBowling ? null : bowlingStyleId ?? this.bowlingStyleId,
        country: clearCountry ? null : country ?? this.country,
        jerseyNumber: clearJersey ? null : jerseyNumber ?? this.jerseyNumber,
        ascending: ascending ?? this.ascending,
      );

  bool get hasActiveFilters =>
      roleId != null ||
      battingStyleId != null ||
      bowlingStyleId != null ||
      country != null ||
      jerseyNumber != null;

  PlayerFilterState get cleared => const PlayerFilterState();
}

class AppSearchFilterBar extends StatefulWidget {
  final List<PlayerChoice> roles;
  final List<PlayerChoice> battingStyles;
  final List<PlayerChoice> bowlingStyles;
  final List<String> countries;
  final PlayerFilterState filterState;
  final ValueChanged<PlayerFilterState> onChanged;

  const AppSearchFilterBar({
    super.key,
    required this.roles,
    required this.battingStyles,
    required this.bowlingStyles,
    required this.countries,
    required this.filterState,
    required this.onChanged,
  });

  @override
  State<AppSearchFilterBar> createState() => _AppSearchFilterBarState();
}

class _AppSearchFilterBarState extends State<AppSearchFilterBar> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _jerseyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.filterState.query;
    _jerseyCtrl.text = widget.filterState.jerseyNumber?.toString() ?? '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterPanel(
        roles: widget.roles,
        battingStyles: widget.battingStyles,
        bowlingStyles: widget.bowlingStyles,
        countries: widget.countries,
        current: widget.filterState,
        jerseyCtrl: _jerseyCtrl,
        onApply: (updated) {
          Navigator.pop(context);
          widget.onChanged(updated);
        },
        onReset: () {
          Navigator.pop(context);
          _jerseyCtrl.clear();
          widget.onChanged(PlayerFilterState(query: widget.filterState.query));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = widget.filterState.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Search field — takes remaining space
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                onChanged: (v) => widget
                    .onChanged(widget.filterState.copyWith(query: v.trim())),
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textSecondary, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            widget.onChanged(
                                widget.filterState.copyWith(query: ''));
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort toggle
          _IconBtn(
            icon: widget.filterState.ascending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            tooltip: widget.filterState.ascending
                ? 'Sort A→Z'
                : 'Sort Z→A',
            color: AppColors.textSecondary,
            onTap: () => widget.onChanged(widget.filterState
                .copyWith(ascending: !widget.filterState.ascending)),
          ),
          const SizedBox(width: 6),

          // Filter button — badge when active
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.tune,
                tooltip: 'Filters',
                color: hasFilters ? AppColors.primary : AppColors.textSecondary,
                onTap: _openFilterPanel,
              ),
              if (hasFilters)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── FILTER PANEL ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final List<PlayerChoice> roles;
  final List<PlayerChoice> battingStyles;
  final List<PlayerChoice> bowlingStyles;
  final List<String> countries;
  final PlayerFilterState current;
  final TextEditingController jerseyCtrl;
  final ValueChanged<PlayerFilterState> onApply;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.roles,
    required this.battingStyles,
    required this.bowlingStyles,
    required this.countries,
    required this.current,
    required this.jerseyCtrl,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late PlayerFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onReset,
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Sort order
                  _sectionLabel('Sort Order'),
                  Row(
                    children: [
                      _SortChip(
                        label: 'A → Z',
                        icon: Icons.arrow_upward,
                        selected: _draft.ascending,
                        onTap: () =>
                            setState(() => _draft = _draft.copyWith(ascending: true)),
                      ),
                      const SizedBox(width: 10),
                      _SortChip(
                        label: 'Z → A',
                        icon: Icons.arrow_downward,
                        selected: !_draft.ascending,
                        onTap: () =>
                            setState(() => _draft = _draft.copyWith(ascending: false)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Role
                  _sectionLabel('Role'),
                  _buildChoiceFilter(
                    value: _draft.roleId,
                    choices: widget.roles,
                    onChanged: (v) => setState(() => v == null
                        ? _draft = _draft.copyWith(clearRole: true)
                        : _draft = _draft.copyWith(roleId: v)),
                  ),
                  const SizedBox(height: 16),

                  // Batting Style
                  _sectionLabel('Batting Style'),
                  _buildChoiceFilter(
                    value: _draft.battingStyleId,
                    choices: widget.battingStyles,
                    onChanged: (v) => setState(() => v == null
                        ? _draft = _draft.copyWith(clearBatting: true)
                        : _draft = _draft.copyWith(battingStyleId: v)),
                  ),
                  const SizedBox(height: 16),

                  // Bowling Style
                  _sectionLabel('Bowling Style'),
                  _buildChoiceFilter(
                    value: _draft.bowlingStyleId,
                    choices: widget.bowlingStyles,
                    onChanged: (v) => setState(() => v == null
                        ? _draft = _draft.copyWith(clearBowling: true)
                        : _draft = _draft.copyWith(bowlingStyleId: v)),
                  ),
                  const SizedBox(height: 16),

                  // Country
                  if (widget.countries.isNotEmpty) ...[
                    _sectionLabel('Country'),
                    _buildStringFilter(
                      value: _draft.country,
                      options: widget.countries,
                      onChanged: (v) => setState(() => v == null
                          ? _draft = _draft.copyWith(clearCountry: true)
                          : _draft = _draft.copyWith(country: v)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Jersey Number
                  _sectionLabel('Jersey Number'),
                  TextField(
                    controller: widget.jerseyCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      setState(() => n == null
                          ? _draft = _draft.copyWith(clearJersey: true)
                          : _draft = _draft.copyWith(jerseyNumber: n));
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 7',
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceHigh,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => widget.onApply(_draft),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _buildChoiceFilter({
    required int? value,
    required List<PlayerChoice> choices,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: const Color(0xFF0D1B2A),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Any',
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<int>(
            value: null, child: Text('Any')),
        ...choices.map((c) =>
            DropdownMenuItem<int>(value: c.id, child: Text(c.name))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildStringFilter({
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0D1B2A),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Any',
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Any')),
        ...options.map((c) =>
            DropdownMenuItem<String>(value: c, child: Text(c))),
      ],
      onChanged: onChanged,
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}