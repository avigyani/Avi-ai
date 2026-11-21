import 'package:avi_ai/draft_engine.dart';
import 'package:avi_ai/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final training = [
    TrainingExample(
      id: 't1',
      incoming: 'Table book madbeku',
      reply: 'ನಮಸ್ಕಾರ! ಟೇಬಲ್ ಬುಕ್ ಮಾಡೋಕೆ ಖುಷಿ ಆಗುತ್ತೆ.',
    ),
    TrainingExample(
      id: 't2',
      incoming: 'Menu price heli',
      reply: 'ನಮಸ್ಕಾರ! ಮೆನು ಕಳುಹಿಸ್ತೀನಿ.',
    ),
  ];

  test('training example wins on close match', () {
    final r = draftReply('Table book madbeku, 4 people tonight', training);
    expect(r.source, 'training');
    expect(r.text, contains('ಟೇಬಲ್ ಬುಕ್'));
  });

  test('template used for timing question with no training match', () {
    final r = draftReply('What time do you open?', training);
    expect(r.source, 'template');
    expect(r.text, contains('12:00'));
  });

  test('neutral fallback for unrelated message', () {
    final r = draftReply('random xyz qqq', training);
    expect(r.source, 'template');
    expect(r.text, contains('ನಮಸ್ಕಾರ'));
  });
}
