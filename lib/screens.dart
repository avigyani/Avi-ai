// Avi AI v1 — all screens. Kannada-first labels, Material 3.
//
// MANUAL MODE (v1, honest label on every screen): Messenger and
// WhatsApp have no direct connect for personal profiles, so messages
// are pasted by the user, Avi AI drafts, Abhi approves, and Abhi
// sends it himself in the original app. Nothing auto-sends.
import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';

const _maroon = Color(0xFF7B1E26);
const _cream = Color(0xFFFFF9EF);
const _gold = Color(0xFFB98A2F);

String _time(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

Widget manualBanner() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Manual mode: Messenger / WhatsApp ಗೆ direct connect ಇನ್ನೂ ಇಲ್ಲ. '
        'Message paste ಮಾಡಿ, draft approve ಮಾಡಿ, ನೀವೇ ಆ app ನಲ್ಲಿ send ಮಾಡಿ.',
        style: TextStyle(fontSize: 12.5),
      ),
    );

Widget platformChip(PlatformKind p) => Chip(
      label: Text('${p.kannada} • ${p.label}', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _gold),
    );

Future<void> editDraftDialog(
    BuildContext context, AviStore store, InboxItem item) async {
  final c = TextEditingController(text: item.editedDraft);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Draft edit ಮಾಡಿ'),
      content: TextField(
        controller: c,
        maxLines: 6,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save')),
      ],
    ),
  );
  if (ok == true) {
    await store.updateDraft(item, c.text);
  }
}

// ---------------- Inbox ----------------
class InboxScreen extends StatefulWidget {
  final AviStore store;
  const InboxScreen({super.key, required this.store});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  PlatformKind? filter;

  @override
  Widget build(BuildContext context) {
    final items = widget.store.inbox
        .where((e) => filter == null || e.platform == filter)
        .toList();
    final pending =
        widget.store.inbox.where((e) => e.status == InboxStatus.pending).length;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text('Inbox • $pending ಕಾಯುತ್ತಿದೆ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        manualBanner(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('ಎಲ್ಲಾ', null),
              for (final p in PlatformKind.values)
                _filterChip(p.kannada, p),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('ಇಲ್ಲಿ ಏನೂ ಇಲ್ಲ. Paste tab ನಲ್ಲಿ message ಹಾಕಿ.'))),
        for (final item in items) _inboxCard(context, item),
      ],
    );
  }

  Widget _filterChip(String label, PlatformKind? p) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: filter == p,
          onSelected: (_) => setState(() => filter = p),
        ),
      );

  Widget _inboxCard(BuildContext context, InboxItem item) {
    final store = widget.store;
    final profile = store.profiles.firstWhere((p) => p.id == item.profileId,
        orElse: () => store.profiles.first);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                platformChip(item.platform),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(store.profileName(item.profileId),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(_time(item.receivedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text('From: ${item.sender}  •  ${item.status.kannada}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Text(item.text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _cream, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Avi AI draft',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 6),
                    Chip(
                      label: Text(item.draftSource == 'training'
                          ? 'ನಿನ್ನ training'
                          : 'Template'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 10),
                    ),
                    const Spacer(),
                    if (profile.access == AccessMode.full)
                      const Text('Full access ON',
                          style: TextStyle(fontSize: 11, color: _maroon)),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.editedDraft, style: const TextStyle(fontSize: 14)),
                  if (profile.access == AccessMode.full)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Full access ಇದ್ದರೂ v1 ನಲ್ಲಿ auto-send ಇಲ್ಲ — direct connect ಬಂದಮೇಲೆ ಮಾತ್ರ. ಈಗ approve ಮಾಡಿ ನೀವೇ send ಮಾಡಿ.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (item.status == InboxStatus.pending) ...[
                  FilledButton(
                    onPressed: () async {
                      await store.setStatus(item, InboxStatus.approved);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Approved ✓ — ಈಗ ${item.platform.label} ನಲ್ಲಿ ನೀವೇ send ಮಾಡಿ.')));
                      }
                    },
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () => editDraftDialog(context, store, item),
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () => store.setStatus(item, InboxStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ] else ...[
                  if (item.status == InboxStatus.approved)
                    FilledButton.tonal(
                      onPressed: () async {
                        await store.setStatus(
                            item, InboxStatus.sentManually);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Sent ಎಂದು ಗುರುತಾಯ್ತು ✓')));
                        }
                      },
                      child: const Text('ನಾನು send ಮಾಡಿದೆ'),
                    ),
                  TextButton(
                    onPressed: () => store.deleteInbox(item),
                    child: const Text('Delete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Compose / Paste ----------------
class ComposeScreen extends StatefulWidget {
  final AviStore store;
  final void Function() onAdded;
  const ComposeScreen({super.key, required this.store, required this.onAdded});
  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late String profileId;
  PlatformKind platform = PlatformKind.whatsapp;
  final sender = TextEditingController();
  final message = TextEditingController();

  @override
  void initState() {
    super.initState();
    profileId = widget.store.profiles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Message paste ಮಾಡಿ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        manualBanner(),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: profileId,
          decoration: const InputDecoration(
              labelText: 'Profile', border: OutlineInputBorder()),
          items: widget.store.profiles
              .map((p) => DropdownMenuItem(
                  value: p.id, child: Text('${p.name} (${p.handle})')))
              .toList(),
          onChanged: (v) => setState(() => profileId = v!),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<PlatformKind>(
          initialValue: platform,
          decoration: const InputDecoration(
              labelText: 'Platform', border: OutlineInputBorder()),
          items: PlatformKind.values
              .map((p) => DropdownMenuItem(
                  value: p, child: Text('${p.kannada} • ${p.label}')))
              .toList(),
          onChanged: (v) => setState(() => platform = v!),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: sender,
          decoration: const InputDecoration(
              labelText: 'Sender ಹೆಸರು (optional)',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: message,
          maxLines: 5,
          decoration: const InputDecoration(
              labelText: 'ಬಂದ message ಇಲ್ಲಿ paste ಮಾಡಿ',
              hintText: 'ಉದಾ: Table book madbeku, 4 people',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: message.text.trim().isEmpty
              ? null
              : () async {
                  await widget.store.addInbox(
                    profileId: profileId,
                    platform: platform,
                    sender: sender.text,
                    text: message.text,
                  );
                  message.clear();
                  sender.clear();
                  widget.onAdded();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Inbox ಗೆ ಸೇರಿತು ✓ Draft ready.')));
                  }
                },
          child: const Text('Draft ಮಾಡಿ → Inbox ಗೆ ಹಾಕಿ'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Draft ಮೊದಲು ನಿನ್ನ training examples ನಿಂದ ಬರುತ್ತೆ, ಸಿಗದಿದ್ದರೆ Kannada template ಬರುತ್ತೆ. ಯಾವುದೂ auto-send ಆಗಲ್ಲ.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

// ---------------- Train ----------------
class TrainScreen extends StatefulWidget {
  final AviStore store;
  const TrainScreen({super.key, required this.store});
  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  final incoming = TextEditingController();
  final reply = TextEditingController();
  final note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Avi AI ಗೆ ಕಲಿಸಿ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'ನೀನು ಹೇಳಿಕೊಟ್ಟ ಮಾತಿನಂತೇ Avi AI reply ಮಾಡುತ್ತೆ. ಬಂದ message ತರದ್ದು + ನಿನ್ನ ಉತ್ತರ ಹಾಕಿ.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: incoming,
          decoration: const InputDecoration(
              labelText: 'ಬಂದ message (ಉದಾ: Table book madbeku)',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: reply,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'ನಿನ್ನ ಉತ್ತರ (Avi AI ಇದೇ ತರ ಬರೆಯಬೇಕು)',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: note,
          decoration: const InputDecoration(
              labelText: 'Note (optional)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () async {
            if (incoming.text.trim().isEmpty ||
                reply.text.trim().isEmpty) {
              return;
            }
            await widget.store.addTraining(incoming.text, reply.text,
                note: note.text.isEmpty ? null : note.text);
            incoming.clear();
            reply.clear();
            note.clear();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Training ಸೇರಿತು ✓')));
            }
          },
          child: const Text('Add training'),
        ),
        const SizedBox(height: 16),
        Text('Training examples (${widget.store.training.length})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final ex in widget.store.training)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('Q: ${ex.incoming}'),
              subtitle: Text('A: ${ex.reply}'
                  '${ex.note == null ? '' : '\nNote: ${ex.note}'}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => widget.store.deleteTraining(ex),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Profiles ----------------
class ProfilesScreen extends StatefulWidget {
  final AviStore store;
  const ProfilesScreen({super.key, required this.store});
  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final name = TextEditingController();
  final handle = TextEditingController();
  PlatformKind platform = PlatformKind.instagram;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Profiles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'ಪ್ರತಿ profile ಗೂ Approval / Full access ಬೇರೆ ಬೇರೆ ಇಡಬಹುದು. '
          'Full access ಕೊಟ್ಟರೂ v1 ನಲ್ಲಿ auto-send ಇಲ್ಲ — direct connect ಬಂದಮೇಲೆ ಮಾತ್ರ.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        for (final p in widget.store.profiles)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    platformChip(p.platform),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => widget.store.deleteProfile(p),
                    ),
                  ]),
                  Text(p.handle, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  SegmentedButton<AccessMode>(
                    segments: const [
                      ButtonSegment(
                          value: AccessMode.approval,
                          label: Text('Approval ಮಾತ್ರ')),
                      ButtonSegment(
                          value: AccessMode.full, label: Text('Full access')),
                    ],
                    selected: {p.access},
                    onSelectionChanged: (s) =>
                        widget.store.setAccess(p, s.first),
                  ),
                ],
              ),
            ),
          ),
        const Divider(),
        const Text('ಹೊಸ profile ಸೇರಿಸಿ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: name,
          decoration: const InputDecoration(
              labelText: 'ಹೆಸರು', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: handle,
          decoration: const InputDecoration(
              labelText: 'Handle / username', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<PlatformKind>(
          initialValue: platform,
          decoration: const InputDecoration(
              labelText: 'Platform', border: OutlineInputBorder()),
          items: PlatformKind.values
              .map((p) => DropdownMenuItem(
                  value: p, child: Text('${p.kannada} • ${p.label}')))
              .toList(),
          onChanged: (v) => setState(() => platform = v!),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            await widget.store
                .addProfile(name.text, handle.text, platform);
            name.clear();
            handle.clear();
          },
          child: const Text('Add profile'),
        ),
      ],
    );
  }
}

// ---------------- Settings ----------------
class SettingsScreen extends StatelessWidget {
  final AviStore store;
  const SettingsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Approval-only (default)'),
            subtitle: const Text(
                'ON ಇದ್ದರೆ ಹೊಸ profile ಗಳಿಗೆ approval ಬೇಕು. OFF ಮಾಡಿದರೆ Full access default.'),
            value: store.approvalDefault,
            onChanged: (v) => store.setApprovalDefault(v),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('ಭಾಷೆ / Language'),
            subtitle: Text('ಕನ್ನಡ ಮೊದಲು, English ಜೊತೆ. Kannada-first labels.'),
            leading: Icon(Icons.language),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('Privacy — ಫೋನ್ memory touch ಮಾಡಲ್ಲ'),
            subtitle: Text(
                'ಈ app ಫೋನ್ internal memory / files open ಮಾಡಲ್ಲ, scan ಮಾಡಲ್ಲ, storage permission ಕೇಳಲ್ಲ. ನೀನು type / paste ಮಾಡಿದ್ದು ಮಾತ್ರ phone ನಲ್ಲಿ save ಆಗುತ್ತೆ.'),
            leading: Icon(Icons.lock_outline),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('Direct connect status'),
            subtitle: Text(
                'Facebook personal Messenger: Meta official API ಇಲ್ಲ, Muse connect 2026-11-21 ರಲ್ಲಿ "something wrong" fail ಆಯ್ತು. WhatsApp personal: official API ಇಲ್ಲ, Business API ಮಾತ್ರ. ಅದಕ್ಕೆ v1 manual mode.'),
            leading: Icon(Icons.info_outline),
          ),
        ),
        const Card(
          child: ListTile(
            title: Text('Avi AI ಬಗ್ಗೆ'),
            subtitle: Text(
                'Version 1.0.0 • Flutter • Avi AI — Abhi ಗಾಗಿ. Draft ಮಾತ್ರ ಮಾಡುತ್ತೆ, send ಮಾಡಲ್ಲ.'),
            leading: Icon(Icons.smart_toy_outlined),
          ),
        ),
      ],
    );
  }
}
