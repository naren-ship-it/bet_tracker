// screens/tournament_management_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:bet_tracker/models/team_model.dart';
import 'package:bet_tracker/models/tournament_model.dart';
import 'package:bet_tracker/models/tournament_team_model.dart';
import 'package:bet_tracker/models/tournament_type_model.dart';
import 'package:bet_tracker/services/team_service.dart';
import 'package:bet_tracker/services/tournament_service.dart';
import 'package:bet_tracker/services/tournament_type_service.dart';
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
const String _mediaBase = 'http://127.0.0.1:8000';

String? _resolveLogo(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  return path.startsWith('http') ? path : '$_mediaBase$path';
}

enum _StatusFilter { all, upcoming, ongoing, completed, cancelled }

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() =>
      _TournamentManagementScreenState();
}

class _TournamentManagementScreenState
    extends State<TournamentManagementScreen> {
  final _typeService = TournamentTypeService();
  final _tournamentService = TournamentService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<TournamentType> _types = [];
  List<Tournament> _tournaments = [];

  int _count = 0;
  int _page = 1;
  int _pageSize = 10;
  bool _loading = true;
  String? _error;
  _StatusFilter _filter = _StatusFilter.all;
  int? _typeId;

  int _totalAll = 0;
  int _totalUpcoming = 0;
  int _totalOngoing = 0;
  int _totalCompleted = 0;

  int _requestId = 0;

  int get _totalPages => math.max(1, (_count / _pageSize).ceil());

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _load();
    _loadStats();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String? get _statusParam => switch (_filter) {
        _StatusFilter.all => null,
        _StatusFilter.upcoming => 'upcoming',
        _StatusFilter.ongoing => 'ongoing',
        _StatusFilter.completed => 'completed',
        _StatusFilter.cancelled => 'cancelled',
      };

  Future<void> _loadTypes() async {
    try {
      final types = await _typeService.fetchTournamentTypes();
      if (!mounted) return;
      setState(() => _types = types);
    } catch (_) {}
  }

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _tournamentService.fetchTournaments(
        page: _page,
        pageSize: _pageSize,
        search: _searchCtrl.text,
        tournamentTypeId: _typeId,
        status: _statusParam,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _tournaments = res.results;
        _count = res.count;
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
        _tournamentService.fetchTournaments(pageSize: 1),
        _tournamentService.fetchTournaments(pageSize: 1, status: 'upcoming'),
        _tournamentService.fetchTournaments(pageSize: 1, status: 'ongoing'),
        _tournamentService.fetchTournaments(pageSize: 1, status: 'completed'),
      ]);
      if (!mounted) return;
      setState(() {
        _totalAll = r[0].count;
        _totalUpcoming = r[1].count;
        _totalOngoing = r[2].count;
        _totalCompleted = r[3].count;
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
      _refreshAll();
    });
    setState(() {});
  }

  void _setFilter(_StatusFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _page = 1;
    _refreshAll();
  }

  void _setType(int? id) {
    if (id == _typeId) return;
    setState(() => _typeId = id);
    _page = 1;
    _refreshAll();
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

  // ── Add Tournament Type ──

  void _addTournamentType() {
    final nameCtrl = TextEditingController();
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _SimpleDialog(
            title: 'New Tournament Type',
            children: [
              _FieldLabel('Type name'),
              _SimpleTextField(controller: nameCtrl, hint: 'e.g. T10, Knockout'),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: _C.danger, fontSize: 12)),
              ],
            ],
            onCancel: saving ? null : () => Navigator.pop(context),
            onConfirm: saving
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    setDialogState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final created = await _typeService.createTournamentType(name);
                      if (!mounted) return;
                      setState(() => _types = [..._types, created]);
                      Navigator.pop(context);
                      _toast('Tournament type created');
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        error = e.toString();
                      });
                    }
                  },
            confirmLabel: saving ? 'Creating...' : 'Create',
          );
        },
      ),
    );
  }

  // ── Add / Edit Tournament (slide-in panel) ──

  Future<void> _openForm([Tournament? tournament]) async {
    final saved = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: _TournamentFormPanel(
          tournament: tournament,
          service: _tournamentService,
          types: _types,
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      _toast(tournament == null
          ? 'Tournament created successfully'
          : 'Tournament updated successfully');
      if (tournament == null) {
        // reset search/filters so the newly created row is visible
        _searchCtrl.clear();
        _filter = _StatusFilter.all;
        _typeId = null;
        _page = 1;
      }
      await _refreshAll();
    }
  }

  // ── Allocate Teams (large slide-in drawer) ──

  Future<void> _openAllocateTeams(Tournament tournament) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: _AllocateTeamsPanel(
          tournament: tournament,
          service: _tournamentService,
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
    // Always refetch, even if the drawer was dismissed by tapping outside it.
    if (!mounted) return;
    await _refreshAll();
  }

  Future<void> _confirmDelete(Tournament t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _C.border),
        ),
        title: const Text('Delete tournament?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: SizedBox(
          width: 380,
          child: Text(
            '"${t.name}" and all its team allocations will be permanently removed. This action cannot be undone.',
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
      await _tournamentService.deleteTournament(t.id);
      if (!mounted) return;
      _toast('Tournament deleted');
      if (_tournaments.length == 1 && _page > 1) _page--;
      await _refreshAll();
    } catch (e) {
      if (mounted) _toast(e.toString(), error: true);
    }
  }

  // ───────────────────────── UI ─────────────────────────

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
          child: const Icon(Icons.workspace_premium_outlined,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tournament Management',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Create tournament types, manage tournaments and allocate teams.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _C.border),
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _addTournamentType,
          icon: const Icon(Icons.category_outlined, size: 17),
          label: const Text('Add Type', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Tournament', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Total Tournaments',
                value: _totalAll,
                icon: Icons.workspace_premium_outlined,
                color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Upcoming',
                value: _totalUpcoming,
                icon: Icons.schedule_outlined,
                color: AppColors.secondary)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Ongoing',
                value: _totalOngoing,
                icon: Icons.play_circle_outline,
                color: _C.success)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Completed',
                value: _totalCompleted,
                icon: Icons.check_circle_outline,
                color: AppColors.textSecondary)),
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
                hintText: 'Search by tournament name or year...',
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
          const SizedBox(width: 14),
          _buildTypeDropdown(),
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

  Widget _buildTypeDropdown() {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _typeId,
          isExpanded: true,
          isDense: true,
          hint: const Text('All types',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          dropdownColor: _C.card,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All types')),
            ..._types.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
          ],
          onChanged: _setType,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _tournaments.isEmpty) {
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
        title: 'Could not load tournaments',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_tournaments.isEmpty) {
      final filtering = _searchCtrl.text.isNotEmpty ||
          _filter != _StatusFilter.all ||
          _typeId != null;
      return _MessageState(
        icon: filtering ? Icons.search_off : Icons.workspace_premium_outlined,
        color: AppColors.primary,
        title: filtering ? 'No matching tournaments' : 'No tournaments yet',
        subtitle: filtering
            ? 'Try a different search term or clear the filters.'
            : 'Create your first tournament to get started.',
        actionLabel: filtering ? 'Clear filters' : 'Add Tournament',
        onAction: filtering
            ? () {
                _searchCtrl.clear();
                _filter = _StatusFilter.all;
                _typeId = null;
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
                      itemCount: _tournaments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: _C.border),
                      itemBuilder: (_, i) => _TournamentRow(
                        tournament: _tournaments[i],
                        onEdit: () => _openForm(_tournaments[i]),
                        onDelete: () => _confirmDelete(_tournaments[i]),
                        onAllocateTeams: () => _openAllocateTeams(_tournaments[i]),
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
          Text('Showing $from–$to of $_count tournaments',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const Spacer(),
          _PageButton(icon: Icons.chevron_left, enabled: _page > 1, onTap: () => _goToPage(_page - 1)),
          for (var p = start; p <= end; p++)
            _PageButton(label: '$p', selected: p == _page, onTap: () => _goToPage(p)),
          _PageButton(icon: Icons.chevron_right, enabled: _page < total, onTap: () => _goToPage(_page + 1)),
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
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
      _StatusFilter.upcoming: 'Upcoming',
      _StatusFilter.ongoing: 'Ongoing',
      _StatusFilter.completed: 'Completed',
      _StatusFilter.cancelled: 'Cancelled',
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
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
          h('Tournament', 26),
          h('Type', 14),
          h('Duration', 20),
          h('Year', 8),
          h('Status', 12),
          h('Teams', 10),
          const SizedBox(width: 130),
        ],
      ),
    );
  }
}

class _TournamentRow extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAllocateTeams;

  const _TournamentRow({
    required this.tournament,
    required this.onEdit,
    required this.onDelete,
    required this.onAllocateTeams,
  });

  @override
  State<_TournamentRow> createState() => _TournamentRowState();
}

class _TournamentRowState extends State<_TournamentRow> {
  bool _hover = false;

  Widget _cell(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text.isEmpty ? '—' : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: text.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 13.5)),
      );

  Color _statusColor(String status) => switch (status) {
        'ongoing' => _C.success,
        'upcoming' => AppColors.primary,
        'completed' => AppColors.textSecondary,
        'cancelled' => _C.danger,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                        if (t.description.isNotEmpty)
                          Text(t.description,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _cell(t.tournamentTypeName, flex: 14),
            _cell('${t.startDate} → ${t.endDate}', flex: 20),
            _cell(t.year, flex: 8),
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(t.status).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: _statusColor(t.status), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        t.status[0].toUpperCase() + t.status.substring(1),
                        style: TextStyle(
                            color: _statusColor(t.status), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                t.maxTeams != null ? '${t.teamCount}/${t.maxTeams}' : '${t.teamCount}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ),
            SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _IconAction(
                      icon: Icons.groups_outlined,
                      tooltip: 'Allocate teams',
                      color: AppColors.primary,
                      onTap: widget.onAllocateTeams),
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
  const _IconAction({required this.icon, required this.tooltip, required this.color, required this.onTap});

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
  const _PageButton({this.label, this.icon, this.selected = false, this.enabled = true, required this.onTap});

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
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4))
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
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

// ───────────────────────── Add/Edit Tournament slide-in panel ─────────────────────────

class _TournamentFormPanel extends StatefulWidget {
  final Tournament? tournament;
  final TournamentService service;
  final List<TournamentType> types;

  const _TournamentFormPanel({this.tournament, required this.service, required this.types});

  @override
  State<_TournamentFormPanel> createState() => _TournamentFormPanelState();
}

class _TournamentFormPanelState extends State<_TournamentFormPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _year;
  late final TextEditingController _maxTeams;
  int? _typeId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _bettingOn;
  String _status = 'upcoming';
  late bool _active;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.tournament != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _name = TextEditingController(text: t?.name ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _year = TextEditingController(text: t?.year ?? '${DateTime.now().year}');
    _maxTeams = TextEditingController(text: t?.maxTeams?.toString() ?? '');
    _typeId = t?.tournamentType;
    _startDate = t != null ? DateTime.tryParse(t.startDate) : null;
    _endDate = t != null ? DateTime.tryParse(t.endDate) : null;
    _bettingOn = t != null ? DateTime.tryParse(t.bettingOn) : null;
    _status = t?.status ?? 'upcoming';
    _active = t?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _year, _maxTeams]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    var init = initial ?? DateTime.now();
    if (init.isAfter(last)) init = last;
    if (init.isBefore(first)) init = first;

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeId == null) {
      setState(() => _error = 'Please select a tournament type.');
      return;
    }
    if (_startDate == null || _endDate == null || _bettingOn == null) {
      setState(() => _error = 'Please select start date, end date and betting-on date.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }
    if (!_bettingOn!.isBefore(_startDate!)) {
      setState(() => _error = 'Betting-on date must be before the tournament start date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final fields = Tournament.toFields(
      name: _name.text.trim(),
      tournamentType: _typeId!,
      bettingOn: _fmt(_bettingOn),
      description: _description.text.trim(),
      year: _year.text.trim(),
      startDate: _fmt(_startDate),
      endDate: _fmt(_endDate),
      status: _status,
      maxTeams: int.tryParse(_maxTeams.text.trim()),
      isActive: _active,
    );

    try {
      if (_isEdit) {
        await widget.service.updateTournament(widget.tournament!.id, fields);
      } else {
        await widget.service.createTournament(fields);
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

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder b(Color c) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.9, fontWeight: FontWeight.w600)),
      );

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked, {
    DateTime? firstDate,
    DateTime? lastDate,
    String? blockedMessage,
  }) {
    return InkWell(
      onTap: () {
        if (blockedMessage != null) {
          setState(() => _error = blockedMessage);
          return;
        }
        setState(() => _error = null);
        _pickDate(
          initial: value,
          onPicked: onPicked,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      },
      child: InputDecorator(
        decoration: _dec(label, icon: Icons.calendar_today_outlined),
        child: Text(
          value == null ? 'Select date' : _fmt(value),
          style: TextStyle(
              color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.textPrimary, fontSize: 14);
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
                        Text(_isEdit ? 'Edit Tournament' : 'Add Tournament',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            _isEdit ? 'Update the details of this tournament.' : 'Fill in the details to create a new tournament.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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
                      _section('Basic information'),
                      TextFormField(
                        controller: _name,
                        style: style,
                        decoration: _dec('Tournament name *', icon: Icons.shield_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Tournament name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _C.field,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _typeId,
                            isExpanded: true,
                            hint: const Text('Select tournament type *',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            dropdownColor: _C.card,
                            style: style,
                            items: widget.types.map((t) => DropdownMenuItem<int>(value: t.id, child: Text(t.name))).toList(),
                            onChanged: (v) => setState(() => _typeId = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _description,
                        style: style,
                        maxLines: 2,
                        decoration: _dec('Description', icon: Icons.notes_outlined),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _year,
                              style: style,
                              decoration: _dec('Year *', icon: Icons.event_outlined),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Year is required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxTeams,
                              style: style,
                              keyboardType: TextInputType.number,
                              decoration: _dec('Max teams', icon: Icons.groups_outlined),
                            ),
                          ),
                        ],
                      ),
                      _section('Schedule'),
                      Row(
                        children: [
                          Expanded(
                            child: _dateField('Start date *', _startDate, (d) {
                              setState(() {
                                _startDate = d;
                                if (_endDate != null && _endDate!.isBefore(d)) {
                                  _endDate = null;
                                }
                                // betting date must stay strictly before the start date
                                if (_bettingOn != null && !_bettingOn!.isBefore(d)) {
                                  _bettingOn = null;
                                }
                              });
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateField(
                              'End date *',
                              _endDate,
                              (d) => setState(() => _endDate = d),
                              firstDate: _startDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dateField(
                        'Betting on * (before start date)',
                        _bettingOn,
                        (d) => setState(() => _bettingOn = d),
                        lastDate: _startDate == null
                            ? null
                            : DateTime(_startDate!.year, _startDate!.month, _startDate!.day - 1),
                        blockedMessage: _startDate == null ? 'Select the start date first.' : null,
                      ),
                      _section('Status'),
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _C.field,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            dropdownColor: _C.card,
                            style: style,
                            items: const [
                              DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                              DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                          title: const Text('Active tournament', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                          subtitle: const Text('Inactive tournaments are hidden from listings.',
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
                          child: Text(_error!, style: const TextStyle(color: _C.danger, fontSize: 13)),
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
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Save changes' : 'Create tournament',
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

// ───────────────────────── Allocate Teams large drawer ─────────────────────────



class _AllocateTeamsPanel extends StatefulWidget {
  final Tournament tournament;
  final TournamentService service;

  const _AllocateTeamsPanel({required this.tournament, required this.service});

  @override
  State<_AllocateTeamsPanel> createState() => _AllocateTeamsPanelState();
}

class _AllocateTeamsPanelState extends State<_AllocateTeamsPanel> {
  final _teamService = TeamService();
  final _searchCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();

  List<Team> _allTeams = [];
  List<TournamentTeam> _allocated = [];
  final Set<int> _selected = {};
  final Set<int> _removing = {};

  int _tab = 0; // 0 = allocated, 1 = add teams
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;
  String? _error;

  int? get _max => widget.tournament.maxTeams;
  int? get _remaining => _max == null ? null : math.max(0, _max! - _allocated.length);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  // ───────────── data ─────────────

  /// Follows `next` so every page of teams is loaded.
  Future<List<Team>> _fetchEveryTeam() async {
    final all = <Team>[];
    var page = 1;
    while (page <= 50) {
      final res = await _teamService.fetchTeams(page: page, pageSize: 100, isActive: true);
      all.addAll(res.results);
      if (res.next == null || res.results.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (teams, allocated) = await (
        _fetchEveryTeam(),
        widget.service.fetchTournamentTeams(widget.tournament.id),
      ).wait;
      if (!mounted) return;
      setState(() {
        _allTeams = teams;
        _allocated = allocated;
        _tab = allocated.isEmpty ? 1 : 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadAllocated() async {
    final list = await widget.service.fetchTournamentTeams(widget.tournament.id);
    if (!mounted) return;
    setState(() => _allocated = list);
  }

  Future<void> _allocateSelected() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await widget.service.bulkAllocateTeams(
        tournamentIds: [widget.tournament.id],
        teamIds: _selected.toList(),
        groupName: _groupCtrl.text.trim(),
      );
      final created = result['created_count'] ?? _selected.length;
      _changed = true;
      // reload from the backend so the list always reflects the server
      await _reloadAllocated();
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _searchCtrl.clear();
        _groupCtrl.clear();
        _tab = 0;
      });
      _snack('$created team(s) allocated successfully.');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(TournamentTeam a) async {
    final name = _nameFor(a);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _C.border),
        ),
        title: const Text('Remove team?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text('"$name" will be removed from ${widget.tournament.name}.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _removing.add(a.id));
    try {
      await widget.service.bulkDeallocateTeams(
        tournamentIds: [widget.tournament.id],
        teamIds: [a.team],
      );
      _changed = true;
      await _reloadAllocated();
      _snack('$name removed.');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _removing.remove(a.id));
    }
  }

  // ───────────── helpers ─────────────

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 380,
        backgroundColor: error ? _C.danger : _C.success,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
  }

  Team? _teamById(int id) {
    for (final t in _allTeams) {
      if (t.id == id) return t;
    }
    return null;
  }

  String _nameFor(TournamentTeam a) =>
      a.teamName.isNotEmpty ? a.teamName : (_teamById(a.team)?.name ?? 'Team #${a.team}');

  String _shortFor(TournamentTeam a) =>
      a.teamShortName.isNotEmpty ? a.teamShortName : (_teamById(a.team)?.shortName ?? '');

  void _toggle(Team team) {
    if (_selected.contains(team.id)) {
      setState(() => _selected.remove(team.id));
      return;
    }
    final rem = _remaining;
    if (rem != null && _selected.length >= rem) {
      _snack(
        rem == 0
            ? 'This tournament is full (${_max} teams).'
            : 'Only $rem slot(s) left in this tournament.',
        error: true,
      );
      return;
    }
    setState(() => _selected.add(team.id));
  }

  List<Team> get _available {
    final q = _searchCtrl.text.trim().toLowerCase();
    final taken = _allocated.map((a) => a.team).toSet();
    return _allTeams.where((t) {
      if (taken.contains(t.id)) return false;
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) || t.shortName.toLowerCase().contains(q);
    }).toList();
  }

  void _selectAllVisible() {
    final visible = _available;
    final allSelected = visible.isNotEmpty && visible.every((t) => _selected.contains(t.id));
    setState(() {
      if (allSelected) {
        for (final t in visible) {
          _selected.remove(t.id);
        }
      } else {
        final rem = _remaining;
        for (final t in visible) {
          if (rem != null && _selected.length >= rem) break;
          _selected.add(t.id);
        }
      }
    });
  }

  void _close() => Navigator.pop(context, _changed);

  // ───────────── UI ─────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.card,
      child: Container(
        width: 500,
        height: double.infinity,
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: _C.border))),
        child: Column(
          children: [
            _header(),
            const Divider(height: 1, color: _C.border),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Expanded(child: _errorView())
            else ...[
              _capacityBar(),
              _tabs(),
              const Divider(height: 1, color: _C.border),
              Expanded(child: _tab == 0 ? _allocatedTab() : _addTab()),
              const Divider(height: 1, color: _C.border),
              _footer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.groups_outlined, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Teams',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.tournament.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            IconButton(
              onPressed: _saving ? null : _close,
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 34, color: _C.danger),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.danger, fontSize: 13)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _capacityBar() {
    final max = _max;
    final count = _allocated.length;
    final full = max != null && count >= max;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                max != null ? '$count of $max teams allocated' : '$count teams allocated',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (full)
                const Text('Full',
                    style: TextStyle(
                        color: _C.warning, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          if (max != null && max > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (count / max).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: _C.field,
                color: full ? _C.warning : AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabs() {
    Widget tab(int index, String label, int badge) {
      final active = _tab == index;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: active ? AppColors.primary : Colors.transparent, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.textPrimary : AppColors.textSecondary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary.withValues(alpha: 0.18) : _C.field,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$badge',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.primary : AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          tab(0, 'Allocated', _allocated.length),
          tab(1, 'Add teams', _available.length),
        ],
      ),
    );
  }

  // ── Allocated tab ──

  Widget _allocatedTab() {
    if (_allocated.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.groups_outlined, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              const Text('No teams allocated yet',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Add teams to start building this tournament.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => setState(() => _tab = 1),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add teams'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _allocated.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = _allocated[i];
        final busy = _removing.contains(a.id);
        final short = _shortFor(a);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _C.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              _TeamAvatar(label: short.isNotEmpty ? short : _nameFor(a),
              logoUrl:a.teamLogo,
              ),
              
              
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameFor(a),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (short.isNotEmpty)
                          Text(short,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        if (a.groupName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(a.groupName,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              busy
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Tooltip(
                      message: 'Remove from tournament',
                      child: IconButton(
                        onPressed: () => _remove(a),
                        icon: const Icon(Icons.delete_outline, size: 19, color: _C.danger),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ── Add tab ──

  Widget _addTab() {
    final teams = _available;
    final rem = _remaining;
    final full = rem != null && rem == 0;
    final allSelected = teams.isNotEmpty && teams.every((t) => _selected.contains(t.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search teams...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                      onPressed: () => setState(_searchCtrl.clear),
                    ),
              filled: true,
              fillColor: _C.field,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Text(
                '${_selected.length} selected'
                '${rem != null ? ' · $rem slot(s) left' : ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const Spacer(),
              if (teams.isNotEmpty && !full)
                TextButton(
                  onPressed: _selectAllVisible,
                  child: Text(allSelected ? 'Clear all' : 'Select all',
                      style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ),
        Expanded(
          child: teams.isEmpty
              ? Center(
                  child: Text(
                    _searchCtrl.text.isNotEmpty
                        ? 'No teams match your search.'
                        : 'All active teams are already allocated.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  itemCount: teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final team = teams[i];
                    final selected = _selected.contains(team.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _toggle(team),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : _C.field,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected ? AppColors.primary : _C.border),
                        ),
                        child: Row(
                          children: [
                            _TeamAvatar(
                                label: team.shortName.isNotEmpty ? team.shortName : team.name,
                                logoUrl: team.logo,
                                
                                ),
                              
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(team.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(team.shortName,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(
                              selected ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 21,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Footer ──

  Widget _footer() {
    if (_tab == 0) {
      return Padding(
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
                onPressed: _close,
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _tab = 1),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add teams', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _groupCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Group name (optional), e.g. Group A',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.label_outline, size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: _C.field,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _C.border),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saving ? null : () => setState(() => _tab = 0),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (_saving || _selected.isEmpty) ? null : _allocateSelected,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _selected.isEmpty
                              ? 'Select teams to allocate'
                              : 'Allocate ${_selected.length} team(s)',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final initials = text.isEmpty
        ? '?'
        : (text.length <= 3 ? text : text.substring(0, 2)).toUpperCase();

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

class _SimpleDialog extends StatelessWidget {
  const _SimpleDialog({
    required this.title,
    required this.children,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _C.border),
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onConfirm,
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _SimpleTextField extends StatelessWidget {
  const _SimpleTextField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: _C.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.border)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.2)),
      ),
    );
  }
}