import 'package:flutter/material.dart';

enum NotifType { success, error, warning, info }

class NotificationHelper {
  static void show(
    BuildContext context,
    String message, {
    NotifType type = NotifType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _config(type);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotifToast(
        title: title ?? config.defaultTitle,
        message: message,
        icon: config.icon,
        color: config.color,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message, type: NotifType.success, title: title);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message, type: NotifType.error, title: title, duration: const Duration(seconds: 4));

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message, type: NotifType.warning, title: title);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message, type: NotifType.info, title: title);

  static _NotifConfig _config(NotifType type) {
    switch (type) {
      case NotifType.success:
        return _NotifConfig('Berhasil', Icons.check_circle_rounded, const Color(0xFF16A34A));
      case NotifType.error:
        return _NotifConfig('Terjadi Kesalahan', Icons.error_rounded, const Color(0xFFDC2626));
      case NotifType.warning:
        return _NotifConfig('Perhatian', Icons.warning_rounded, const Color(0xFFD97706));
      case NotifType.info:
        return _NotifConfig('Info', Icons.info_rounded, const Color(0xFF1E88E5));
    }
  }
}

class _NotifConfig {
  final String defaultTitle;
  final IconData icon;
  final Color color;
  const _NotifConfig(this.defaultTitle, this.icon, this.color);
}

class _NotifToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDismiss;

  const _NotifToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_NotifToast> createState() => _NotifToastState();
}

class _NotifToastState extends State<_NotifToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
