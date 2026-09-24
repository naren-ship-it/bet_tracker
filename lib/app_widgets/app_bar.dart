import 'dart:async';
import 'package:bet_tracker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onProfileTap,
    this.onLogoutTap,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          // Draggable title area
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 15,
                      color: AppColors.background,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'bet_tracker',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _DateTimeDisplay(),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border.withOpacity(0.5),
          ),
          const _NotificationIcon(),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          _ProfileChip(
            onProfileTap: onProfileTap,
            onLogoutTap: onLogoutTap,
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 20,
            color: AppColors.border.withOpacity(0.5),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

// ── Live date/time ────────────────────────────────────────────────────────────

class _DateTimeDisplay extends StatefulWidget {
  const _DateTimeDisplay();

  @override
  State<_DateTimeDisplay> createState() => _DateTimeDisplayState();
}

class _DateTimeDisplayState extends State<_DateTimeDisplay> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update every second; drop to Duration(minutes: 1) if you don't need seconds.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _dateText {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  String get _timeText {
    final hour24 = _now.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          _dateText,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 1,
          height: 12,
          color: AppColors.border.withOpacity(0.5),
        ),
        const SizedBox(width: 10),
        Text(
          _timeText,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Notification icon with badge ─────────────────────────────────────────────

class _NotificationIcon extends StatefulWidget {
  const _NotificationIcon();

  @override
  State<_NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<_NotificationIcon> {
  bool _hovering = false;

  // TODO: wire to real unread state
  final bool _hasUnread = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () {
          // TODO: hook up notifications action
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovering ? AppColors.surfaceHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 17,
                color: _hovering
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              if (_hasUnread)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile chip with dropdown menu ──────────────────────────────────────────

class _ProfileChip extends StatefulWidget {
  const _ProfileChip({this.onProfileTap, this.onLogoutTap});

  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _hovering = false;
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-20, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.surfaceHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        _MenuItem(
          icon: Icons.person_outline,
          label: 'Profile view',
          onTap: () {
            _menuController.close();
            widget.onProfileTap?.call();
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          height: 1,
          color: AppColors.border.withOpacity(0.5),
        ),
        _MenuItem(
          icon: Icons.logout,
          label: 'Logout',
          iconColor: AppColors.error,
          textColor: AppColors.error,
          onTap: () {
            _menuController.close();
            widget.onLogoutTap?.call();
          },
        ),
      ],
      builder: (context, controller, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () {
              controller.isOpen ? controller.close() : controller.open();
            },
            child: Container(
              height: 30,
              padding: const EdgeInsets.only(left: 4, right: 8),
              decoration: BoxDecoration(
                color: (_hovering || controller.isOpen)
                    ? AppColors.surfaceHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.secondary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'TV',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tamil Vanan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    controller.isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: (_hovering || controller.isOpen)
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.surfaceHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor ?? AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Window buttons ────────────────────────────────────────────────────────────

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: Icons.crop_square,
          iconSize: 13,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icons.close,
          hoverColor: AppColors.error,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.iconSize = 16,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final double iconSize;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovering
        ? (widget.hoverColor ?? AppColors.surfaceHigh)
        : Colors.transparent;
    final iconColor = _hovering && widget.hoverColor != null
        ? AppColors.background
        : AppColors.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 44,
          color: bg,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
        ),
      ),
    );
  }
}