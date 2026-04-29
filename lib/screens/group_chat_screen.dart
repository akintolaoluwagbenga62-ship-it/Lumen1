import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _msgC = TextEditingController();
  final _scrollC = ScrollController();
  String? _replyToId;
  String? _replyToName;
  String? _replyToText;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    // Mark messages as read once when chat opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markGroupRead(widget.groupId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(_scrollC.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  /// Auto-scroll only when the message list grew since the last build.
  /// Avoids the original bug of unconditional scroll inside build().
  void _maybeAutoScroll(int currentCount) {
    if (currentCount > _lastMsgCount) {
      _lastMsgCount = currentCount;
      _scrollToBottom();
    }
  }

  void _send(AppState state) {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    if (!state.checkContentRelevance(text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message blocked: study-related topics only')));
      return;
    }
    state.sendGroupMessage(widget.groupId, text, replyTo: _replyToId);
    _msgC.clear();
    setState(() { _replyToId = null; _replyToName = null; _replyToText = null; });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final group = state.groups.firstWhere((g) => g.id == widget.groupId, orElse: () => state.groups.first);
    final user = state.currentUser!;
    final isAdmin = group.admins.contains(user.email) || user.isAdmin;
    final isMod = isAdmin || group.moderators.contains(user.email);
    final isMember = group.isDefault || group.members.contains(user.email) || group.admins.contains(user.email);
    final msgs = state.groupMessages[widget.groupId] ?? [];

    _maybeAutoScroll(msgs.length);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _showGroupInfo(context, state, group, isAdmin),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _parseColor(group.color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _parseColor(group.color).withOpacity(0.2)),
              ),
              child: Center(child: Text(group.icon, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.textColor)),
              Text('${group.isDefault ? state.allUsers.length : group.members.length} members', style: TextStyle(fontSize: 11, color: context.textMuted)),
            ]),
          ]),
        ),
        actions: [
          if (isMod) IconButton(icon: Icon(Icons.settings_outlined, color: context.textMuted), onPressed: () => _showGroupSettings(context, state, group)),
          IconButton(icon: Icon(Icons.info_outline, color: context.textMuted), onPressed: () => _showGroupInfo(context, state, group, isAdmin)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: context.glassBorder)),
      ),
      body: Column(
        children: [
          // Pinned message
          if (group.pinned.isNotEmpty) _buildPinnedBar(context, state, group),
          // Messages
          Expanded(
            child: msgs.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_bubble_outline, size: 40, color: context.textMuted.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No messages yet. Start the conversation!', style: TextStyle(color: context.textMuted, fontSize: 14)),
                  ]))
                : ListView.builder(
                    controller: _scrollC,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: msgs.length,
                    itemBuilder: (ctx, i) {
                      final msg = msgs[i];
                      if (msg.type == 'system') return _SystemMsg(text: msg.text);
                      final isSent = msg.from == user.email;
                      final sender = state.getUserByEmail(msg.from);
                      return _ChatBubble(
                        msg: msg,
                        isSent: isSent,
                        sender: sender,
                        state: state,
                        canAdmin: isAdmin || isMod,
                        groupId: widget.groupId,
                        onReply: (id, name, text) => setState(() {
                          _replyToId = id;
                          _replyToName = name;
                          _replyToText = text;
                        }),
                        onDelete: () => state.deleteGroupMessage(widget.groupId, msg.id),
                        onPin: isAdmin ? () => state.pinMessage(widget.groupId, msg.id) : null,
                      );
                    },
                  ),
          ),
          // Reply preview
          if (_replyToId != null)
            Container(
              color: context.bg1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                Container(width: 3, height: 36, color: context.accent),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Replying to $_replyToName', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.accent)),
                  Text(_replyToText ?? '', style: TextStyle(fontSize: 12, color: context.textMuted), overflow: TextOverflow.ellipsis),
                ])),
                IconButton(icon: Icon(Icons.close, size: 16, color: context.textMuted), onPressed: () => setState(() { _replyToId = null; })),
              ]),
            ),
          // Input
          if (isMember) _buildInput(context, state) else _buildJoinBar(context, state),
        ],
      ),
    );
  }

  Widget _buildPinnedBar(BuildContext context, AppState state, StudyGroup group) {
    final pinned = group.pinned.map((id) => (state.groupMessages[group.id] ?? []).firstWhere((m) => m.id == id, orElse: () => ChatMessage(id: '', from: '', text: '', timestamp: 0))).where((m) => m.id.isNotEmpty).toList();
    if (pinned.isEmpty) return const SizedBox();
    final last = pinned.last;
    return GestureDetector(
      onTap: () => _showPinnedMessages(context, state, group),
      child: Container(
        color: context.accentDim,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Icon(Icons.push_pin, size: 14, color: context.accent),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PINNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.accent)),
            Text(last.text.isEmpty ? 'Shared content' : last.text, style: TextStyle(fontSize: 12, color: context.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }

  Widget _buildInput(BuildContext context, AppState state) {
    return Container(
      color: context.bg1,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _msgC,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(state),
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: context.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide(color: context.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide(color: context.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide(color: context.accent)),
                suffixIcon: IconButton(icon: Icon(Icons.tag_faces_outlined, color: context.textMuted), onPressed: () => _showEmojiPicker(context)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(state),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: context.accent, shape: BoxShape.circle),
              child: Icon(Icons.send, color: context.isDark ? Colors.black : Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildJoinBar(BuildContext context, AppState state) {
    return Container(
      color: context.bg1,
      padding: const EdgeInsets.all(14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => state.joinGroup(widget.groupId),
            style: ElevatedButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Join to participate', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final symbols = ['+1', 'OK', '?', '!!', '...', 'lol', 'nope', 'yes', 'no', 'wow', 'facts', 'noted', 'wrong', 'right', 'nice'];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick Reactions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.07, color: context.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: symbols.map((s) => GestureDetector(
              onTap: () { _msgC.text += s; Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.glassBorder)),
                child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textColor)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showGroupInfo(BuildContext context, AppState state, StudyGroup group, bool isAdmin) {
    final memberEmails = group.isDefault ? state.allUsers.map((u) => u.email).toList() : group.members;
    final members = state.allUsers.where((u) => memberEmails.contains(u.email)).toList();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6, maxChildSize: 0.9,
        builder: (_, scroll) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text(group.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.glassBorder)), child: Text(group.description, style: TextStyle(fontSize: 13, color: context.textSecondary))),
              const SizedBox(height: 12),
              Text('${members.length} Members', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.07)),
            ]),
          ),
          Expanded(child: ListView(controller: scroll, children: members.map((m) {
            final role = group.admins.contains(m.email) ? 'Admin' : group.moderators.contains(m.email) ? 'Mod' : 'Member';
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(state.avatarUrl(m))),
              title: Text(m.name, style: TextStyle(fontWeight: FontWeight.w700, color: context.textColor)),
              subtitle: Text(m.course1, style: TextStyle(color: context.textMuted, fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: role == 'Admin' ? const Color(0xFFF59E0B).withOpacity(0.12) : role == 'Mod' ? const Color(0xFF3B82F6).withOpacity(0.1) : context.bg3,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: role == 'Admin' ? const Color(0xFFF59E0B).withOpacity(0.2) : role == 'Mod' ? const Color(0xFF3B82F6).withOpacity(0.2) : context.glassBorder),
                ),
                child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: role == 'Admin' ? const Color(0xFFF59E0B) : role == 'Mod' ? const Color(0xFF3B82F6) : context.textMuted)),
              ),
            );
          }).toList())),
          if (!group.isDefault && group.members.contains(state.currentUser!.email))
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () { state.leaveGroup(group.id); Navigator.pop(context); Navigator.pop(context); },
                style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Leave Group', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ),
        ]),
      ),
    );
  }

  void _showGroupSettings(BuildContext context, AppState state, StudyGroup group) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group settings coming soon')));
  }

  void _showPinnedMessages(BuildContext context, AppState state, StudyGroup group) {
    final pinned = group.pinned.map((id) => (state.groupMessages[group.id] ?? []).firstWhere((m) => m.id == id, orElse: () => ChatMessage(id: '', from: '', text: '', timestamp: 0))).where((m) => m.id.isNotEmpty).toList();
    showModalBottomSheet(
      context: context, backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.push_pin, size: 16), const SizedBox(width: 8), Text('Pinned Messages', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textColor))]),
          const SizedBox(height: 12),
          ...pinned.map((m) {
            final s = state.getUserByEmail(m.from);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.glassBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s?.name ?? m.from, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.accent)),
                const SizedBox(height: 4),
                Text(m.text.isEmpty ? 'Image' : m.text, style: TextStyle(fontSize: 13, color: context.textSecondary)),
                const SizedBox(height: 4),
                Text(state.formatClock(m.timestamp), style: TextStyle(fontSize: 10, color: context.textMuted)),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF7C3AED); }
  }
}

class _SystemMsg extends StatelessWidget {
  final String text;
  const _SystemMsg({required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: context.bg2, borderRadius: BorderRadius.circular(100), border: Border.all(color: context.glassBorder)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted)),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isSent;
  final LumenUser? sender;
  final AppState state;
  final bool canAdmin;
  final String groupId;
  final Function(String, String, String) onReply;
  final VoidCallback onDelete;
  final VoidCallback? onPin;

  const _ChatBubble({
    required this.msg, required this.isSent, required this.sender,
    required this.state, required this.canAdmin, required this.groupId,
    required this.onReply, required this.onDelete, this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSent) ...[
              CircleAvatar(backgroundImage: NetworkImage(state.avatarUrl(sender)), radius: 14),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: isSent ? context.accent : context.bg1,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSent ? 16 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 16),
                  ),
                  border: isSent ? null : Border.all(color: context.glassBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!isSent && sender != null)
                    Text(sender!.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.accent)),
                  if (msg.replyTo != null) _buildReplyQuote(context),
                  if (msg.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(msg.image!, width: double.infinity, height: 180, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (msg.text.isNotEmpty)
                    Text(msg.text, style: TextStyle(fontSize: 14, color: isSent ? (context.isDark ? Colors.black : Colors.white) : context.textColor)),
                  const SizedBox(height: 2),
                  Text(state.formatClock(msg.timestamp), style: TextStyle(fontSize: 10, color: (isSent ? (context.isDark ? Colors.black : Colors.white) : context.textColor).withOpacity(0.5))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyQuote(BuildContext context) {
    final orig = (state.groupMessages[groupId] ?? []).firstWhere((m) => m.id == msg.replyTo, orElse: () => ChatMessage(id: '', from: '', text: '', timestamp: 0));
    if (orig.id.isEmpty) return const SizedBox();
    final s = state.getUserByEmail(orig.from);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: isSent ? Colors.white.withOpacity(0.4) : context.accent, width: 2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s?.name ?? orig.from, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSent ? Colors.white70 : context.accent)),
        Text(orig.text.isEmpty ? 'Shared content' : (orig.text.length > 60 ? '${orig.text.substring(0, 60)}...' : orig.text), style: TextStyle(fontSize: 12, color: isSent ? Colors.white70 : context.textMuted)),
      ]),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: context.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bg4, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        _option(context, Icons.reply_outlined, 'Reply', () {
          Navigator.pop(context);
          onReply(msg.id, sender?.name ?? 'User', msg.text);
        }),
        if (onPin != null) _option(context, Icons.push_pin_outlined, 'Pin Message', () { Navigator.pop(context); onPin!(); }),
        if (isSent || canAdmin) _option(context, Icons.delete_outline, 'Delete', () { Navigator.pop(context); onDelete(); }, danger: true),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _option(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? context.dangerColor : context.textSecondary),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? context.dangerColor : context.textColor)),
      onTap: onTap,
    );
  }
}
