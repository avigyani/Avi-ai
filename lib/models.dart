/// Avi AI v1 — data models. Pure Dart, no platform code.
///
/// Privacy rule: no storage / file access anywhere in this app.
/// Everything is typed or pasted by the user, stored locally with
/// shared_preferences. Nothing is sent automatically.
enum PlatformKind { whatsapp, instagram, facebook, gbp }

extension PlatformKindLabel on PlatformKind {
  String get label {
    switch (this) {
      case PlatformKind.whatsapp:
        return 'WhatsApp';
      case PlatformKind.instagram:
        return 'Instagram';
      case PlatformKind.facebook:
        return 'Facebook';
      case PlatformKind.gbp:
        return 'Google (GBP)';
    }
  }

  String get kannada {
    switch (this) {
      case PlatformKind.whatsapp:
        return 'ವಾಟ್ಸಾಪ್';
      case PlatformKind.instagram:
        return 'ಇನ್‌ಸ್ಟಾಗ್ರಾಮ್';
      case PlatformKind.facebook:
        return 'ಫೇಸ್‌ಬುಕ್';
      case PlatformKind.gbp:
        return 'ಗೂಗಲ್';
    }
  }
}

enum AccessMode { approval, full }

extension AccessModeLabel on AccessMode {
  String get label =>
      this == AccessMode.approval ? 'Approval only' : 'Full access';
  String get kannada =>
      this == AccessMode.approval ? 'Approval ಮಾತ್ರ' : 'Full access';
}

/// A profile Avi AI manages. Profiles are configurable in-app;
/// do NOT hardcode more than the two seed profiles below.
class AviProfile {
  final String id;
  final String name;
  final String handle;
  final PlatformKind platform;
  AccessMode access;

  AviProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.platform,
    this.access = AccessMode.approval,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'platform': platform.name,
        'access': access.name,
      };

  factory AviProfile.fromJson(Map<String, dynamic> j) => AviProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        handle: j['handle'] as String,
        platform: PlatformKind.values
            .firstWhere((p) => p.name == j['platform'],
                orElse: () => PlatformKind.facebook),
        access: (j['access'] as String?) == 'full'
            ? AccessMode.full
            : AccessMode.approval,
      );
}

enum InboxStatus { pending, approved, rejected, sentManually }

extension InboxStatusLabel on InboxStatus {
  String get kannada {
    switch (this) {
      case InboxStatus.pending:
        return 'ಕಾಯುತ್ತಿದೆ';
      case InboxStatus.approved:
        return 'Approve ಆಯ್ತು';
      case InboxStatus.rejected:
        return 'Reject ಆಯ್ತು';
      case InboxStatus.sentManually:
        return 'ನೀವು ಕಳುಹಿಸಿದ್ದು';
    }
  }
}

/// One received message, pasted manually by the user in v1.
/// v1 does NOT read Messenger / WhatsApp directly (no official API
/// for personal profiles). The sender sends it themself after approval.
class InboxItem {
  final String id;
  final String profileId;
  final PlatformKind platform;
  final String sender;
  final String text;
  final DateTime receivedAt;
  final String draft;
  final String draftSource; // 'training' or 'template'
  InboxStatus status;
  String editedDraft;

  InboxItem({
    required this.id,
    required this.profileId,
    required this.platform,
    required this.sender,
    required this.text,
    required this.receivedAt,
    required this.draft,
    required this.draftSource,
    this.status = InboxStatus.pending,
    String? editedDraft,
  }) : editedDraft = editedDraft ?? draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'platform': platform.name,
        'sender': sender,
        'text': text,
        'receivedAt': receivedAt.toIso8601String(),
        'draft': draft,
        'draftSource': draftSource,
        'status': status.name,
        'editedDraft': editedDraft,
      };

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
        id: j['id'] as String,
        profileId: j['profileId'] as String,
        platform: PlatformKind.values
            .firstWhere((p) => p.name == j['platform'],
                orElse: () => PlatformKind.facebook),
        sender: j['sender'] as String,
        text: j['text'] as String,
        receivedAt: DateTime.tryParse(j['receivedAt'] as String? ?? '') ??
            DateTime.now(),
        draft: j['draft'] as String,
        draftSource: j['draftSource'] as String? ?? 'template',
        status: InboxStatus.values.firstWhere(
            (s) => s.name == j['status'],
            orElse: () => InboxStatus.pending),
        editedDraft: j['editedDraft'] as String?,
      );
}

/// One training example Abhi teaches Avi AI:
/// when a message like [incoming] arrives, reply like [reply].
class TrainingExample {
  final String id;
  final String incoming;
  final String reply;
  final String? note;

  TrainingExample({
    required this.id,
    required this.incoming,
    required this.reply,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'incoming': incoming,
        'reply': reply,
        'note': note,
      };

  factory TrainingExample.fromJson(Map<String, dynamic> j) =>
      TrainingExample(
        id: j['id'] as String,
        incoming: j['incoming'] as String,
        reply: j['reply'] as String,
        note: j['note'] as String?,
      );
}
