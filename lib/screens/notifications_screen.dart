// ── NOTIFICATIONS SCREEN ─────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark notifications read once after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markAllNotifsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }
    final notifs = state.notifications
        .where((n) => n.user == user.email || user.isAdmin)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.textColor), onPressed: () => Navigator.pop(context)),
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: notifs.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_none, size: 40, color: context.textMuted.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('No notifications yet.', style: TextStyle(color: context.textMuted)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (ctx, i) {
                final n = notifs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.read ? context.bg1 : context.accentDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: n.read ? context.glassBorder : context.accent),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: context.bg3, shape: BoxShape.circle),
                      child: Icon(Icons.notifications_outlined, color: context.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.msg,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textColor,
                              fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        Text(n.time, style: TextStyle(fontSize: 11, color: context.textMuted)),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
