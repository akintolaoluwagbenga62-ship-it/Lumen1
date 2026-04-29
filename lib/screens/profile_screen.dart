import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import 'paywall_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final xp = user.xp;
    final level = user.calcLevel;
    final nextLevelXp = level * level * 100;
    final xpProgress = xp / nextLevelXp;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        actions: [
          if (user.isAdmin)
            IconButton(icon: Icon(Icons.admin_panel_settings, color: context.goldColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
          IconButton(icon: Icon(Icons.logout_outlined, color: context.textMuted), onPressed: () => _confirmLogout(context, state)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: ListView(
        children: [
          // Profile Header
          Container(
            color: context.bg1,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(state.avatarUrl(user, size: 80)),
                ),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: context.accent, shape: BoxShape.circle, border: Border.all(color: context.bg1, width: 2)),
                  child: Icon(Icons.edit, size: 12, color: context.isDark ? Colors.black : Colors.white),
                ),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(user.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: context.textColor)),
                if (user.isAdmin) ...[const SizedBox(width: 6), Icon(Icons.workspace_premium, color: context.goldColor, size: 18)],
                if (user.verified && !user.isAdmin) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 18)],
              ]),
              const SizedBox(height: 4),
              Text(user.email, style: TextStyle(fontSize: 13, color: context.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isActivated ? context.successColor.withOpacity(0.1) : context.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: state.isActivated ? context.successColor.withOpacity(0.2) : context.dangerColor.withOpacity(0.2)),
                ),
                child: Text(state.subscriptionLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: state.isActivated ? context.successColor : context.dangerColor)),
              ),
            ]),
          ),

          // Stats
          Container(
            color: context.bg1,
            margin: const EdgeInsets.only(top: 8),
            child: Row(children: [
              _statItem(context, user.testsTaken.toString(), 'Tests'),
              _statItem(context, '${user.scores.isEmpty ? 0 : (user.scores.reduce((a, b) => a + b) / user.scores.length).round()}%', 'Avg Score'),
              _statItem(context, '$level', 'Level'),
              _statItem(context, '$xp', 'XP'),
            ]),
          ),

          // XP Bar
          Container(
            color: context.bg1,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Level $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted)),
                Text('$xp / $nextLevelXp XP', style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress.clamp(0.0, 1.0),
                  backgroundColor: context.bg3,
                  valueColor: AlwaysStoppedAnimation<Color>(context.accent),
                  minHeight: 6,
                ),
              ),
            ]),
          ),

          // Info Cards
          const SizedBox(height: 8),
          _infoCard(context, Icons.school_outlined, 'Primary Subject', user.course1),
          _infoCard(context, Icons.account_balance_outlined, 'Target School', user.choice1),

          // Actions
          const SizedBox(height: 8),
          if (!state.isActivated || state.isOnTrial)
            _actionTile(context, Icons.bolt, 'Upgrade Plan', 'Unlock full access', context.goldColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()))),
          _actionTile(context, Icons.dark_mode_outlined, state.darkMode ? 'Light Mode' : 'Dark Mode', 'Switch app theme', context.accent, state.toggleTheme),
          _actionTile(context, Icons.info_outline, 'About Lumen', 'Study. Focus. Pass JAMB.', context.textMuted, () => _showAbout(context)),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, state),
              style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: context.glassBorder))),
      child: Column(children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        const SizedBox(height: 2),
        Text(lbl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textMuted)),
      ]),
    ),
  );

  Widget _infoCard(BuildContext context, IconData icon, String label, String value) => Container(
    color: context.bg1,
    margin: const EdgeInsets.only(bottom: 1),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 18, color: context.textMuted),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textColor)),
      ]),
    ]),
  );

  Widget _actionTile(BuildContext context, IconData icon, String title, String sub, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      color: context.bg1,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textColor)),
          Text(sub, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ])),
        Icon(Icons.chevron_right, color: context.textMuted, size: 18),
      ]),
    ),
  );

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: context.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
      content: Text('Are you sure you want to sign out?', style: TextStyle(color: context.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); state.logout(); },
          style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor, foregroundColor: Colors.white, elevation: 0),
          child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  void _showAbout(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: context.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('About Lumen', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
      content: Text('Lumen v1.0\n\nStudy together. Focus. Pass JAMB.\n\nBuild with Flutter.', style: TextStyle(color: context.textSecondary, height: 1.6)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: context.accent, fontWeight: FontWeight.w700)))],
    ));
  }
}
