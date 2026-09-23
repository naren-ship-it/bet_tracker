import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

// ── Models (UI-only, local state) ──────────────────────────────────────────

class TournamentType {
  TournamentType({required this.name, required this.icon});
  final String name;
  final IconData icon;
}

enum TournamentStatus { upcoming, live, completed }

class Tournament {
  Tournament({
    required this.name,
    required this.type,
    required this.startDate,
    required this.teams,
    required this.status,
  });

  final String name;
  final String type;
  final String startDate;
  final int teams;
  final TournamentStatus status;
}

// ── Screen ────────────────────────────────────────────────────────────────

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() =>
      _TournamentManagementScreenState();
}

class _TournamentManagementScreenState
    extends State<TournamentManagementScreen> {
  final List<TournamentType> _types = [
    TournamentType(name: 'T20', icon: Icons.bolt_outlined),
    TournamentType(name: 'ODI', icon: Icons.sports_cricket_outlined),
    TournamentType(name: 'Test', icon: Icons.calendar_view_week_outlined),
    TournamentType(name: 'League', icon: Icons.leaderboard_outlined),
  ];

  final List<Tournament> _tournaments = [
    Tournament(
      name: 'Chennai Premier League 2026',
      type: 'T20',
      startDate: '05 Oct 2026',
      teams: 8,
      status: TournamentStatus.upcoming,
    ),
    Tournament(
      name: 'City Cricket Cup',
      type: 'ODI',
      startDate: '23 Sep 2026',
      teams: 6,
      status: TournamentStatus.live,
    ),
    Tournament(
      name: 'Summer Test Series',
      type: 'Test',
      startDate: '01 Aug 2026',
      teams: 4,
      status: TournamentStatus.completed,
    ),
  ];

  void _addTournamentType() {
    final nameCtrl = TextEditingController();
    IconData selectedIcon = Icons.emoji_events_outlined;

    final iconOptions = [
      Icons.bolt_outlined,
      Icons.sports_cricket_outlined,
      Icons.calendar_view_week_outlined,
      Icons.leaderboard_outlined,
      Icons.emoji_events_outlined,
      Icons.groups_outlined,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _AppDialog(
            title: 'New Tournament Type',
            children: [
              _DialogLabel('Type name'),
              _DialogTextField(controller: nameCtrl, hint: 'e.g. T10, Knockout'),
              const SizedBox(height: 16),
              _DialogLabel('Icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: iconOptions.map((icon) {
                  final isSelected = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.16)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _types.add(
                  TournamentType(
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                  ),
                );
              });
              Navigator.pop(context);
            },
            confirmLabel: 'Create',
          );
        },
      ),
    );
  }

  void _addTournament() {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final teamsCtrl = TextEditingController();
    String? selectedType = _types.isNotEmpty ? _types.first.name : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _AppDialog(
            title: 'New Tournament',
            children: [
              _DialogLabel('Tournament name'),
              _DialogTextField(
                controller: nameCtrl,
                hint: 'e.g. Winter Cricket Cup',
              ),
              const SizedBox(height: 16),
              _DialogLabel('Type'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceHigh,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: _types
                        .map(
                          (t) => DropdownMenuItem(
                        value: t.name,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(t.name),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogLabel('Start date'),
                        _DialogTextField(
                          controller: dateCtrl,
                          hint: 'DD Mon YYYY',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogLabel('No. of teams'),
                        _DialogTextField(
                          controller: teamsCtrl,
                          hint: 'e.g. 8',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              if (nameCtrl.text.trim().isEmpty || selectedType == null) return;
              setState(() {
                _tournaments.insert(
                  0,
                  Tournament(
                    name: nameCtrl.text.trim(),
                    type: selectedType!,
                    startDate:
                    dateCtrl.text.trim().isEmpty ? '—' : dateCtrl.text.trim(),
                    teams: int.tryParse(teamsCtrl.text.trim()) ?? 0,
                    status: TournamentStatus.upcoming,
                  ),
                );
              });
              Navigator.pop(context);
            },
            confirmLabel: 'Create',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScreenHeader(
              icon: Icons.workspace_premium_outlined,
              title: 'Tournament Management',
              subtitle: 'Create tournament types and manage tournaments.',
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Tournament Types',
              actionLabel: 'Add Type',
              onAction: _addTournamentType,
            ),
            const SizedBox(height: 14),
            _types.isEmpty
                ? const _EmptyState(message: 'No tournament types yet.')
                : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _types
                  .map((t) => _TypeChip(type: t))
                  .toList(),
            ),
            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Tournaments',
              actionLabel: 'Add Tournament',
              onAction: _addTournament,
            ),
            const SizedBox(height: 14),
            _tournaments.isEmpty
                ? const _EmptyState(message: 'No tournaments created yet.')
                : Column(
              children: _tournaments
                  .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TournamentCard(tournament: t),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header widgets ────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        _PrimaryButton(label: actionLabel, onTap: onAction),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.primaryDark : AppColors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: AppColors.background),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tournament type chip ─────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final TournamentType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            type.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tournament card ───────────────────────────────────────────────────────

class _TournamentCard extends StatefulWidget {
  const _TournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  State<_TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<_TournamentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovering ? AppColors.surfaceHigh : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _MetaChip(icon: Icons.category_outlined, label: t.type),
                      const SizedBox(width: 8),
                      _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label: t.startDate),
                      const SizedBox(width: 8),
                      _MetaChip(
                          icon: Icons.groups_outlined,
                          label: '${t.teams} teams'),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: t.status),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: _hovering
                    ? AppColors.textPrimary
                    : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (status) {
      case TournamentStatus.upcoming:
        color = AppColors.secondary;
        label = 'Upcoming';
        break;
      case TournamentStatus.live:
        color = AppColors.primary;
        label = 'Live';
        break;
      case TournamentStatus.completed:
        color = AppColors.textMuted;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
    );
  }
}

// ── Shared dialog widgets ────────────────────────────────────────────────

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.children,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    onTap: onCancel,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    onTap: onConfirm,
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (_hovering ? AppColors.primaryDark : AppColors.primary)
        : (_hovering ? AppColors.surfaceHigh : Colors.transparent);
    final fg = widget.filled ? AppColors.background : AppColors.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.filled
                ? null
                : Border.all(color: AppColors.border.withOpacity(0.6)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}