// screens/team_management_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:bet_tracker/models/team_model.dart';
import 'package:bet_tracker/services/team_service.dart';
import 'package:flutter/material.dart';

class _C {
  static const card = Color(0xFF111827);
  static const field = Color(0xFF0B1220);
  static const border = Color(0xFF1F2A44);
  static const hover = Color(0xFF162036);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

// Change to your server. On the Android emulator use http://10.0.2.2:8000
const String _mediaBase = 'http://127.0.0.1:8000';

String? _resolveLogo(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  return path.startsWith('http') ? path : '$_mediaBase$path';
}

enum _StatusFilter { all, active, inactive }

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _service = TeamService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Team> _teams = [];
  int _count = 0;
  int _page = 1;
  int _pageSize = 10;
  bool _loading = true;
  String? _error;
  _StatusFilter _filter = _StatusFilter.all;

  int _totalAll = 0;
  int _totalActive = 0;
  int _totalInactive = 0;

  int _requestId = 0;

  int get _totalPages => math.max(1, (_count / _pageSize).ceil());

  bool? get _isActiveParam => switch (_filter) {
        _StatusFilter.all => null,
        _StatusFilter.active => true,
        _StatusFilter.inactive => false,
      };

  @override
  void initState() {
    super.initState();
    _load();
    _loadStats();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ───────────── data ─────────────

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.fetchTeams(
        page: _page,
        pageSize: _pageSize,
        search: _searchCtrl.text,
        isActive: _isActiveParam,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _teams = res.results;
        _count = res.count;
        // backend ignores page_size, so use the size it actually returned
        if (_page == 1 && res.next != null && res.results.isNotEmpty) {
          _pageSize = res.results.length;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final r = await Future.wait([
        _service.fetchTeams(pageSize: 1),
        _service.fetchTeams(pageSize: 1, isActive: true),
        _service.fetchTeams(pageSize: 1, isActive: false),
      ]);
      if (!mounted) return;
      setState(() {
        _totalAll = r[0].count;
        _totalActive = r[1].count;
        _totalInactive = r[2].count;
      });
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    await Future.wait([_load(), _loadStats()]);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _page = 1;
      _load();
    });
    setState(() {});
  }

  void _setFilter(_StatusFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _page = 1;
    _load();
  }

  void _goToPage(int p) {
    if (p < 1 || p > _totalPages || p == _page) return;
    setState(() => _page = p);
    _load();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 420,
        backgroundColor: error ? _C.danger : _C.success,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
  }

  // ───────────── actions ─────────────

  Future<void> _openForm([Team? team]) async {
    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: _TeamFormPanel(team: team, service: _service),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
    if (!mounted || saved != true) return;
    _toast(team == null ? 'Team created successfully' : 'Team updated successfully');
    if (team == null) {
      _searchCtrl.clear();
      _filter = _StatusFilter.all;
      _page = 1;
    }
    await _refreshAll();
  }

  Future<void> _toggleActive(Team t) async {
    try {
      await _service.updateTeam(t.id, {'is_active': !t.isActive});
      if (!mounted) return;
      _toast(t.isActive ? '${t.name} deactivated' : '${t.name} activated');
      await _refreshAll();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _confirmDelete(Team t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _C.border),
        ),
        title: const Text('Delete team?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: SizedBox(
          width: 380,
          child: Text(
            '"${t.name}" will be permanently removed, including its tournament allocations. This action cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteTeam(t.id);
      if (!mounted) return;
      _toast('Team deleted');
      if (_teams.length == 1 && _page > 1) _page--;
      await _refreshAll();
    } catch (e) {
      _toast(e.toString(), error: true);
    }
  }

  // ───────────── UI ─────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildToolbar(),
                  const Divider(height: 1, color: _C.border),
                  Expanded(child: _buildBody()),
                  const Divider(height: 1, color: _C.border),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups_outlined, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Management',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Create and manage teams, coaches and owners.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Team', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Total Teams',
                value: _totalAll,
                icon: Icons.groups_outlined,
                color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Active',
                value: _totalActive,
                icon: Icons.check_circle_outline,
                color: _C.success)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Inactive',
                value: _totalInactive,
                icon: Icons.pause_circle_outline,
                color: _C.warning)),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search by team name or short name...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                filled: true,
                fillColor: _C.field,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _SegmentedFilter(value: _filter, onChanged: _setFilter),
          const Spacer(),
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _teams.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        ),
      );
    }
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        color: _C.danger,
        title: 'Could not load teams',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_teams.isEmpty) {
      final filtering = _searchCtrl.text.isNotEmpty || _filter != _StatusFilter.all;
      return _MessageState(
        icon: filtering ? Icons.search_off : Icons.groups_outlined,
        color: AppColors.primary,
        title: filtering ? 'No matching teams' : 'No teams yet',
        subtitle: filtering
            ? 'Try a different search term or clear the filters.'
            : 'Create your first team to get started.',
        actionLabel: filtering ? 'Clear filters' : 'Add Team',
        onAction: filtering
            ? () {
                _searchCtrl.clear();
                _filter = _StatusFilter.all;
                _page = 1;
                _load();
              }
            : () => _openForm(),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final w = math.max(c.maxWidth, 980.0);
      return Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: w,
              child: Column(
                children: [
                  const _TableHeader(),
                  const Divider(height: 1, color: _C.border),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _teams.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: _C.border),
                      itemBuilder: (_, i) => _TeamRow(
                        team: _teams[i],
                        onEdit: () => _openForm(_teams[i]),
                        onDelete: () => _confirmDelete(_teams[i]),
                        onToggle: () => _toggleActive(_teams[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
            ),
        ],
      );
    });
  }

  Widget _buildFooter() {
    final from = _count == 0 ? 0 : (_page - 1) * _pageSize + 1;
    final to = math.min(_page * _pageSize, _count);
    final total = _totalPages;
    var start = math.max(1, _page - 2);
    final end = math.min(total, start + 4);
    start = math.max(1, end - 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Showing $from–$to of $_count teams',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const Spacer(),
          _PageButton(
              icon: Icons.chevron_left, enabled: _page > 1, onTap: () => _goToPage(_page - 1)),
          for (var p = start; p <= end; p++)
            _PageButton(label: '$p', selected: p == _page, onTap: () => _goToPage(p)),
          _PageButton(
              icon: Icons.chevron_right, enabled: _page < total, onTap: () => _goToPage(_page + 1)),
        ],
      ),
    );
  }
}

// ───────────────────────── Widgets ─────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text('$value',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedFilter extends StatelessWidget {
  final _StatusFilter value;
  final ValueChanged<_StatusFilter> onChanged;
  const _SegmentedFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _StatusFilter.all: 'All',
      _StatusFilter.active: 'Active',
      _StatusFilter.inactive: 'Inactive',
    };
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _C.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in _StatusFilter.values)
            GestureDetector(
              onTap: () => onChanged(f),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: f == value ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[f]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: f == value ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    Widget h(String t, int flex) => Expanded(
          flex: flex,
          child: Text(t.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600)),
        );
    return Container(
      color: _C.field,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          h('Team', 26),
          h('Short', 9),
          h('Coach', 16),
          h('Owner', 22),
          h('Home ground', 14),
          h('Status', 12),
          const SizedBox(width: 130),
        ],
      ),
    );
  }
}

class _TeamRow extends StatefulWidget {
  final Team team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  const _TeamRow({
    required this.team,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_TeamRow> createState() => _TeamRowState();
}

class _TeamRowState extends State<_TeamRow> {
  bool _hover = false;

  Widget _cell(String text, int flex) => Expanded(
        flex: flex,
        child: Text(text.isEmpty ? '—' : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: text.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 13.5)),
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.team;
    final statusColor = t.isActive ? _C.success : _C.warning;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? _C.hover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 26,
              child: Row(
                children: [
                  _TeamAvatar(
                    label: t.shortName.isNotEmpty ? t.shortName : t.name,
                    logoUrl: t.logo,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            _cell(t.shortName, 9),
            _cell(t.coachName, 16),
            _cell(t.ownerName, 22),
            _cell(t.homeGround, 14),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(t.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                              color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconAction(
                      icon: t.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      tooltip: t.isActive ? 'Deactivate' : 'Activate',
                      color: t.isActive ? _C.warning : _C.success,
                      onTap: widget.onToggle),
                  _IconAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      color: AppColors.textSecondary,
                      onTap: widget.onEdit),
                  _IconAction(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: _C.danger,
                      onTap: widget.onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onTap,
          splashRadius: 18,
          icon: Icon(icon, size: 19, color: color),
        ),
      );
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _PageButton(
      {this.label, this.icon, this.selected = false, this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : _C.border),
          ),
          child: icon != null
              ? Icon(icon,
                  size: 18,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.4))
              : Text(label!,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

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
                color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _C.border),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

/// Team logo, falling back to a coloured initials badge.
class _TeamAvatar extends StatelessWidget {
  final String label;
  final String? logoUrl;
  final double size;
  const _TeamAvatar({required this.label, this.logoUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF14B8A6),
      Color(0xFFF59E0B), Color(0xFF22C55E), Color(0xFFEF4444), Color(0xFF06B6D4),
    ];
    final text = label.trim();
    final color = palette[text.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
    final initials =
        text.isEmpty ? '?' : (text.length <= 3 ? text : text.substring(0, 2)).toUpperCase();

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(initials,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );

    final url = _resolveLogo(logoUrl);
    if (url == null) return fallback;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(3),
      child: Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

// ───────────────────────── Add / Edit Team panel ─────────────────────────

class _TeamFormPanel extends StatefulWidget {
  final Team? team;
  final TeamService service;
  const _TeamFormPanel({this.team, required this.service});

  @override
  State<_TeamFormPanel> createState() => _TeamFormPanelState();
}

class _TeamFormPanelState extends State<_TeamFormPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _short;
  late final TextEditingController _owner;
  late final TextEditingController _coach;
  late final TextEditingController _ground;
  late bool _active;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.team != null;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _name = TextEditingController(text: t?.name ?? '');
    _short = TextEditingController(text: t?.shortName ?? '');
    _owner = TextEditingController(text: t?.ownerName ?? '');
    _coach = TextEditingController(text: t?.coachName ?? '');
    _ground = TextEditingController(text: t?.homeGround ?? '');
    _active = t?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _short, _owner, _coach, _ground]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'short_name': _short.text.trim().toUpperCase(),
      'owner_name': _owner.text.trim(),
      'coach_name': _coach.text.trim(),
      'home_ground': _ground.text.trim(),
      'is_active': _active,
    };

    try {
      if (_isEdit) {
        await widget.service.updateTeam(widget.team!.id, fields);
      } else {
        await widget.service.createTeamWithFields(fields);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c));
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: _C.field,
      enabledBorder: b(_C.border),
      focusedBorder: b(AppColors.primary),
      errorBorder: b(_C.danger),
      focusedErrorBorder: b(_C.danger),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.textPrimary, fontSize: 14);
    final previewLabel = _short.text.trim().isNotEmpty ? _short.text.trim() : _name.text.trim();

    return Material(
      color: _C.card,
      child: Container(
        width: 460,
        height: double.infinity,
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: _C.border))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEdit ? 'Edit Team' : 'Add Team',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            _isEdit
                                ? 'Update the details of this team.'
                                : 'Fill in the details to create a new team.',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _C.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: _TeamAvatar(
                          label: previewLabel,
                          logoUrl: widget.team?.logo,
                          size: 72,
                        ),
                      ),
                      _section('Basic information'),
                      TextFormField(
                        controller: _name,
                        style: style,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Team name *', icon: Icons.shield_outlined),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Team name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _short,
                        style: style,
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Short name *', icon: Icons.short_text)
                            .copyWith(counterText: ''),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Short name is required' : null,
                      ),
                      _section('Management'),
                      TextFormField(
                        controller: _coach,
                        style: style,
                        decoration: _dec('Coach name', icon: Icons.sports_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _owner,
                        style: style,
                        decoration: _dec('Owner name', icon: Icons.business_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ground,
                        style: style,
                        decoration: _dec('Home ground', icon: Icons.stadium_outlined),
                      ),
                      _section('Status'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.field,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _C.success,
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                          title: const Text('Active team',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                          subtitle: const Text(
                              'Inactive teams cannot be allocated to tournaments.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _C.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _C.danger.withValues(alpha: 0.4)),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(color: _C.danger, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: _C.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: _C.border),
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Save changes' : 'Create team',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
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
}