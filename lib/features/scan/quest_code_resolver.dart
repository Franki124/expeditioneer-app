import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/reveal_modal.dart';
import '../events/data/participant_repository.dart';
import '../events/domain/journal.dart';
import '../quiz/presentation/quiz_flow_screen.dart';

/// Finds the uncollected journal whose manual/QR code matches [raw], or null
/// if nothing matches (an unrecognized code, or someone else's marker).
Journal? findMatchingJournal(String raw, List<Journal> uncollected) {
  for (final journal in uncollected) {
    if (journal.matchesManualCode(raw)) return journal;
  }
  return null;
}

/// How a scanned code relates to the joined event's quests.
enum ScannedCodeKind {
  /// Matches a quest the player hasn't collected yet.
  newQuest,

  /// Matches a quest the player has already collected.
  alreadyFound,

  /// Matches nothing at this event — a QR from somewhere else entirely, or
  /// another event's marker.
  unknown,
}

class ScannedCodeMatch {
  const ScannedCodeMatch(this.kind, [this.journal]);

  final ScannedCodeKind kind;

  /// The matched quest; null when [kind] is [ScannedCodeKind.unknown].
  final Journal? journal;
}

/// Classifies [raw] against every quest at the event, so the scan screen can
/// tell "not part of the game" apart from "you've already found this one".
ScannedCodeMatch classifyScannedCode(
  String raw, {
  required List<Journal> journals,
  required Set<String> collectedIds,
}) {
  for (final journal in journals) {
    if (!journal.matchesManualCode(raw)) continue;
    return collectedIds.contains(journal.id)
        ? ScannedCodeMatch(ScannedCodeKind.alreadyFound, journal)
        : ScannedCodeMatch(ScannedCodeKind.newQuest, journal);
  }
  return const ScannedCodeMatch(ScannedCodeKind.unknown);
}

/// What happened after handing a matched [Journal] to [completeQuestFind] —
/// callers use this to decide their own follow-up navigation (e.g. whether
/// to pop their own screen).
enum QuestFindOutcome { completed, quizNotFinished, error }

/// Resolves a matched quest exactly the same way regardless of how it was
/// found — a real camera scan or manual code entry both end up here once
/// they've matched a code against `Journal.matchesManualCode`. A quiz hands
/// off to the quiz flow (it only "completes" once every question is
/// answered — see `ParticipantRepository.submitQuizAnswer`); everything else
/// records the scan and shows [RevealModal].
///
/// [beforeNavigate] fires right before the quiz flow is pushed, or right
/// after a successful non-quiz recordScan just before the reveal dialog
/// opens. The manual-code entry dialog uses it to close itself first — two
/// dialogs stacked on top of each other looks wrong. The camera scan screen
/// doesn't need it, since it isn't itself a dialog.
Future<QuestFindOutcome> completeQuestFind({
  required BuildContext context,
  required String eventId,
  required String uid,
  required Journal journal,
  VoidCallback? beforeNavigate,
}) async {
  if (journal.type == QuestType.quiz) {
    beforeNavigate?.call();
    if (!context.mounted) return QuestFindOutcome.quizNotFinished;
    final finished = await showQuizFlow(context, eventId: eventId, uid: uid, journal: journal);
    return finished ? QuestFindOutcome.completed : QuestFindOutcome.quizNotFinished;
  }

  try {
    await context.read<ParticipantRepository>().recordScan(
          eventId: eventId,
          uid: uid,
          journalId: journal.id,
        );
  } catch (_) {
    return QuestFindOutcome.error;
  }

  if (!context.mounted) return QuestFindOutcome.completed;
  beforeNavigate?.call();
  if (!context.mounted) return QuestFindOutcome.completed;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => RevealModal(
      journal: journal,
      onAddToJournal: () => Navigator.of(dialogContext).pop(),
    ),
  );
  return QuestFindOutcome.completed;
}
