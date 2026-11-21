// Avi AI v1 — draft engine. Pure Dart, no network, no API key.
//
// Rule 1: Abhi's training examples win. The incoming message is
// matched against his examples by word overlap; the best match
// above the threshold is returned verbatim (his words, his style).
// Rule 2: if nothing matches, a neutral Kannada-first template
// reply is used, chosen by simple intent keywords.
// Nothing here ever sends anything — it only returns a draft string.
import 'models.dart';

class DraftResult {
  final String text;
  final String source; // 'training' or 'template'
  final String? matchedExampleId;

  const DraftResult({
    required this.text,
    required this.source,
    this.matchedExampleId,
  });
}

List<String> _tokens(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((t) => t.length > 1)
    .toList();

double _overlap(String a, String b) {
  final at = _tokens(a).toSet();
  final bt = _tokens(b).toSet();
  if (at.isEmpty || bt.isEmpty) return 0;
  final shared = at.intersection(bt).length;
  // Score against the shorter side so short messages still match.
  final denom = at.length < bt.length ? at.length : bt.length;
  return shared / denom;
}

const double _trainingThreshold = 0.25;

DraftResult draftReply(
  String incoming,
  List<TrainingExample> training, {
  String businessName = 'Secrets of Ocean',
}) {
  final text = incoming.trim();
  if (text.isEmpty) {
    return const DraftResult(
      text: 'ನಮಸ್ಕಾರ! ನಿಮ್ಮ ಸಂದೇಶ ಸಿಕ್ಕಿದೆ, ಸ್ವಲ್ಪ ಹೊತ್ತಿನಲ್ಲಿ ಉತ್ತರ ಕೊಡ್ತೀನಿ.',
      source: 'template',
    );
  }

  // 1) Training examples first.
  TrainingExample? best;
  double bestScore = 0;
  for (final ex in training) {
    final score = _overlap(text, ex.incoming);
    if (score > bestScore) {
      bestScore = score;
      best = ex;
    }
  }
  if (best != null && bestScore >= _trainingThreshold) {
    return DraftResult(
      text: best.reply,
      source: 'training',
      matchedExampleId: best.id,
    );
  }

  // 2) Intent templates (Kannada-first, short, polite).
  final lower = text.toLowerCase();
  bool hasAny(List<String> words) =>
      words.any((w) => lower.contains(w));

  if (hasAny(['book', 'table', 'booking', 'reserve', 'ಬುಕ್', 'ಟೇಬಲ್'])) {
    return DraftResult(
      text:
          'ನಮಸ್ಕಾರ! $businessName ನಲ್ಲಿ ಟೇಬಲ್ ಬುಕ್ ಮಾಡೋಕೆ ಖುಷಿ ಆಗುತ್ತೆ. ಎಷ್ಟು ಜನ, ಯಾವ ದಿನ ಮತ್ತು ಯಾವ ಸಮಯ ಅಂತ ಹೇಳಿ, ನಾನು confirm ಮಾಡ್ತೀನಿ.',
      source: 'template',
    );
  }
  if (hasAny(['price', 'cost', 'rate', 'menu', 'ಬೆಲೆ', 'ಮೆನು', 'ದರ'])) {
    return const DraftResult(
      text:
          'ನಮಸ್ಕಾರ! ಮೆನು ಮತ್ತು ಬೆಲೆ ವಿವರ ಕಳುಹಿಸ್ತೀನಿ. ನಿಮಗೆ veg ಬೇಕಾ, non-veg ಬೇಕಾ ಅಂತ ಹೇಳಿ, ಅದಕ್ಕೆ ತಕ್ಕಂತೆ suggest ಮಾಡ್ತೀನಿ.',
      source: 'template',
    );
  }
  if (hasAny(['timing', 'open', 'close', 'hours', 'ಟೈಮ್', 'ತೆರೆದ', 'ಸಮಯ'])) {
    return DraftResult(
      text:
          'ನಮಸ್ಕಾರ! $businessName ಮಧ್ಯಾಹ್ನ 12:00 ರಿಂದ ರಾತ್ರಿ 11:00 ವರೆಗೆ ತೆರೆದಿರುತ್ತೆ. ಬರುವ ಮೊದಲು ಒಮ್ಮೆ ಹೇಳಿದರೆ ಟೇಬಲ್ ready ಇಡ್ತೀನಿ.',
      source: 'template',
    );
  }
  if (hasAny(['location', 'address', 'where', 'reach', 'ವಿಳಾಸ', 'ಎಲ್ಲಿ', 'ದಾರಿ'])) {
    return DraftResult(
      text:
          'ನಮಸ್ಕಾರ! $businessName, Acharya College Main Road, Chikkabanavara, Bengaluru ನಲ್ಲಿದೆ. Location ಬೇಕಾದರೆ ಕಳುಹಿಸ್ತೀನಿ.',
      source: 'template',
    );
  }
  if (hasAny(['party', 'event', 'birthday', 'celebrat', 'ಪಾರ್ಟಿ', 'ಹುಟ್ಟುಹಬ್ಬ'])) {
    return const DraftResult(
      text:
          'ನಮಸ್ಕಾರ! ಪಾರ್ಟಿ / celebration ಗೆ party hall ಇದೆ, event booking ಜೊತೆ hall free. ಎಷ್ಟು ಜನ, ಯಾವ ದಿನ ಅಂತ ಹೇಳಿ, details ಕಳುಹಿಸ್ತೀನಿ.',
      source: 'template',
    );
  }
  if (hasAny(['thank', 'thanks', 'ಧನ್ಯವಾದ', 'ಥ್ಯಾಂಕ್ಸ್'])) {
    return const DraftResult(
      text: 'ಧನ್ಯವಾದಗಳು! ಮತ್ತೆ ಬನ್ನಿ, ನಿಮ್ಮನ್ನು ನೋಡೋಕೆ ಖುಷಿ ಆಗುತ್ತೆ. 🙏',
      source: 'template',
    );
  }
  if (hasAny(['hi', 'hello', 'hey', 'ನಮಸ್ಕಾರ', 'ಹಾಯ್'])) {
    return const DraftResult(
      text:
          'ನಮಸ್ಕಾರ! ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ? ಟೇಬಲ್ ಬುಕಿಂಗ್, ಮೆನು, ಅಥವಾ ಪಾರ್ಟಿ — ಏನು ಬೇಕೋ ಹೇಳಿ.',
      source: 'template',
    );
  }

  // 3) Neutral fallback — never invents facts, never confirms a booking.
  return const DraftResult(
    text:
        'ನಮಸ್ಕಾರ! ನಿಮ್ಮ ಸಂದೇಶ ಸಿಕ್ಕಿದೆ. ಸ್ವಲ್ಪ ವಿವರ ಕೊಟ್ಟರೆ ಸರಿಯಾಗಿ ಸಹಾಯ ಮಾಡ್ತೀನಿ — ಏನು ಬೇಕು ಅಂತ ಹೇಳಿ.',
    source: 'template',
  );
}
