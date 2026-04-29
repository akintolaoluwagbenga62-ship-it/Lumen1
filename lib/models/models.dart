// ── MODELS ──────────────────────────────────────
import 'dart:math' as math;

class LumenUser {
  final String name;
  final String email;
  final String password;
  final String course1;
  final String choice1;
  String bio;
  String avatar;
  int testsTaken;
  List<int> scores;
  bool isAdmin;
  bool verified;
  final int createdAt;
  int lastActive;
  int? subscriptionExpiry;
  Map<String, dynamic>? paymentPending;

  LumenUser({
    required this.name,
    required this.email,
    required this.password,
    required this.course1,
    required this.choice1,
    this.bio = '',
    this.avatar = '',
    this.testsTaken = 0,
    List<int>? scores,
    this.isAdmin = false,
    this.verified = false,
    required this.createdAt,
    required this.lastActive,
    this.subscriptionExpiry,
    this.paymentPending,
  }) : scores = scores ?? [];

  factory LumenUser.fromJson(Map<String, dynamic> j) => LumenUser(
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        password: j['pass'] ?? '',
        course1: j['course1'] ?? 'Mathematics',
        choice1: j['choice1'] ?? 'University',
        bio: j['bio'] ?? '',
        avatar: j['avatar'] ?? '',
        testsTaken: j['testsTaken'] ?? 0,
        scores: List<int>.from(j['scores'] ?? const []),
        isAdmin: j['isAdmin'] ?? false,
        verified: j['verified'] ?? false,
        createdAt: j['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        lastActive: j['lastActive'] ?? DateTime.now().millisecondsSinceEpoch,
        subscriptionExpiry: j['subscriptionExpiry'],
        paymentPending: j['paymentPending'] != null
            ? Map<String, dynamic>.from(j['paymentPending'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'pass': password,
        'course1': course1,
        'choice1': choice1,
        'bio': bio,
        'avatar': avatar,
        'testsTaken': testsTaken,
        'scores': scores,
        'isAdmin': isAdmin,
        'verified': verified,
        'createdAt': createdAt,
        'lastActive': lastActive,
        'subscriptionExpiry': subscriptionExpiry,
        'paymentPending': paymentPending,
      };

  /// Total XP earned from tests + scores.
  int get xp => (testsTaken * 50) + scores.fold<int>(0, (s, v) => s + v);

  /// Level derived from XP. Each level requires N²·100 XP, so:
  ///   level = floor(sqrt(xp / 100)) + 1
  /// Uses dart:math.sqrt for correctness and performance.
  int get calcLevel {
    if (xp <= 0) return 1;
    return math.sqrt(xp / 100).floor() + 1;
  }

  /// XP required to reach the next level.
  int get nextLevelXp {
    final lvl = calcLevel;
    return lvl * lvl * 100;
  }
}

class StudyGroup {
  final String id;
  String name;
  String description;
  String icon;
  String color;
  List<String> members;
  List<String> admins;
  List<String> moderators;
  List<String> banned;
  List<String> pinned;
  bool isDefault;
  final int createdAt;
  String createdBy;

  StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    List<String>? members,
    List<String>? admins,
    List<String>? moderators,
    List<String>? banned,
    List<String>? pinned,
    this.isDefault = false,
    required this.createdAt,
    required this.createdBy,
  })  : members = members ?? [],
        admins = admins ?? [],
        moderators = moderators ?? [],
        banned = banned ?? [],
        pinned = pinned ?? [];

  factory StudyGroup.fromJson(Map<String, dynamic> j) => StudyGroup(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        icon: j['icon'] ?? '📚',
        color: j['color'] ?? '#7c3aed',
        members: List<String>.from(j['members'] ?? const []),
        admins: List<String>.from(j['admins'] ?? const []),
        moderators: List<String>.from(j['moderators'] ?? const []),
        banned: List<String>.from(j['banned'] ?? const []),
        pinned: List<String>.from(j['pinned'] ?? const []),
        isDefault: j['isDefault'] ?? false,
        createdAt: j['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        createdBy: j['createdBy'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'members': members,
        'admins': admins,
        'moderators': moderators,
        'banned': banned,
        'pinned': pinned,
        'isDefault': isDefault,
        'createdAt': createdAt,
        'createdBy': createdBy,
      };
}

class ChatMessage {
  final String id;
  final String from;
  String text;
  final int timestamp;
  List<String> readBy;
  String? replyTo;
  String? image;
  bool isSharedQ;
  bool isVoice;
  String? voiceData;
  String type; // 'message' | 'system'

  ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.timestamp,
    List<String>? readBy,
    this.replyTo,
    this.image,
    this.isSharedQ = false,
    this.isVoice = false,
    this.voiceData,
    this.type = 'message',
  }) : readBy = readBy ?? [];

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] ?? '',
        from: j['from'] ?? '',
        text: j['text'] ?? '',
        timestamp: j['timestamp'] ?? 0,
        readBy: List<String>.from(j['readBy'] ?? const []),
        replyTo: j['replyTo'],
        image: j['image'],
        isSharedQ: j['isSharedQ'] ?? false,
        isVoice: j['isVoice'] ?? false,
        voiceData: j['voiceData'],
        type: j['type'] ?? 'message',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'text': text,
        'timestamp': timestamp,
        'readBy': readBy,
        'replyTo': replyTo,
        'image': image,
        'isSharedQ': isSharedQ,
        'isVoice': isVoice,
        'voiceData': voiceData,
        'type': type,
      };
}

class FlashDeck {
  final String id;
  String name;
  String subject;
  String color;
  List<FlashCard> cards;
  final String ownerId;
  final int createdAt;

  FlashDeck({
    required this.id,
    required this.name,
    required this.subject,
    required this.color,
    List<FlashCard>? cards,
    required this.ownerId,
    required this.createdAt,
  }) : cards = cards ?? [];

  factory FlashDeck.fromJson(Map<String, dynamic> j) => FlashDeck(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        subject: j['subject'] ?? '',
        color: j['color'] ?? '#7c3aed',
        cards: (j['cards'] as List<dynamic>? ?? const [])
            .map((c) => FlashCard.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        ownerId: j['ownerId'] ?? '',
        createdAt: j['createdAt'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'color': color,
        'cards': cards.map((c) => c.toJson()).toList(),
        'ownerId': ownerId,
        'createdAt': createdAt,
      };
}

class FlashCard {
  final String id;
  String front;
  String back;

  FlashCard({required this.id, required this.front, required this.back});

  factory FlashCard.fromJson(Map<String, dynamic> j) =>
      FlashCard(id: j['id'] ?? '', front: j['front'] ?? '', back: j['back'] ?? '');

  Map<String, dynamic> toJson() => {'id': id, 'front': front, 'back': back};
}

class AppNotification {
  final String id;
  final String msg;
  final String? user;
  final String time;
  bool read;

  AppNotification({
    required this.id,
    required this.msg,
    this.user,
    required this.time,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id']?.toString() ?? '',
        msg: j['msg'] ?? '',
        user: j['user'],
        time: j['time'] ?? '',
        read: j['read'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'msg': msg,
        'user': user,
        'time': time,
        'read': read,
      };
}

class VideoLink {
  final String id;
  final String url;
  final String title;
  final String subject;
  final String? note;
  final int postedAt;
  final String postedBy;

  VideoLink({
    required this.id,
    required this.url,
    required this.title,
    required this.subject,
    this.note,
    required this.postedAt,
    required this.postedBy,
  });

  factory VideoLink.fromJson(Map<String, dynamic> j) => VideoLink(
        id: j['id'] ?? '',
        url: j['url'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? 'General',
        note: j['note'],
        postedAt: j['postedAt'] ?? 0,
        postedBy: j['postedBy'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'subject': subject,
        'note': note,
        'postedAt': postedAt,
        'postedBy': postedBy,
      };
}

// ── JAMB QUESTION ───────────────────────────────
class JambQuestion {
  final String q;
  final List<String> options;
  final int answer;
  final String explain;

  const JambQuestion({
    required this.q,
    required this.options,
    required this.answer,
    required this.explain,
  });
}

// ── SUBSCRIPTION PLAN ───────────────────────────
class SubscriptionPlan {
  final String id;
  final String name;
  final int price;
  final int days;
  final bool popular;
  final List<String> perks;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.days,
    this.popular = false,
    required this.perks,
  });
}
