// ── PAYWALL SCREEN ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/constants.dart';
import '../utils/theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'term';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(icon: Icon(Icons.close, color: context.textColor), onPressed: () => Navigator.pop(context)),
        title: Text('Activate Lumen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isOnTrial)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: context.accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.glassBorder)),
              child: Row(children: [
                Icon(Icons.timer_outlined, color: context.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: RichText(text: TextSpan(style: TextStyle(fontSize: 13, color: context.textSecondary), children: [
                  const TextSpan(text: 'Your free trial ends in '),
                  TextSpan(text: '${state.trialDaysLeft} days', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
                  const TextSpan(text: '. Activate now to keep access.'),
                ]))),
              ]),
            ),
          Text('Choose a plan to unlock all features.', style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 14),
          ...plans.map((plan) {
            final isSelected = _selectedPlan == plan.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = plan.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? context.accentDim : context.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? context.accent : plan.popular ? context.goldColor : context.glassBorder, width: isSelected ? 1.5 : 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(plan.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor))),
                    if (plan.popular) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFFF59E0B)]), borderRadius: BorderRadius.circular(20)),
                      child: const Text('BEST VALUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '₦${_formatPrice(plan.price)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: context.accent)),
                    TextSpan(text: ' / ${plan.days <= 30 ? 'month' : plan.days <= 90 ? 'term' : 'year'}', style: TextStyle(fontSize: 13, color: context.textMuted)),
                  ])),
                  const SizedBox(height: 10),
                  ...plan.perks.map((perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.check_circle, color: context.successColor, size: 14),
                      const SizedBox(width: 6),
                      Text(perk, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    ]),
                  )),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showPaymentDetails(context, state),
            style: ElevatedButton.styleFrom(backgroundColor: context.goldColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Continue to Payment →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(height: 10),
          Center(child: Text('After payment, send proof to admin for activation.', style: TextStyle(fontSize: 11, color: context.textMuted), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  void _showPaymentDetails(BuildContext context, AppState state) {
    final plan = plans.firstWhere((p) => p.id == _selectedPlan);
    final refC = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Payment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.glassBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SELECTED PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.07)),
              const SizedBox(height: 4),
              Text('${plan.name} — ₦${_formatPrice(plan.price)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFB45309).withOpacity(0.08), const Color(0xFFF59E0B).withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB45309).withOpacity(0.18)),
            ),
            child: Column(children: [
              Text('BANK TRANSFER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.goldColor, letterSpacing: 0.07)),
              const SizedBox(height: 12),
              _bankRow(context, 'Bank', 'Access Bank'),
              const SizedBox(height: 8),
              _bankRow(context, 'Account Name', 'Lumen Education Ltd'),
              const SizedBox(height: 8),
              _bankRow(context, 'Account Number', '0123456789'),
              const SizedBox(height: 8),
              _bankRow(context, 'Amount', '₦${_formatPrice(plan.price)}', isAmount: true),
            ]),
          ),
          const SizedBox(height: 12),
          Text('① Transfer ₦${_formatPrice(plan.price)} to the account above\n② Take a screenshot of your receipt\n③ Send receipt + email to admin via DM', style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.6)),
          const SizedBox(height: 12),
          TextField(controller: refC, decoration: InputDecoration(hintText: 'Enter your transfer reference/narration', hintStyle: TextStyle(color: context.textMuted))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (refC.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter your transfer reference')));
                return;
              }
              state.submitPaymentProof(_selectedPlan, refC.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment notified! Admin will activate you shortly.')));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.goldColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text("I've Made Payment — Notify Admin", style: TextStyle(fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _bankRow(BuildContext context, String label, String value, {bool isAmount = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: context.textMuted)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isAmount ? context.goldColor : context.textColor)),
    ],
  );
}
