import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/constants.dart';

/// Central app state. Persists to SharedPreferences (local-only).
class AppState extends ChangeNotifier {
  LumenUser? currentUser;
  List<LumenUser> allUsers = [];
  List<StudyGroup> groups = [];
  Map<String, List<ChatMessage>> groupMessages = {};
  List<FlashDeck> decks = [];
  List<AppNotification> notifications = [];
  List<VideoLink> videoLinks = [];
  bool darkMode = false;

  static const _uuid = Uuid();

  // Storage keys (centralised so refactors don't drop user data).
  static const _kDark = 'lumenDark';
  static const _kUsers = 'lumenAllUsers';
  static const _kCurrentUser = 'lumenUser';
  static const _kGroups = 'lumenGroups';
  static const _kGroupMsgs = 'lumenGMsgs';
  static const _kDecks = 'lumenDecks';
  static const _kNotifs = 'lumenNotifs';
  static const _kVideos = 'lumenVideos';

  // ── INIT ──────────────────────────────────────
  Future<void> init() async {
    await _loadAll();
    await _seedDefaultGroups();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    darkMode = prefs.getBool(_kDark) ?? false;

    allUsers = _decodeList<LumenUser>(prefs.getString(_kUsers), LumenUser.fromJson);

    final userJson = prefs.getString(_kCurrentUser);
    if (userJson != null) {
      try {
        currentUser = LumenUser.fromJson(Map<String, dynamic>.from(jsonDecode(userJson)));
        // Sync with master allUsers list.
        final idx = allUsers.indexWhere((u) => u.email == currentUser!.email);
        if (idx != -1) currentUser = allUsers[idx];
      } catch (e) {
        debugPrint('Failed to restore current user: $e');
        currentUser = null;
      }
    }

    groups = _decodeList<StudyGroup>(prefs.getString(_kGroups), StudyGroup.fromJson);

    final gMsgsJson = prefs.getString(_kGroupMsgs);
    if (gMsgsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(gMsgsJson);
        groupMessages = decoded.map((k, v) {
          final List<dynamic> msgs = v as List<dynamic>;
          return MapEntry(
            k,
            msgs.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList(),
          );
        });
      } catch (e) {
        debugPrint('Failed to load group messages: $e');
      }
    }

    decks = _decodeList<FlashDeck>(prefs.getString(_kDecks), FlashDeck.fromJson);
    notifications = _decodeList<AppNotification>(prefs.getString(_kNotifs), AppNotification.fromJson);
    videoLinks = _decodeList<VideoLink>(prefs.getString(_kVideos), VideoLink.fromJson);
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((j) => fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (e) {
      debugPrint('Failed to decode list ($T): $e');
      return <T>[];
    }
  }

  Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, darkMode);
    await prefs.setString(_kUsers, jsonEncode(allUsers.map((u) => u.toJson()).toList()));
    if (currentUser != null) {
      await prefs.setString(_kCurrentUser, jsonEncode(currentUser!.toJson()));
    }
    await prefs.setString(_kGroups, jsonEncode(groups.map((g) => g.toJson()).toList()));
    await prefs.setString(
      _kGroupMsgs,
      jsonEncode(groupMessages.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()))),
    );
    await prefs.setString(_kDecks, jsonEncode(decks.map((d) => d.toJson()).toList()));
    // Cap notifications at 100 most recent so storage stays bounded.
    final recentNotifs = notifications.length <= 100
        ? notifications
        : notifications.sublist(notifications.length - 100);
    await prefs.setString(_kNotifs, jsonEncode(recentNotifs.map((n) => n.toJson()).toList()));
    await prefs.setString(_kVideos, jsonEncode(videoLinks.map((v) => v.toJson()).toList()));
  }

  Future<void> _seedDefaultGroups() async {
    const defaults = [
      {'id': 'grp_jamb_general', 'name': 'JAMB General', 'icon': '🎯', 'color': '#7c3aed', 'desc': 'General JAMB prep discussion'},
      {'id': 'grp_math', 'name': 'Mathematics Hub', 'icon': '∑', 'color': '#2563eb', 'desc': 'Math problems & solutions'},
      {'id': 'grp_english', 'name': 'English Corner', 'icon': 'Aa', 'color': '#7c3aed', 'desc': 'English language & lit'},
      {'id': 'grp_science', 'name': 'Science Bloc', 'icon': '⚗', 'color': '#059669', 'desc': 'Physics, Chemistry, Biology'},
      {'id': 'grp_cbt', 'name': 'CBT Warriors', 'icon': '⚔', 'color': '#dc2626', 'desc': 'CBT practice & strategies'},
    ];
    var changed = false;
    for (final d in defaults) {
      if (!groups.any((g) => g.id == d['id'])) {
        groups.add(StudyGroup(
          id: d['id']!,
          name: d['name']!,
          description: d['desc']!,
          icon: d['icon']!,
          color: d['color']!,
          isDefault: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          createdBy: adminEmail,
          admins: [adminEmail],
        ));
        changed = true;
      }
    }
    if (changed) await saveAll();
  }

  // ── AUTH ──────────────────────────────────────
  Future<String?> register(String name, String email, String pass, String course, String uni) async {
    if (name.isEmpty || email.isEmpty || pass.isEmpty) return 'Fill all fields';
    if (pass.length < 6) return 'Password min 6 chars';
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) return 'Enter a valid email';
    if (allUsers.any((u) => u.email == normalized)) return 'Email already registered';

    final isAdmin = normalized == adminEmail;
    final user = LumenUser(
      name: name.trim(),
      email: normalized,
      password: pass,
      course1: course,
      choice1: uni.trim().isEmpty ? 'University' : uni.trim(),
      isAdmin: isAdmin,
      verified: isAdmin,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastActive: DateTime.now().millisecondsSinceEpoch,
    );
    allUsers.add(user);
    currentUser = user;
    await saveAll();
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String pass) async {
    final normalized = email.trim().toLowerCase();
    LumenUser? match;
    for (final u in allUsers) {
      if (u.email == normalized && u.password == pass) {
        match = u;
        break;
      }
    }
    if (match == null) return 'Invalid email or password';
    currentUser = match;
    match.lastActive = DateTime.now().millisecondsSinceEpoch;
    await saveAll();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUser);
    currentUser = null;
    notifyListeners();
  }

  bool _isValidEmail(String e) =>
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(e);

  // ── SUBSCRIPTION ──────────────────────────────
  bool get isActivated {
    final u = currentUser;
    if (u == null) return false;
    if (u.isAdmin) return true;
    final exp = u.subscriptionExpiry;
    if (exp != null && exp > DateTime.now().millisecondsSinceEpoch) return true;
    return trialDaysLeft > 0;
  }

  int get trialDaysLeft {
    final u = currentUser;
    if (u == null) return 0;
    final trialEnd = u.createdAt + (freeTrialDays * 86400000);
    final ms = trialEnd - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? (ms / 86400000).ceil() : 0;
  }

  bool get isOnTrial {
    final u = currentUser;
    if (u == null) return false;
    final exp = u.subscriptionExpiry;
    if (exp != null && exp > DateTime.now().millisecondsSinceEpoch) return false;
    return trialDaysLeft > 0;
  }

  String get subscriptionLabel {
    final u = currentUser;
    if (u == null) return '';
    if (u.isAdmin) return 'Admin';
    final exp = u.subscriptionExpiry;
    if (exp != null && exp > DateTime.now().millisecondsSinceEpoch) {
      final days = ((exp - DateTime.now().millisecondsSinceEpoch) / 86400000).ceil();
      return 'Active · ${days}d left';
    }
    if (isOnTrial) return 'Free Trial · ${trialDaysLeft}d left';
    return 'Expired — Upgrade';
  }

  void activateUser(String email, String planId) {
    final plan = plans.firstWhere((p) => p.id == planId, orElse: () => plans[1]);
    final idx = allUsers.indexWhere((u) => u.email == email);
    if (idx == -1) return;
    allUsers[idx].subscriptionExpiry =
        DateTime.now().millisecondsSinceEpoch + (plan.days * 86400000);
    allUsers[idx].paymentPending = null;
    if (currentUser?.email == email) currentUser = allUsers[idx];
    saveAll();
    notifyListeners();
  }

  void submitPaymentProof(String planId, String ref) {
    if (currentUser == null) return;
    final plan = plans.firstWhere((p) => p.id == planId, orElse: () => plans[1]);
    final pending = {
      'plan': planId,
      'ref': ref,
      'submittedAt': DateTime.now().millisecondsSinceEpoch,
    };
    currentUser!.paymentPending = pending;
    final idx = allUsers.indexWhere((u) => u.email == currentUser!.email);
    if (idx != -1) allUsers[idx].paymentPending = pending;
    addNotification(
      '[PAYMENT] ${currentUser!.name} (${currentUser!.email}) — ${plan.name} Plan ₦${plan.price} — Ref: $ref',
      adminEmail,
    );
    saveAll();
    notifyListeners();
  }

  // ── THEME ─────────────────────────────────────
  void toggleTheme() {
    darkMode = !darkMode;
    saveAll();
    notifyListeners();
  }

  // ── GROUPS ────────────────────────────────────
  void createGroup(String name, String desc, String icon, String color) {
    if (currentUser == null) return;
    final g = StudyGroup(
      id: 'grp_${_uuid.v4().substring(0, 8)}',
      name: name,
      description: desc,
      icon: icon,
      color: color,
      members: [currentUser!.email],
      admins: [currentUser!.email],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      createdBy: currentUser!.email,
    );
    groups.add(g);
    saveAll();
    notifyListeners();
  }

  void joinGroup(String gid) {
    if (currentUser == null) return;
    final g = _findGroup(gid);
    if (g == null) return;
    if (!g.members.contains(currentUser!.email)) {
      g.members.add(currentUser!.email);
      addGroupMessage(gid, ChatMessage(
        id: 'gm_${DateTime.now().millisecondsSinceEpoch}',
        from: 'system',
        text: '${currentUser!.name} joined the group',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: 'system',
      ));
    }
    saveAll();
    notifyListeners();
  }

  void leaveGroup(String gid) {
    if (currentUser == null) return;
    final g = _findGroup(gid);
    if (g == null) return;
    g.members.remove(currentUser!.email);
    g.admins.remove(currentUser!.email);
    g.moderators.remove(currentUser!.email);
    saveAll();
    notifyListeners();
  }

  StudyGroup? _findGroup(String gid) {
    for (final g in groups) {
      if (g.id == gid) return g;
    }
    return null;
  }

  // ── MESSAGES ──────────────────────────────────
  void addGroupMessage(String gid, ChatMessage msg) {
    groupMessages.putIfAbsent(gid, () => []);
    groupMessages[gid]!.add(msg);
    saveAll();
    notifyListeners();
  }

  void sendGroupMessage(String gid, String text, {String? replyTo}) {
    if (currentUser == null) return;
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: 'gm_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 4)}',
      from: currentUser!.email,
      text: text.trim(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      readBy: [currentUser!.email],
      replyTo: replyTo,
    );
    addGroupMessage(gid, msg);
  }

  void deleteGroupMessage(String gid, String msgId) {
    groupMessages[gid]?.removeWhere((m) => m.id == msgId);
    // Also clear the message from any pinned list it might be in.
    final g = _findGroup(gid);
    g?.pinned.remove(msgId);
    saveAll();
    notifyListeners();
  }

  void pinMessage(String gid, String msgId) {
    final g = _findGroup(gid);
    if (g == null) return;
    if (g.pinned.contains(msgId)) {
      g.pinned.remove(msgId);
    } else {
      g.pinned.add(msgId);
    }
    saveAll();
    notifyListeners();
  }

  void removeMember(String gid, String email) {
    final g = _findGroup(gid);
    if (g == null) return;
    g.members.remove(email);
    g.moderators.remove(email);
    saveAll();
    notifyListeners();
  }

  void banMember(String gid, String email) {
    final g = _findGroup(gid);
    if (g == null) return;
    g.members.remove(email);
    g.moderators.remove(email);
    if (!g.banned.contains(email)) g.banned.add(email);
    saveAll();
    notifyListeners();
  }

  void toggleMod(String gid, String email) {
    final g = _findGroup(gid);
    if (g == null) return;
    if (g.moderators.contains(email)) {
      g.moderators.remove(email);
    } else {
      g.moderators.add(email);
    }
    saveAll();
    notifyListeners();
  }

  void promoteToAdmin(String gid, String email) {
    final g = _findGroup(gid);
    if (g == null) return;
    if (!g.admins.contains(email)) g.admins.add(email);
    saveAll();
    notifyListeners();
  }

  /// Mark every message in a group as read by the current user.
  void markGroupRead(String gid) {
    if (currentUser == null) return;
    final msgs = groupMessages[gid];
    if (msgs == null) return;
    var changed = false;
    for (final m in msgs) {
      if (!m.readBy.contains(currentUser!.email)) {
        m.readBy.add(currentUser!.email);
        changed = true;
      }
    }
    if (changed) {
      saveAll();
      notifyListeners();
    }
  }

  int unreadCount(String gid) {
    final email = currentUser?.email;
    if (email == null) return 0;
    final msgs = groupMessages[gid];
    if (msgs == null) return 0;
    var count = 0;
    for (final m in msgs) {
      if (m.from != email && !m.readBy.contains(email)) count++;
    }
    return count;
  }

  // ── FLASHCARDS ────────────────────────────────
  void createDeck(String name, String subject, String color) {
    if (currentUser == null) return;
    final deck = FlashDeck(
      id: 'deck_${_uuid.v4().substring(0, 8)}',
      name: name,
      subject: subject,
      color: color,
      ownerId: currentUser!.email,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    decks.add(deck);
    saveAll();
    notifyListeners();
  }

  void addCard(String deckId, String front, String back) {
    final deck = decks.firstWhere(
      (d) => d.id == deckId,
      orElse: () => throw StateError('Deck $deckId not found'),
    );
    deck.cards.add(FlashCard(id: _uuid.v4(), front: front, back: back));
    saveAll();
    notifyListeners();
  }

  void deleteDeck(String deckId) {
    decks.removeWhere((d) => d.id == deckId);
    saveAll();
    notifyListeners();
  }

  // ── VIDEO LINKS ───────────────────────────────
  void addVideoLink(String url, String title, String subject, String? note) {
    if (currentUser == null) return;
    videoLinks.add(VideoLink(
      id: _uuid.v4(),
      url: url,
      title: title,
      subject: subject,
      note: note,
      postedAt: DateTime.now().millisecondsSinceEpoch,
      postedBy: currentUser!.email,
    ));
    saveAll();
    notifyListeners();
  }

  void deleteVideoLink(String id) {
    videoLinks.removeWhere((v) => v.id == id);
    saveAll();
    notifyListeners();
  }

  // ── PROFILE / TEST ────────────────────────────
  void recordTestResult(int score, int total, String subject) {
    final u = currentUser;
    if (u == null) return;
    u.testsTaken++;
    u.scores.add(score);
    final idx = allUsers.indexWhere((x) => x.email == u.email);
    if (idx != -1) {
      allUsers[idx].testsTaken = u.testsTaken;
      allUsers[idx].scores = u.scores;
    }
    saveAll();
    notifyListeners();
  }

  void updateProfile({String? bio, String? avatar}) {
    final u = currentUser;
    if (u == null) return;
    if (bio != null) u.bio = bio;
    if (avatar != null) u.avatar = avatar;
    final idx = allUsers.indexWhere((x) => x.email == u.email);
    if (idx != -1) {
      allUsers[idx].bio = u.bio;
      allUsers[idx].avatar = u.avatar;
    }
    saveAll();
    notifyListeners();
  }

  // ── NOTIFICATIONS ─────────────────────────────
  void addNotification(String msg, [String? user]) {
    notifications.add(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      msg: msg,
      user: user ?? currentUser?.email,
      time: DateTime.now().toIso8601String(),
    ));
    saveAll();
    notifyListeners();
  }

  void markAllNotifsRead() {
    final email = currentUser?.email;
    if (email == null) return;
    var changed = false;
    for (final n in notifications) {
      if (!n.read && (n.user == email || currentUser?.isAdmin == true)) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      saveAll();
      notifyListeners();
    }
  }

  int get unreadNotifCount {
    final email = currentUser?.email;
    if (email == null) return 0;
    final isAdmin = currentUser?.isAdmin == true;
    return notifications.where((n) => !n.read && (n.user == email || isAdmin)).length;
  }

  // ── ADMIN ─────────────────────────────────────
  void verifyUser(String email) {
    final idx = allUsers.indexWhere((u) => u.email == email);
    if (idx != -1) {
      allUsers[idx].verified = true;
      saveAll();
      notifyListeners();
    }
  }

  void deleteUser(String email) {
    allUsers.removeWhere((u) => u.email == email);
    saveAll();
    notifyListeners();
  }

  void rejectPayment(String email) {
    final idx = allUsers.indexWhere((u) => u.email == email);
    if (idx == -1) return;
    allUsers[idx].paymentPending = null;
    if (currentUser?.email == email) currentUser = allUsers[idx];
    saveAll();
    notifyListeners();
  }

  // ── HELPERS ───────────────────────────────────
  LumenUser? getUserByEmail(String email) {
    for (final u in allUsers) {
      if (u.email == email) return u;
    }
    return null;
  }

  String avatarUrl(LumenUser? user, {int size = 40}) {
    final px = size * 2;
    if (user == null) {
      return 'https://ui-avatars.com/api/?name=U&background=7c3aed&color=fff&size=$px';
    }
    if (user.avatar.isNotEmpty) return user.avatar;
    final name = Uri.encodeComponent(user.name.isEmpty ? 'U' : user.name);
    return 'https://ui-avatars.com/api/?name=$name&background=7c3aed&color=fff&size=$px';
  }

  String formatTime(int ts) {
    final d = DateTime.now().millisecondsSinceEpoch - ts;
    if (d < 60000) return 'Just now';
    if (d < 3600000) return '${(d / 60000).floor()}m ago';
    if (d < 86400000) return '${(d / 3600000).floor()}h ago';
    return '${(d / 86400000).floor()}d ago';
  }

  String formatClock(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  List<LumenUser> get leaderboard {
    final sorted = List<LumenUser>.from(allUsers);
    sorted.sort((a, b) => b.xp.compareTo(a.xp));
    return sorted.take(20).toList();
  }

  /// Lightweight content filter used to keep groups study-focused.
  static const _bannedWords = {
    'bet', 'betting', 'casino', 'gambl', 'porn', 'sex', 'nude', 'xxx',
    'dating', 'scam', 'yahoo', 'fraud', 'crypto', 'forex',
  };

  bool checkContentRelevance(String text) {
    final lower = text.toLowerCase();
    return !_bannedWords.any(lower.contains);
  }
}
