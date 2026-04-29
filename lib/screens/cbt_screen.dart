import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../models/constants.dart';
import '../utils/theme.dart';
import 'paywall_screen.dart';

class CBTScreen extends StatelessWidget {
  const CBTScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        title: Text('CBT Practice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SubjectGrid(state: state),
          const SizedBox(height: 24),
          _LeaderboardCard(state: state),
        ],
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  final AppState state;
  const _SubjectGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Subject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
        const SizedBox(height: 4),
        Text('Practice JAMB-style questions', style: TextStyle(fontSize: 13, color: context.textMuted)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
          children: subjects.keys.map((subject) {
            final info = subjects[subject]!;
            final color = info['color'] as Color;
            return GestureDetector(
              onTap: () {
                if (!state.isActivated && state.trialDaysLeft == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => TestScreen(subject: subject)));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(info['icon'] as String, style: TextStyle(fontSize: 26, color: color, fontWeight: FontWeight.w800)),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(subject, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.textColor)),
                    Text('${jambQuestions[subject]?.length ?? 0} questions', style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ]),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final AppState state;
  const _LeaderboardCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final board = state.leaderboard.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Students', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
        const SizedBox(height: 12),
        ...board.asMap().entries.map((e) {
          final rank = e.key + 1;
          final u = e.value;
          final isMe = u.email == state.currentUser?.email;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? context.accentDim : context.bg1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isMe ? context.accent : context.glassBorder),
            ),
            child: Row(children: [
              _rankBadge(rank),
              const SizedBox(width: 12),
              CircleAvatar(backgroundImage: NetworkImage(state.avatarUrl(u, size: 36)), radius: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name + (isMe ? ' (You)' : ''), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textColor)),
                Text('${u.testsTaken} tests · Lv.${u.calcLevel}', style: TextStyle(fontSize: 11, color: context.textMuted)),
              ])),
              Text('${u.xp} XP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: context.accent)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _rankBadge(int rank) {
    Color color;
    if (rank == 1) color = const Color(0xFFFBBF24);
    else if (rank == 2) color = const Color(0xFFD1D5DB);
    else if (rank == 3) color = const Color(0xFFCA8A04);
    else color = const Color(0xFF6B7280);
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4))),
      child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color))),
    );
  }
}

// ── TEST SCREEN ──────────────────────────────────
class TestScreen extends StatefulWidget {
  final String subject;
  const TestScreen({super.key, required this.subject});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late List<JambQuestion> _questions;
  int _current = 0;
  int? _selected;
  bool _answered = false;
  Map<int, int> _answers = {};
  bool _finished = false;
  int _score = 0;

  // Timer
  late Timer _timer;
  int _seconds = 0;
  final int _totalSeconds = 20 * 60; // 20 min

  @override
  void initState() {
    super.initState();
    final all = List<JambQuestion>.from(jambQuestions[widget.subject] ?? []);
    all.shuffle();
    _questions = all.take(20).toList();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _seconds++; });
      if (_seconds >= _totalSeconds) _finish();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _select(int idx) {
    if (_answered) return;
    setState(() { _selected = idx; _answered = true; _answers[_current] = idx; });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() { _current++; _selected = _answers[_current]; _answered = _answers.containsKey(_current); });
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer.cancel();
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].answer) score++;
    }
    setState(() { _finished = true; _score = score; });
    context.read<AppState>().recordTestResult(score, _questions.length, widget.subject);
  }

  String get _timeLeft {
    final rem = _totalSeconds - _seconds;
    if (rem <= 0) return '00:00';
    final m = (rem ~/ 60).toString().padLeft(2, '0');
    final s = (rem % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _ResultScreen(score: _score, total: _questions.length, subject: widget.subject, answers: _answers, questions: _questions);

    final q = _questions[_current];
    final progress = (_current + 1) / _questions.length;
    final timeWarn = (_totalSeconds - _seconds) < 120;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(icon: Icon(Icons.close, color: context.textColor), onPressed: () => Navigator.pop(context)),
        title: Text('${widget.subject} CBT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timeWarn ? context.dangerColor.withOpacity(0.12) : context.bg2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: timeWarn ? context.dangerColor.withOpacity(0.3) : context.glassBorder),
            ),
            child: Text(_timeLeft, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: timeWarn ? context.dangerColor : context.textColor)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.bg3,
            valueColor: AlwaysStoppedAnimation<Color>(context.accent),
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${_current + 1} of ${_questions.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.bg1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.glassBorder),
              ),
              child: Text(q.q, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textColor, height: 1.4)),
            ),
            const SizedBox(height: 16),
            ...q.options.asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              final isSelected = _selected == idx;
              final isCorrect = _answered && idx == q.answer;
              final isWrong = _answered && isSelected && idx != q.answer;
              Color borderColor = context.glassBorder;
              Color bgColor = context.bg1;
              if (isCorrect) { borderColor = context.successColor; bgColor = context.successColor.withOpacity(0.08); }
              if (isWrong) { borderColor = context.dangerColor; bgColor = context.dangerColor.withOpacity(0.07); }
              if (!_answered && isSelected) { borderColor = context.accent; bgColor = context.accentDim; }

              return GestureDetector(
                onTap: () => _select(idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 1.5)),
                  child: Row(children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isCorrect ? context.successColor : isWrong ? context.dangerColor : isSelected ? context.accent : context.glassBorder, width: 1.5)),
                      child: Center(child: Text(['A', 'B', 'C', 'D'][idx], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isCorrect ? context.successColor : isWrong ? context.dangerColor : context.textColor))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(opt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textColor))),
                    if (isCorrect) Icon(Icons.check_circle, color: context.successColor, size: 18),
                    if (isWrong) Icon(Icons.cancel, color: context.dangerColor, size: 18),
                  ]),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.glassBorder)),
                child: Row(children: [
                  Icon(Icons.lightbulb_outline, color: context.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(q.explain, style: TextStyle(fontSize: 13, color: context.textSecondary))),
                ]),
              ),
            ],
            const Spacer(),
            Row(children: [
              if (_current > 0) Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _current--; _selected = _answers[_current]; _answered = _answers.containsKey(_current); }),
                  style: OutlinedButton.styleFrom(foregroundColor: context.textColor, side: BorderSide(color: context.glassBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (_current > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _answered ? _next : null,
                  style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(_current < _questions.length - 1 ? 'Next →' : 'Finish', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── RESULT SCREEN ────────────────────────────────
class _ResultScreen extends StatelessWidget {
  final int score, total;
  final String subject;
  final Map<int, int> answers;
  final List<JambQuestion> questions;

  const _ResultScreen({required this.score, required this.total, required this.subject, required this.answers, required this.questions});

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    final isGood = pct >= 60;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: (isGood ? context.successColor : context.dangerColor).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(isGood ? '🎉' : '📚', style: const TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 16),
              Text(isGood ? 'Well Done!' : 'Keep Studying!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5, color: context.textColor)),
              const SizedBox(height: 8),
              Text('$score out of $total correct', style: TextStyle(fontSize: 15, color: context.textMuted)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: context.bg1, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.glassBorder)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$pct', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 48, color: isGood ? context.successColor : context.dangerColor, letterSpacing: -2)),
                    Text('%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: context.textMuted)),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: pct / 100, backgroundColor: context.bg3, valueColor: AlwaysStoppedAnimation<Color>(isGood ? context.successColor : context.dangerColor), minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _stat(context, '✅', '$score', 'Correct'),
                    _stat(context, '❌', '${total - score}', 'Wrong'),
                    _stat(context, '⚡', '+${score * 50} XP', 'Earned'),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Back to Practice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              )),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestScreen(subject: subject))),
                style: OutlinedButton.styleFrom(foregroundColor: context.textColor, side: BorderSide(color: context.glassBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 0)),
                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String icon, String val, String lbl) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 20)),
    const SizedBox(height: 4),
    Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.textColor)),
    Text(lbl, style: TextStyle(fontSize: 11, color: context.textMuted)),
  ]);
}
