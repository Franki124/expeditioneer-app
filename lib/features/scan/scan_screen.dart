import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/widgets/motion.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../events/cubit/joined_event_cubit.dart';
import '../events/data/event_repository.dart';
import '../events/data/journal_repository.dart';
import '../events/data/participant_repository.dart';
import '../events/domain/event.dart';
import '../events/domain/journal.dart';
import '../events/widgets/manual_code_entry.dart';
import 'quest_code_resolver.dart';
import 'widgets/camera_access_off_screen.dart';
import 'widgets/viewfinder.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _scanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture, String eventId, String uid, List<Journal> uncollected) async {
    if (_scanning) return;
    final barcodes = capture.barcodes;
    final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    final journal = findMatchingJournal(raw, uncollected);
    if (journal == null) return; // unrecognized code in frame — keep scanning silently

    setState(() => _scanning = true);
    final outcome = await completeQuestFind(context: context, eventId: eventId, uid: uid, journal: journal);
    if (!mounted) return;
    if (outcome == QuestFindOutcome.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your scan — check your connection and try again.")),
      );
    } else if (outcome == QuestFindOutcome.completed) {
      context.pop();
      return;
    }
    setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(backgroundColor: AppColors.navyDeep),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final uid = context.watch<AuthCubit>().state.user?.uid;
    final eventId = context.watch<JoinedEventCubit>().state.joinedEventId;
    if (uid == null || eventId == null) {
      return Center(
        child: Text('Join an event first.', style: AppTypography.body(color: AppColors.creamDim)),
      );
    }

    return StreamBuilder<Event?>(
      stream: context.read<EventRepository>().watchEvent(eventId),
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data;
        if (event == null || !event.isLive) {
          return Center(
            child: Text(
              'This event is no longer active.',
              style: AppTypography.body(color: AppColors.creamDim),
            ),
          );
        }

        return StreamBuilder<List<Journal>>(
          stream: context.read<JournalRepository>().watchJournals(eventId),
          builder: (context, journalsSnapshot) {
            final journals = journalsSnapshot.data ?? const <Journal>[];
            return StreamBuilder<Set<String>>(
              stream: context.read<ParticipantRepository>().watchCollectedJournalIds(eventId, uid),
              builder: (context, collectedSnapshot) {
                final collected = collectedSnapshot.data ?? const <String>{};
                final uncollected = journals.where((j) => !collected.contains(j.id)).toList();
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md20),
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (uncollected.isEmpty)
                          Text(
                            "You've found every quest at this event!",
                            style: AppTypography.body(color: AppColors.creamDim),
                            textAlign: TextAlign.center,
                          )
                        else ...[
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: kIsWeb && MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop
                                  ? AppBreakpoints.scanViewfinderMaxWidth
                                  : double.infinity,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRect(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    MobileScanner(
                                      controller: _controller,
                                      onDetect: (capture) => _handleDetection(capture, eventId, uid, uncollected),
                                      errorBuilder: (context, error) => CameraAccessOffScreen(
                                        onOpenSettings: () => openAppSettings(),
                                        onTryAgain: () => _controller.start(),
                                      ),
                                    ),
                                    const Viewfinder(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md20),
                          TextButton(
                            onPressed: _scanning
                                ? null
                                : () => showManualCodeEntry(
                                      context: context,
                                      eventId: eventId,
                                      uid: uid,
                                      uncollected: uncollected,
                                    ),
                            child: Text('enter code instead', style: AppTypography.label(fontSize: 15)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
