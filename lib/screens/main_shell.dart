import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import 'groups_screen.dart';
import 'cbt_screen.dart';
import 'flashcards_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final List<Widget> _screens = const [
    GroupsScreen(),
    CBTScreen(),
    FlashcardsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.bg1,
          border: Border(top: BorderSide(color: context.glassBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _navItem(0, Icons.people_outline, Icons.people, 'Groups'),
                _navItem(1, Icons.quiz_outlined, Icons.quiz, 'CBT'),
                _navItem(2, Icons.style_outlined, Icons.style, 'Cards'),
                _notifItem(state),
                _navItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final active = _tab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon,
              color: active ? context.accent : context.textMuted, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? context.accent : context.textMuted,
            )),
          ],
        ),
      ),
    );
  }

  Widget _notifItem(AppState state) {
    final count = state.unreadNotifCount;
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_outlined, color: context.textMuted, size: 22),
                const SizedBox(height: 2),
                Text('Alerts', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: context.textMuted)),
              ],
            ),
            if (count > 0)
              Positioned(
                top: 8, right: 14,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: context.dangerColor, shape: BoxShape.circle),
                  child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
