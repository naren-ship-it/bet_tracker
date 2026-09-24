import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

enum AppModule {
  home,
  tournamentManagement,
  teamManagement,
  playerManagement,
  tournamentBetting,
  settings,
}

class CustomAppFooter extends StatelessWidget {
  const CustomAppFooter({
    super.key,
    required this.currentModule,
    required this.onModuleSelected,
  });

  final AppModule currentModule;
  final ValueChanged<AppModule> onModuleSelected;

  static const _items = [
    _FooterItemData(
      module: AppModule.home,
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard,
      label: 'Home',
    ),
    _FooterItemData(
      module: AppModule.tournamentManagement,
      icon: Icons.workspace_premium_rounded,
      activeIcon: Icons.workspace_premium,
      label: 'Tournament',
    ),
    _FooterItemData(
      module: AppModule.teamManagement,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: 'Teams',
    ),
    _FooterItemData(
      module: AppModule.playerManagement,
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge,
      label: 'Players',
    ),
    _FooterItemData(
      module: AppModule.tournamentBetting,
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Betting',
    ),
    _FooterItemData(
      module: AppModule.settings,
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow.withOpacity(0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((item) {
              final isActive = item.module == currentModule;
              return _FooterItem(
                data: item,
                isActive: isActive,
                onTap: () => onModuleSelected(item.module),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _FooterItemData {
  const _FooterItemData({
    required this.module,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final AppModule module;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _FooterItem extends StatefulWidget {
  const _FooterItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final _FooterItemData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_FooterItem> createState() => _FooterItemState();
}

class _FooterItemState extends State<_FooterItem> {
  bool _hovering = false;

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isActive
        ? AppColors.primary
        : (_hovering ? AppColors.textPrimary : AppColors.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _hovering ? 1.08 : 1.0,
          duration: _duration,
          curve: _curve,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.primary.withOpacity(0.14)
                  : (_hovering
                  ? AppColors.surfaceHigh
                  : Colors.transparent),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: _duration,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: Icon(
                          widget.isActive
                              ? widget.data.activeIcon
                              : widget.data.icon,
                          key: ValueKey(widget.isActive),
                          size: 26,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  curve: _curve,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: iconColor,
                  ),
                  child: Text(
                    widget.data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}