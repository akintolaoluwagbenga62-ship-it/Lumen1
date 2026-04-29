import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import 'group_chat_screen.dart';
import 'paywall_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final mine = state.groups.where((g) => g.isDefault || g.members.contains(user.email) || g.admins.contains(user.email)).toList();
    final others = state.groups.where((g) => !g.isDefault && !g.members.contains(user.email) && !g.admins.contains(user.email)).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        title: Text('Study Groups', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.accent),
            onPressed: () => _showCreateGroup(context, state),
          ),
          IconButton(
            icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: context.textMuted),
            onPressed: state.toggleTheme,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.glassBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.accentDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.glassBorder),
            ),
            child: Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: context.accent),
              const SizedBox(width: 8),
              Expanded(child: Text('Groups are study-only. Posts must be academic.', style: TextStyle(fontSize: 12, color: context.textSecondary))),
            ]),
          ),
          const SizedBox(height: 16),
          if (mine.isNotEmpty) ...[
            Text('Your Groups', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.07)),
            const SizedBox(height: 8),
            ...mine.map((g) => _GroupCard(group: g, isMember: true)),
          ],
          if (others.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Discover', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.07)),
            const SizedBox(height: 8),
            ...others.map((g) => _GroupCard(group: g, isMember: false)),
          ],
        ],
      ),
    );
  }

  void _showCreateGroup(BuildContext context, AppState state) {
    if (!state.isActivated && state.trialDaysLeft == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    final nameC = TextEditingController();
    final descC = TextEditingController();
    String selectedIcon = '📚';
    String selectedColor = '#7c3aed';

    final icons = ['📚', '🎯', '⚗', '∑', '⚔', '🔬', '📝', '💡', '🌍', '📐'];
    final colors = ['#7c3aed', '#2563eb', '#059669', '#dc2626', '#d97706', '#0891b2', '#7c3aed'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Create Study Group', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
              const SizedBox(height: 16),
              TextField(controller: nameC, decoration: InputDecoration(hintText: 'Group name', hintStyle: TextStyle(color: context.textMuted))),
              const SizedBox(height: 12),
              TextField(controller: descC, decoration: InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: context.textMuted))),
              const SizedBox(height: 12),
              Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: icons.map((ic) => GestureDetector(
                  onTap: () => setModalState(() => selectedIcon = ic),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: selectedIcon == ic ? context.accentDim : context.bg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedIcon == ic ? context.accent : context.glassBorder),
                    ),
                    child: Center(child: Text(ic, style: const TextStyle(fontSize: 18))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameC.text.trim().isEmpty) return;
                    state.createGroup(nameC.text.trim(), descC.text.trim(), selectedIcon, selectedColor);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: context.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  final bool isMember;
  const _GroupCard({required this.group, required this.isMember});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final user = state.currentUser!;
    final msgs = (state.groupMessages[group.id] ?? []).length;
    final memberCount = group.isDefault ? state.allUsers.length : group.members.length;
    final unread = state.unreadCount(group.id);
    final isAdmin = group.admins.contains(user.email) || user.isAdmin;

    return GestureDetector(
      onTap: () {
        if (!state.isActivated && state.trialDaysLeft == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
          return;
        }
        if (group.banned.contains(user.email)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are banned from this group')));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: group.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _parseColor(group.color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _parseColor(group.color).withOpacity(0.2)),
              ),
              child: Center(child: Text(group.icon, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(group.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textColor)),
                    if (isAdmin) ...[const SizedBox(width: 4), Icon(Icons.workspace_premium, color: const Color(0xFFF59E0B), size: 14)],
                  ]),
                  Text('$msgs messages · $memberCount members', style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: context.accent, borderRadius: BorderRadius.circular(20)),
                child: Text('$unread', style: TextStyle(color: context.isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              )
            else if (!isMember)
              TextButton(
                onPressed: () {
                  if (!state.isActivated && state.trialDaysLeft == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                    return;
                  }
                  state.joinGroup(group.id);
                },
                style: TextButton.styleFrom(
                  backgroundColor: context.accentDim,
                  foregroundColor: context.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              )
            else
              Icon(Icons.chevron_right, color: context.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C3AED);
    }
  }
}
