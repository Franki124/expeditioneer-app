import 'package:expeditioneer_journal/features/events/domain/journal.dart';
import 'package:expeditioneer_journal/features/scan/quest_code_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Journal _journal(String id, String code) =>
    Journal(id: id, title: id, blurb: '', order: 0, artUrl: '', type: QuestType.journal, manualCode: code);

void main() {
  final journals = [_journal('a', 'TRV294'), _journal('b', 'MSK101')];

  test('a code for an uncollected quest is a new quest', () {
    final match = classifyScannedCode('trv-294', journals: journals, collectedIds: {'b'});
    expect(match.kind, ScannedCodeKind.newQuest);
    expect(match.journal?.id, 'a');
  });

  test('a code for a collected quest is already found', () {
    final match = classifyScannedCode('MSK101', journals: journals, collectedIds: {'b'});
    expect(match.kind, ScannedCodeKind.alreadyFound);
    expect(match.journal?.id, 'b');
  });

  test('a code from outside the game is unknown', () {
    final match = classifyScannedCode('https://example.com/menu', journals: journals, collectedIds: {});
    expect(match.kind, ScannedCodeKind.unknown);
    expect(match.journal, isNull);
  });
}
