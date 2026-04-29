import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/constants.dart';
import '../utils/theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pendingPayments = state.allUsers.where((u) => u.paymentPending != null).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Row
          Row(children: [
            _statCard(context, '${state.allUsers.length}', 'Users',
                Icons.people_outline, const Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            _statCard(context, '${state.groups.length}', 'Groups',
                Icons.group_work_outlined, const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            _statCard(context, '${pendingPayments.length}', 'Pending',
                Icons.payment_outlined, const Color(0xFFF59E0B)),
          ]),
          const SizedBox(height: 20),

          // Pending Payments
          if (pendingPayments.isNotEmpty) ...[
            Text('Pending Payments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.textColor)),
            const SizedBox(height: 10),
            ...pendingPayments.map((u) {
              final planId = u.paymentPending!['plan'] ?? 'monthly';
              final plan = plans.firstWhere((p) => p.id == planId, orElse: () => plans[0]);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.bg1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.goldColor.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                        backgroundImage: NetworkImage(state.avatarUrl(u)), radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: context.textColor)),
                      Text(u.email,
                          style: TextStyle(fontSize: 12, color: context.textMuted)),
                      Text('${plan.name} Plan — ₦${plan.price}',
                          style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      Text('Ref: ${u.paymentPending!['ref'] ?? '-'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                              fontStyle: FontStyle.italic)),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          state.activateUser(u.email, planId);
                          u.paymentPending = null;
                          state.saveAll();
                          state.addNotification(
                              'Your ${plan.name} plan has been activated! Enjoy full access.', u.email);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${u.name} activated!')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.successColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('✓ Activate', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          u.paymentPending = null;
                          state.saveAll();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment for ${u.name} rejected.')));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.dangerColor,
                          side: BorderSide(color: context.dangerColor.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('✗ Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ]),
              );
            }),
            const SizedBox(height: 16),
          ],

          // All Users
          Text('All Users (${state.allUsers.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.textColor)),
          const SizedBox(height: 10),
          ...state.allUsers.map((u) {
            final subLabel = u.isAdmin
                ? 'Admin'
                : (u.subscriptionExpiry != null &&
                        u.subscriptionExpiry! > DateTime.now().millisecondsSinceEpoch)
                    ? 'Active'
                    : 'Free';
            final subColor = u.isAdmin
                ? context.goldColor
                : subLabel == 'Active'
                    ? context.successColor
                    : context.textMuted;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.glassBorder),
              ),
              child: Row(children: [
                CircleAvatar(
                    backgroundImage: NetworkImage(state.avatarUrl(u, size: 36)), radius: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(u.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13, color: context.textColor)),
                    if (u.isAdmin) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.workspace_premium, color: context.goldColor, size: 13)
                    ],
                    if (u.verified && !u.isAdmin) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 13)
                    ],
                  ]),
                  Text(u.email, style: TextStyle(fontSize: 11, color: context.textMuted)),
                  Text('Tests: ${u.testsTaken} · XP: ${u.xp}',
                      style: TextStyle(fontSize: 11, color: context.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: subColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: subColor.withOpacity(0.2)),
                    ),
                    child: Text(subLabel,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700, color: subColor)),
                  ),
                  if (!u.isAdmin && !u.verified) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        state.verifyUser(u.email);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${u.name} verified!')));
                      },
                      child: Text('Verify',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                  if (!u.isAdmin) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showActivateDialog(context, state, u.email, u.name),
                      child: Text('Activate',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.successColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ]),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context, AppState state, String email, String name) {
    String selectedPlan = 'monthly';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Activate $name',
              style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: plans
                .map((p) => RadioListTile<String>(
                      value: p.id,
                      groupValue: selectedPlan,
                      onChanged: (v) => setDialogState(() => selectedPlan = v!),
                      title: Text('${p.name} (${p.days}d)',
                          style: TextStyle(fontWeight: FontWeight.w700, color: context.textColor)),
                      subtitle:
                          Text('₦${p.price}', style: TextStyle(color: context.textMuted)),
                      activeColor: context.accent,
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: context.textMuted))),
            ElevatedButton(
              onPressed: () {
                state.activateUser(email, selectedPlan);
                state.addNotification(
                    'Your account has been activated by admin. Enjoy full access!', email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$name activated!')));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: context.isDark ? Colors.black : Colors.white,
                  elevation: 0),
              child: const Text('Activate', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      BuildContext context, String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 22, color: context.textColor)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: context.textMuted, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
