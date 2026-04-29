import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../models/constants.dart';
import '../utils/theme.dart';
import 'paywall_screen.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myDecks = state.decks.where((d) => d.ownerId == state.currentUser?.email).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        title: Text('Flashcards', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.accent),
            onPressed: () {
              if (!state.isActivated && state.trialDaysLeft == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                return;
              }
              _showCreateDeck(context, state);
            },
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: myDecks.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.style_outlined, size: 40, color: context.textMuted.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text('No flashcard decks yet.', style: TextStyle(color: context.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showCreateDeck(context, state),
                child: Text('Create your first deck →', style: TextStyle(color: context.accent, fontWeight: FontWeight.w700)),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myDecks.length,
              itemBuilder: (ctx, i) => _DeckCard(deck: myDecks[i]),
            ),
    );
  }

  void _showCreateDeck(BuildContext context, AppState state) {
    final nameC = TextEditingController();
    String selectedSubject = 'Mathematics';
    String selectedColor = '#7c3aed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('New Flashcard Deck', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
            const SizedBox(height: 16),
            TextField(controller: nameC, decoration: InputDecoration(hintText: 'Deck name (e.g. "Biology Chapter 3")', hintStyle: TextStyle(color: context.textMuted))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(11), border: Border.all(color: context.glassBorder)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSubject,
                  isExpanded: true,
                  dropdownColor: context.bg2,
                  style: TextStyle(color: context.textColor, fontSize: 14),
                  onChanged: (v) => setModalState(() => selectedSubject = v!),
                  items: subjects.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameC.text.trim().isEmpty) return;
                  state.createDeck(nameC.text.trim(), selectedSubject, selectedColor);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Create Deck', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final FlashDeck deck;
  const _DeckCard({required this.deck});

  Color get _color {
    try { return Color(int.parse(deck.color.replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF7C3AED); }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckDetailScreen(deckId: deck.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.glassBorder),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: _color.withOpacity(0.2))),
            child: Center(child: Icon(Icons.style, color: _color, size: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deck.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.textColor)),
            const SizedBox(height: 2),
            Text('${deck.subject} · ${deck.cards.length} cards', style: TextStyle(fontSize: 12, color: context.textMuted)),
          ])),
          Icon(Icons.chevron_right, color: context.textMuted, size: 18),
        ]),
      ),
    );
  }
}

// ── DECK DETAIL ──────────────────────────────────
class DeckDetailScreen extends StatefulWidget {
  final String deckId;
  const DeckDetailScreen({super.key, required this.deckId});
  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  bool _studying = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final deck = state.decks.firstWhere((d) => d.id == widget.deckId);

    if (_studying && deck.cards.isNotEmpty) {
      return _StudyMode(deck: deck, onExit: () => setState(() => _studying = false));
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.textColor), onPressed: () => Navigator.pop(context)),
        title: Text(deck.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.dangerColor),
            onPressed: () {
              state.deleteDeck(deck.id);
              Navigator.pop(context);
            },
          ),
          IconButton(icon: Icon(Icons.add, color: context.accent), onPressed: () => _showAddCard(context, state, deck.id)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: Column(children: [
        if (deck.cards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _studying = true),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Study Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        Expanded(
          child: deck.cards.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.style_outlined, size: 40, color: context.textMuted.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No cards yet. Add your first card!', style: TextStyle(color: context.textMuted)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => _showAddCard(context, state, deck.id), child: Text('Add Card', style: TextStyle(color: context.accent, fontWeight: FontWeight.w700))),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: deck.cards.length,
                  itemBuilder: (ctx, i) {
                    final card = deck.cards[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: context.bg1, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.glassBorder)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Q: ${card.front}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textColor)),
                        const SizedBox(height: 6),
                        Text('A: ${card.back}', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _showAddCard(BuildContext context, AppState state, String deckId) {
    final frontC = TextEditingController();
    final backC = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add Flashcard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
          const SizedBox(height: 16),
          TextField(controller: frontC, maxLines: 3, decoration: InputDecoration(hintText: 'Front (Question)', hintStyle: TextStyle(color: context.textMuted))),
          const SizedBox(height: 12),
          TextField(controller: backC, maxLines: 3, decoration: InputDecoration(hintText: 'Back (Answer)', hintStyle: TextStyle(color: context.textMuted))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (frontC.text.trim().isEmpty || backC.text.trim().isEmpty) return;
              state.addCard(deckId, frontC.text.trim(), backC.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── STUDY MODE ───────────────────────────────────
class _StudyMode extends StatefulWidget {
  final FlashDeck deck;
  final VoidCallback onExit;
  const _StudyMode({required this.deck, required this.onExit});
  @override
  State<_StudyMode> createState() => _StudyModeState();
}

class _StudyModeState extends State<_StudyMode> {
  int _index = 0;
  bool _flipped = false;
  int _known = 0;

  @override
  Widget build(BuildContext context) {
    final card = widget.deck.cards[_index];
    final total = widget.deck.cards.length;
    final progress = (_index + 1) / total;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(icon: Icon(Icons.close, color: context.textColor), onPressed: widget.onExit),
        title: Text('${_index + 1} / $total', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress, backgroundColor: context.bg3, valueColor: AlwaysStoppedAnimation<Color>(context.accent), minHeight: 4),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(_flipped),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _flipped ? context.accentDim : context.bg1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _flipped ? context.accent : context.glassBorder, width: _flipped ? 1.5 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_flipped ? 'Answer' : 'Question', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.07, color: context.textMuted)),
                    const SizedBox(height: 16),
                    Text(_flipped ? card.back : card.front, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textColor, height: 1.4), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Text('Tap to ${_flipped ? 'hide' : 'reveal'} answer', style: TextStyle(fontSize: 12, color: context.textMuted)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_flipped) Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _next(false),
              style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Again ✗', style: TextStyle(fontWeight: FontWeight.w800)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => _next(true),
              style: ElevatedButton.styleFrom(backgroundColor: context.successColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Got it ✓', style: TextStyle(fontWeight: FontWeight.w800)),
            )),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _next(bool knew) {
    if (knew) _known++;
    if (_index < widget.deck.cards.length - 1) {
      setState(() { _index++; _flipped = false; });
    } else {
      // Done
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        backgroundColor: context.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Session Complete! 🎉', style: TextStyle(fontWeight: FontWeight.w800, color: context.textColor)),
        content: Text('You knew $_known out of ${widget.deck.cards.length} cards.', style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); widget.onExit(); }, child: Text('Done', style: TextStyle(color: context.accent, fontWeight: FontWeight.w700))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() { _index = 0; _flipped = false; _known = 0; }); },
            style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0),
            child: const Text('Study Again', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ));
    }
  }
}
