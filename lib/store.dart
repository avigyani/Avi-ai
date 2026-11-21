// Avi AI v1 — local store. ChangeNotifier + shared_preferences.
// All data stays on the phone. No cloud, no file/storage access.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'draft_engine.dart';
import 'models.dart';

const _kProfiles = 'avi_ai_profiles_v1';
const _kInbox = 'avi_ai_inbox_v1';
const _kTraining = 'avi_ai_training_v1';
const _kApprovalDefault = 'avi_ai_approval_default_v1';

class AviStore extends ChangeNotifier {
  List<AviProfile> profiles = [];
  List<InboxItem> inbox = [];
  List<TrainingExample> training = [];

  /// True = approval-only by default for new profiles.
  bool approvalDefault = true;
  bool loaded = false;

  String profileName(String id) {
    final p = profiles.where((e) => e.id == id).toList();
    return p.isEmpty ? 'Profile' : p.first.name;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    approvalDefault = prefs.getBool(_kApprovalDefault) ?? true;
    profiles = _decodeList<AviProfile>(
        prefs.getString(_kProfiles), AviProfile.fromJson);
    inbox = _decodeList<InboxItem>(
        prefs.getString(_kInbox), InboxItem.fromJson);
    training = _decodeList<TrainingExample>(
        prefs.getString(_kTraining), TrainingExample.fromJson);
    if (profiles.isEmpty && inbox.isEmpty && training.isEmpty) {
      _seed();
    }
    loaded = true;
    notifyListeners();
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) from) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => from(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfiles,
        jsonEncode(profiles.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kInbox, jsonEncode(inbox.map((e) => e.toJson()).toList()));
    await prefs.setString(_kTraining,
        jsonEncode(training.map((e) => e.toJson()).toList()));
    await prefs.setBool(_kApprovalDefault, approvalDefault);
  }

  void _seed() {
    profiles = [
      AviProfile(
        id: 'p-resto',
        name: 'Secrets of Ocean',
        handle: '@secrets_ofocean',
        platform: PlatformKind.instagram,
      ),
      AviProfile(
        id: 'p-sisira',
        name: 'Sisira Mugila Kavite',
        handle: 'Facebook personal',
        platform: PlatformKind.facebook,
      ),
    ];
    training = [
      TrainingExample(
        id: 't1',
        incoming: 'Table book madbeku',
        reply:
            'ನಮಸ್ಕಾರ! Secrets of Ocean ನಲ್ಲಿ ಟೇಬಲ್ ಬುಕ್ ಮಾಡೋಕೆ ಖುಷಿ ಆಗುತ್ತೆ. ಎಷ್ಟು ಜನ, ಯಾವ ದಿನ ಮತ್ತು ಯಾವ ಸಮಯ ಅಂತ ಹೇಳಿ, ನಾನು confirm ಮಾಡ್ತೀನಿ.',
        note: 'Booking — Abhi style',
      ),
      TrainingExample(
        id: 't2',
        incoming: 'Menu price heli',
        reply:
            'ನಮಸ್ಕಾರ! ಮೆನು ಕಳುಹಿಸ್ತೀನಿ. Seafood, North Indian, Chinese — ಏನು ಇಷ್ಟ ಅಂತ ಹೇಳಿ, ಒಳ್ಳೆ dishes suggest ಮಾಡ್ತೀನಿ.',
        note: 'Menu',
      ),
      TrainingExample(
        id: 't3',
        incoming: 'Thank you, food was great',
        reply: 'ಧನ್ಯವಾದಗಳು! ಮತ್ತೆ ಬನ್ನಿ, ನಿಮ್ಮನ್ನು ನೋಡೋಕೆ ಖುಷಿ ಆಗುತ್ತೆ. 🙏',
        note: 'Thanks',
      ),
    ];
    final now = DateTime.now();
    inbox = [
      InboxItem(
        id: 'm1',
        profileId: 'p-resto',
        platform: PlatformKind.whatsapp,
        sender: 'Customer',
        text: 'Table book madbeku, 4 people, tonight 7pm',
        receivedAt: now.subtract(const Duration(minutes: 32)),
        draft: draftReply('Table book madbeku, 4 people, tonight 7pm',
                training)
            .text,
        draftSource: 'training',
      ),
      InboxItem(
        id: 'm2',
        profileId: 'p-sisira',
        platform: PlatformKind.facebook,
        sender: 'Friend',
        text: 'Hi, new poem chennagide!',
        receivedAt: now.subtract(const Duration(hours: 2)),
        draft:
            'ಧನ್ಯವಾದಗಳು! ಕವಿತೆ ಇಷ್ಟ ಆಯ್ತು ಅಂತ ಕೇಳಿ ಖುಷಿ ಆಯ್ತು. ಮುಂದಿನದು ಬೇಗ ಬರುತ್ತೆ. 🙏',
        draftSource: 'template',
      ),
      InboxItem(
        id: 'm3',
        profileId: 'p-resto',
        platform: PlatformKind.instagram,
        sender: 'Guest',
        text: 'What time do you open?',
        receivedAt: now.subtract(const Duration(hours: 5)),
        draft: draftReply('What time do you open?', training).text,
        draftSource: 'template',
      ),
    ];
    _save();
  }

  // ---- inbox ----
  Future<void> addInbox({
    required String profileId,
    required PlatformKind platform,
    required String sender,
    required String text,
  }) async {
    final profile = profiles.firstWhere((p) => p.id == profileId,
        orElse: () => profiles.first);
    final draft = draftReply(text, training, businessName: profile.name);
    inbox.insert(
      0,
      InboxItem(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        profileId: profileId,
        platform: platform,
        sender: sender.trim().isEmpty ? 'Sender' : sender.trim(),
        text: text.trim(),
        receivedAt: DateTime.now(),
        draft: draft.text,
        draftSource: draft.source,
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> setStatus(InboxItem item, InboxStatus status) async {
    item.status = status;
    await _save();
    notifyListeners();
  }

  Future<void> updateDraft(InboxItem item, String text) async {
    item.editedDraft = text;
    await _save();
    notifyListeners();
  }

  Future<void> deleteInbox(InboxItem item) async {
    inbox.removeWhere((e) => e.id == item.id);
    await _save();
    notifyListeners();
  }

  // ---- training ----
  Future<void> addTraining(String incoming, String reply,
      {String? note}) async {
    training.insert(
      0,
      TrainingExample(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        incoming: incoming.trim(),
        reply: reply.trim(),
        note: note,
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> deleteTraining(TrainingExample ex) async {
    training.removeWhere((e) => e.id == ex.id);
    await _save();
    notifyListeners();
  }

  // ---- profiles ----
  Future<void> addProfile(
      String name, String handle, PlatformKind platform) async {
    profiles.add(AviProfile(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      handle: handle.trim(),
      platform: platform,
      access: approvalDefault ? AccessMode.approval : AccessMode.full,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> deleteProfile(AviProfile p) async {
    profiles.removeWhere((e) => e.id == p.id);
    inbox.removeWhere((e) => e.profileId == p.id);
    await _save();
    notifyListeners();
  }

  Future<void> setAccess(AviProfile p, AccessMode mode) async {
    p.access = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setApprovalDefault(bool v) async {
    approvalDefault = v;
    await _save();
    notifyListeners();
  }
}
