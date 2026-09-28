// lib/screens/player_management_screen.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:bet_tracker/app_widgets/app_snackbar.dart';
import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:bet_tracker/models/player.dart';
import 'package:bet_tracker/models/player_choice.dart';
import 'package:bet_tracker/providers/player_providers.dart';

// ── Matches teammate's _C token class exactly ──────────────────────────────
class _C {
  static const card    = Color(0xFF111827);
  static const field   = Color(0xFF0B1220);
  static const border  = Color(0xFF1F2A44);
  static const hover   = Color(0xFF162036);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
}

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  int _currentPage = 1;
  // Fix 3: page size is now mutable state, not a top-level const
  int _pageSize = 10;
  final ScrollController _scrollCtrl = ScrollController();

  int? _filterRole;
  int? _filterBatting;
  int? _filterBowling;
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<PlayerProvider>();
    await Future.wait([provider.fetchPlayers(), provider.fetchChoices()]);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
    }
  }

  List<Player> _filtered(List<Player> all, List<PlayerChoice> roles ,List<PlayerChoice> battingStyles, List<PlayerChoice> bowlingStyles) {
    var list = all.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.fullName.toLowerCase().contains(q) &&
            !p.country.toLowerCase().contains(q) &&
            !p.roleName(roles).toLowerCase().contains(q) &&
            !p.battingName(battingStyles).toLowerCase().contains(q) &&  // add
            !p.bowlingName(bowlingStyles).toLowerCase().contains(q))     // add
          return false;
      }
      if (_statusFilter == 'Active' && !p.isActive) return false;
      if (_statusFilter == 'Inactive' && p.isActive) return false;
      if (_filterRole != null && p.role != _filterRole) return false;
      if (_filterBatting != null && p.battingStyle != _filterBatting) return false;
      if (_filterBowling != null && p.bowlingStyle != _filterBowling) return false;
      return true;
    }).toList();
    list.sort((a, b) => _ascending
        ? a.fullName.compareTo(b.fullName)
        : b.fullName.compareTo(a.fullName));
    return list;
  }

  void _resetFilters() {
    setState(() {
      _filterRole = null;
      _filterBatting = null;
      _filterBowling = null;
      _ascending = true;
      _currentPage = 1;
    });
  }

  bool get _hasFilters =>
      _filterRole != null || _filterBatting != null || _filterBowling != null;

  void _openForm({Player? player}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      // ── matches teammate's 260 ms ──
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: _PlayerFormDrawer(
          existing: player,
          onSaved: (p, photo) async {
            final provider = context.read<PlayerProvider>();
            final bool success;
            if (player?.id != null) {
              success = await provider.updatePlayer(player!.id!, p, photo: photo);
            } else {
              success = await provider.createPlayer(p, photo: photo);
            }
            if (!mounted) return;
            if (success) {
              Navigator.pop(context);
              // Fix 2: re-fetch so the list always reflects the latest server state
              _load();
              AppSnackbar.success(
                  context, player == null ? 'Player added.' : 'Player updated.');
            } else if (provider.errorMessage != null) {
              AppSnackbar.error(context, provider.errorMessage!);
              provider.clearError();
            }
          },
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Future<void> _deletePlayer(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // ── matches teammate's dialog style ──
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _C.border),
        ),
        title: const Text('Remove Player',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: SizedBox(
          width: 380,
          child: Text(
            'Remove "$name" from the system? This action cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          // ── FilledButton like teammate's Delete ──
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<PlayerProvider>();
    final success = await provider.deletePlayer(id);
    if (!mounted) return;
    if (success) {
      AppSnackbar.success(context, '$name removed.');
    } else if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final all = provider.players;
          final filtered = _filtered(all, provider.roles, provider.battingStyles, provider.bowlingStyles);
          final active = all.where((p) => p.isActive).length;
          final inactive = all.length - active;
          final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
          if (_currentPage > totalPages) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => setState(() => _currentPage = 1));
          }
          final pageStart = (_currentPage - 1) * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, filtered.length);
          final pagePlayers =
              filtered.isEmpty ? <Player>[] : filtered.sublist(pageStart, pageEnd);

          // ── Outer padding matches teammate's Padding(all: 24) ──
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStats(all.length, active, inactive, provider.isLoading),
                const SizedBox(height: 20),
                // ── Bordered card wrapping toolbar + table + footer ──
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
                        _buildToolbar(provider),
                        const Divider(height: 1, color: _C.border),
                        Expanded(
                            child: _buildBody(
                                provider, all, filtered, pagePlayers)),
                        const Divider(height: 1, color: _C.border),
                        _buildFooter(pageStart, pageEnd, filtered.length,
                            totalPages),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header: icon 44×44 size 24, title 22, subtitle 13, FilledButton ──
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
          child: const Icon(Icons.badge_outlined,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player Management',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Manage players, roles and stats.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const Spacer(),
        // ── FilledButton.icon matching teammate exactly ──
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Player',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ── Stat cards: card bg, border, padding 18, icon 42×42, label 12.5, value 24 ──
  Widget _buildStats(int total, int active, int inactive, bool loading) {
    if (loading) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Total Players',
                value: total,
                icon: Icons.people_outline,
                color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Active',
                value: active,
                icon: Icons.check_circle_outline,
                color: _C.success)),
        const SizedBox(width: 16),
        Expanded(
            child: _StatCard(
                label: 'Inactive',
                value: inactive,
                icon: Icons.pause_circle_outline,
                color: _C.warning)),
      ],
    );
  }

  // ── Toolbar: search field, segmented filter, filter/sort/refresh IconButtons ──
  Widget _buildToolbar(PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search — width 340 matching teammate
          SizedBox(
            width: 340,
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _searchQuery = v.trim();
                _currentPage = 1;
              }),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search by player, role, country...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.textSecondary),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
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

          // ── Segmented pill filter matching teammate's _SegmentedFilter ──
          _SegmentedStatusFilter(
            value: _statusFilter,
            onChanged: (s) => setState(() {
              _statusFilter = s;
              _currentPage = 1;
            }),
          ),
          const SizedBox(width: 14),

          // Filter button — plain Tooltip+IconButton like teammate's refresh
          Tooltip(
            message: 'Filters',
            child: IconButton(
              onPressed: () => _showFilterPanel(context, provider),
              icon: Icon(Icons.tune,
                  size: 20,
                  color: _hasFilters
                      ? AppColors.primary
                      : AppColors.textSecondary),
            ),
          ),

          // Sort toggle
          Tooltip(
            message: _ascending ? 'Sort A→Z' : 'Sort Z→A',
            child: IconButton(
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                  color: AppColors.textSecondary),
            ),
          ),

          const Spacer(),

          // Refresh — matches teammate exactly
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh,
                  size: 20, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: loading spinner, empty state, no-match message, table ──
  Widget _buildBody(PlayerProvider provider, List<Player> all,
      List<Player> filtered, List<Player> pagePlayers) {
    if (provider.isLoading && all.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary),
        ),
      );
    }
    if (all.isEmpty) {
      return _MessageState(
        icon: Icons.badge_outlined,
        color: AppColors.primary,
        title: 'No Players Yet',
        subtitle: 'Add your first player to get started.',
        actionLabel: 'Add Player',
        onAction: () => _openForm(),
      );
    }
    if (filtered.isEmpty) {
      return _MessageState(
        icon: Icons.search_off,
        color: AppColors.primary,
        title: 'No matching players',
        subtitle: 'Try a different search term or clear the filters.',
        actionLabel: 'Clear filters',
        onAction: () {
          _searchCtrl.clear();
          setState(() {
            _searchQuery = '';
            _statusFilter = 'All';
            _filterRole = null;
            _filterBatting = null;
            _filterBowling = null;
            _currentPage = 1;
          });
        },
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final w = math.max(c.maxWidth, 900.0);
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
                      controller: _scrollCtrl,
                      itemCount: pagePlayers.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: _C.border),
                      itemBuilder: (_, i) => _PlayerRow(
                        player: pagePlayers[i],
                        roles: provider.roles,
                        battingStyles: provider.battingStyles,
                        bowlingStyles: provider.bowlingStyles,
                        onEdit: () => _openForm(player: pagePlayers[i]),
                        onDelete: () => _deletePlayer(
                            pagePlayers[i].id!, pagePlayers[i].fullName),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                  minHeight: 2, color: AppColors.primary),
            ),
        ],
      );
    });
  }

  // ── Footer: page size selector + count label + page buttons ──
  Widget _buildFooter(int pageStart, int pageEnd, int total, int totalPages) {
    final from = total == 0 ? 0 : pageStart + 1;
    final to = math.min(pageStart + _pageSize, total);

    var winStart = math.max(1, _currentPage - 2);
    final winEnd = math.min(totalPages, winStart + 4);
    winStart = math.max(1, winEnd - 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Fix 3: rows-per-page selector ──────────────────────────────
          const Text('Rows per page:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _C.field,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _pageSize,
                isDense: true,
                dropdownColor: _C.card,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12.5),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.textSecondary),
                items: [10, 25, 50].map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('$n'),
                    )).toList(),
                onChanged: (n) {
                  if (n == null) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 1;
                  });
                  _scrollCtrl.jumpTo(0);
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          // ── Count label ────────────────────────────────────────────────
          Text('Showing $from–$to of $total players',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5)),
          const Spacer(),
          // ── Page buttons ───────────────────────────────────────────────
          _PageButton(
            icon: Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () => setState(() {
              _currentPage--;
              _scrollCtrl.jumpTo(0);
            }),
          ),
          for (var p = winStart; p <= winEnd; p++)
            _PageButton(
              label: '$p',
              selected: p == _currentPage,
              onTap: () => setState(() {
                _currentPage = p;
                _scrollCtrl.jumpTo(0);
              }),
            ),
          _PageButton(
            icon: Icons.chevron_right,
            enabled: _currentPage < totalPages,
            onTap: () => setState(() {
              _currentPage++;
              _scrollCtrl.jumpTo(0);
            }),
          ),
        ],
      ),
    );
  }

  void _showFilterPanel(BuildContext context, PlayerProvider provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          height: double.infinity,
          child: _FilterSheet(
            roles: provider.roles,
            battingStyles: provider.battingStyles,
            bowlingStyles: provider.bowlingStyles,
            roleId: _filterRole,
            battingId: _filterBatting,
            bowlingId: _filterBowling,
            ascending: _ascending,
            onApply: (role, bat, bowl, asc) {
              Navigator.pop(context);
              setState(() {
                _filterRole = role;
                _filterBatting = bat;
                _filterBowling = bowl;
                _ascending = asc;
                _currentPage = 1;
              });
            },
            onReset: () {
              Navigator.pop(context);
              _resetFilters();
            },
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

// ─── SEGMENTED STATUS FILTER ─────────────────────────────────────────────────
// Matches teammate's _SegmentedFilter pill exactly

class _SegmentedStatusFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SegmentedStatusFilter(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
        children: ['All', 'Active', 'Inactive'].map((s) {
          final selected = value == s;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────
// Matches teammate's _StatCard: card bg, border, padding 18, icon 42×42 r:11,
// label 12.5, value 24

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text('$value',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────
// Matches teammate: field bg, px:20 py:12, no rounded corners, letterSpacing 0.8

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
          // avatar space — 38px matches _PlayerAvatar width
          const SizedBox(width: 38),
          const SizedBox(width: 12),
          h('Player', 30),
          h('Role', 15),
          h('Batting', 15),
          h('Bowling', 15),
          h('Country', 15),
          h('Jersey', 10),
          // actions space
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

// ─── TABLE ROW ────────────────────────────────────────────────────────────────
// Matches teammate: StatefulWidget, hover color _C.hover, Divider separator,
// px:20 py:12, _IconAction buttons, _StatusChip

class _PlayerRow extends StatefulWidget {
  final Player player;
  final List<PlayerChoice> roles;
  final List<PlayerChoice> battingStyles;
  final List<PlayerChoice> bowlingStyles;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlayerRow({
    required this.player,
    required this.roles,
    required this.battingStyles,
    required this.bowlingStyles,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow> {
  bool _hover = false;

  Widget _cell(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          text.isEmpty ? '—' : text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: text.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textSecondary,
              fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hover ? _C.hover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar — rounded rect matching teammate's team avatar style
            _PlayerAvatar(player: p),
            const SizedBox(width: 12),
            // Name + status chip
            Expanded(
              flex: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  _StatusChip(active: p.isActive),
                ],
              ),
            ),
            _cell(p.roleName(widget.roles), flex: 15),
            _cell(p.battingName(widget.battingStyles), flex: 15),
            _cell(p.bowlingName(widget.bowlingStyles), flex: 15),
            _cell(p.country, flex: 15),
            Expanded(
              flex: 10,
              child: Text('#${p.jerseyNumber}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            // Actions — matches teammate's _IconAction
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

// ─── PLAYER AVATAR ────────────────────────────────────────────────────────────
// Rounded rect matching teammate's _TeamAvatar style

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    final initials = player.firstName.isNotEmpty
        ? player.firstName[0].toUpperCase()
        : '?';

    final fallback = Center(
      child: Text(initials,
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );

    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: player.photoUrl != null
          ? Image.network(
              player.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}

// ─── STATUS CHIP ──────────────────────────────────────────────────────────────
// Matches teammate's _StatusChip exactly

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? _C.success : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(active ? 'Active' : 'Inactive',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── ICON ACTION ──────────────────────────────────────────────────────────────
// Matches teammate's _IconAction exactly

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

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

// ─── PAGE BUTTON ──────────────────────────────────────────────────────────────
// Matches teammate's _PageButton exactly: 34×34, InkWell, border

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
  });

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
            border:
                Border.all(color: selected ? AppColors.primary : _C.border),
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
                      color:
                          selected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

// ─── MESSAGE STATE ────────────────────────────────────────────────────────────
// Matches teammate's _MessageState exactly

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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _C.border),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ─── FILTER SHEET ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<PlayerChoice> roles;
  final List<PlayerChoice> battingStyles;
  final List<PlayerChoice> bowlingStyles;
  final int? roleId;
  final int? battingId;
  final int? bowlingId;
  final bool ascending;
  final Function(int?, int?, int?, bool) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.roles,
    required this.battingStyles,
    required this.bowlingStyles,
    this.roleId,
    this.battingId,
    this.bowlingId,
    required this.ascending,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _role;
  late int? _batting;
  late int? _bowling;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _role = widget.roleId;
    _batting = widget.battingId;
    _bowling = widget.bowlingId;
    _ascending = widget.ascending;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.card,
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _C.border)),
        ),
        child: Column(
          children: [
            // Header matches teammate's form panel header style
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filters',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Narrow down the player list.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onReset,
                    child: const Text('Reset all',
                        style: TextStyle(color: _C.danger)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _C.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  _section('Sort Order'),
                  Row(
                    children: [
                      _chip('A → Z', Icons.arrow_upward, _ascending,
                          () => setState(() => _ascending = true)),
                      const SizedBox(width: 10),
                      _chip('Z → A', Icons.arrow_downward, !_ascending,
                          () => setState(() => _ascending = false)),
                    ],
                  ),
                  _section('Role'),
                  _dropdown(
                      value: _role,
                      items: widget.roles,
                      onChanged: (v) => setState(() => _role = v)),
                  const SizedBox(height: 14),
                  _section('Batting Style'),
                  _dropdown(
                      value: _batting,
                      items: widget.battingStyles,
                      onChanged: (v) => setState(() => _batting = v)),
                  const SizedBox(height: 14),
                  _section('Bowling Style'),
                  _dropdown(
                      value: _bowling,
                      items: widget.bowlingStyles,
                      onChanged: (v) => setState(() => _bowling = v)),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        widget.onApply(_role, _batting, _bowling, _ascending),
                    child: const Text('Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section label matching teammate's _section()
  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600)),
      );

  Widget _chip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primary.withValues(alpha: 0.15) : _C.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.primary : _C.border, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 13,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required List<PlayerChoice> items,
    required ValueChanged<int?> onChanged,
  }) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c),
        );
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: _C.card,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Any',
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: _C.field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: b(_C.border),
        focusedBorder: b(AppColors.primary),
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Any')),
        ...items.map(
            (c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))),
      ],
      onChanged: onChanged,
    );
  }
}

// ─── PLAYER FORM DRAWER ───────────────────────────────────────────────────────
// Matches teammate's _TeamFormPanel: card bg, border left, section labels,
// _C.field inputs, FilledButton submit, OutlinedButton cancel

class _PlayerFormDrawer extends StatefulWidget {
  final Player? existing;
  final Future<void> Function(Player, File?) onSaved;

  const _PlayerFormDrawer({this.existing, required this.onSaved});

  @override
  State<_PlayerFormDrawer> createState() => _PlayerFormDrawerState();
}

class _PlayerFormDrawerState extends State<_PlayerFormDrawer> {
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _dob;
  late final TextEditingController _country;
  late final TextEditingController _jersey;

  int? _role;
  int? _battingStyle;
  int? _bowlingStyle;
  bool _isActive = true;
  bool _isSaving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _dob = TextEditingController(text: p?.dob ?? '');
    _country = TextEditingController(text: p?.country ?? '');
    _jersey = TextEditingController(
        text: p?.jerseyNumber != null ? p!.jerseyNumber.toString() : '');
    _isActive = p?.isActive ?? true;
    if (p != null) {
      _role = p.role;
      _battingStyle = p.battingStyle;
      _bowlingStyle = p.bowlingStyle;
    }
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PlayerProvider>().fetchChoices());
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dob.dispose();
    _country.dispose();
    _jersey.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null || _battingStyle == null || _bowlingStyle == null) {
      setState(() => _error = 'Please select role, batting and bowling style.');
      return;
    }
    setState(() { _isSaving = true; _error = null; });
    final player = Player(
      id: widget.existing?.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      dob: _dob.text.trim(),
      country: _country.text.trim(),
      role: _role,
      battingStyle: _battingStyle,
      bowlingStyle: _bowlingStyle,
      jerseyNumber: int.parse(_jersey.text.trim()),
      isActive: _isActive,
    );
    await widget.onSaved(player, _pickedImage);
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      _dob.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // Input decoration matching teammate's _dec()
  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon:
          icon == null ? null : Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: _C.field,
      enabledBorder: b(_C.border),
      focusedBorder: b(AppColors.primary),
      errorBorder: b(_C.danger),
      focusedErrorBorder: b(_C.danger),
    );
  }

  // Section label matching teammate's _section()
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
    final provider = context.watch<PlayerProvider>();

    if (provider.choicesLoaded) {
      _role ??= provider.roles.isNotEmpty ? provider.roles.first.id : null;
      _battingStyle ??= provider.battingStyles.isNotEmpty
          ? provider.battingStyles.first.id
          : null;
      _bowlingStyle ??= provider.bowlingStyles.isNotEmpty
          ? provider.bowlingStyles.first.id
          : null;
    }

    return Material(
      color: _C.card,
      child: Container(
        width: 460,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _C.border)),
        ),
        child: Column(
          children: [
            // ── Panel header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEdit ? 'Edit Player' : 'Add Player',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            _isEdit
                                ? 'Update the details of this player.'
                                : 'Fill in the details to create a new player.',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _C.border),

            // ── Form ──
            Expanded(
              child: !provider.choicesLoaded
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _section('Player Photo'),
                            // Photo picker
                            Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceHigh,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _C.border),
                                      ),
                                      child: _pickedImage != null
                                          ? Image.file(_pickedImage!,
                                              fit: BoxFit.cover)
                                          : widget.existing?.photoUrl != null
                                              ? Image.network(
                                                  widget.existing!.photoUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.person,
                                                          size: 36,
                                                          color: AppColors
                                                              .textSecondary),
                                                )
                                              : const Icon(Icons.person,
                                                  size: 36,
                                                  color:
                                                      AppColors.textSecondary),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _C.card, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt,
                                            size: 13, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            _section('Basic Information'),
                            TextFormField(
                              controller: _firstName,
                              style: style,
                              decoration: _dec('First Name *',
                                  icon: Icons.person_outline),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _lastName,
                              style: style,
                              decoration: _dec('Last Name *',
                                  icon: Icons.person_outline),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _country,
                              style: style,
                              decoration: _dec('Country',
                                  icon: Icons.flag_outlined),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _dob,
                              style: style,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: _dec('Date of Birth',
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.calendar_today_outlined),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _jersey,
                              style: style,
                              keyboardType: TextInputType.number,
                              decoration: _dec('Jersey Number',
                                  icon: Icons.tag),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Required';
                                if (int.tryParse(v.trim()) == null)
                                  return 'Must be a number';
                                return null;
                              },
                            ),

                            _section('Playing Details'),
                            _choiceDrop('Role', _role, provider.roles,
                                (v) => setState(() => _role = v)),
                            const SizedBox(height: 14),
                            _choiceDrop(
                                'Batting Style',
                                _battingStyle,
                                provider.battingStyles,
                                (v) => setState(() => _battingStyle = v)),
                            const SizedBox(height: 14),
                            _choiceDrop(
                                'Bowling Style',
                                _bowlingStyle,
                                provider.bowlingStyles,
                                (v) => setState(() => _bowlingStyle = v)),

                            _section('Status'),
                            // Fix 1: Material wraps SwitchListTile so ink
                            // splashes render correctly over the BoxDecoration.
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: _C.field,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _C.border),
                                ),
                                child: SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 0),
                                  activeColor: _C.success,
                                  value: _isActive,
                                  onChanged: (v) =>
                                      setState(() => _isActive = v),
                                  title: const Text('Active player',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14)),
                                  subtitle: const Text(
                                      'Inactive players are hidden from new selections.',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ),
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
                                  border: Border.all(
                                      color: _C.danger.withValues(alpha: 0.4)),
                                ),
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: _C.danger, fontSize: 13)),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),

            // ── Footer buttons ──
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isEdit ? 'Save Changes' : 'Create Player',
                              style: const TextStyle(
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

  Widget _choiceDrop(String label, int? value, List<PlayerChoice> choices,
      ValueChanged<int?> onChanged) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c),
        );
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: _C.card,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: _C.field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: b(_C.border),
        focusedBorder: b(AppColors.primary),
        errorBorder: b(_C.danger),
        focusedErrorBorder: b(_C.danger),
      ),
      items: choices
          .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}