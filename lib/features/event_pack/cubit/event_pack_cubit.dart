import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/connectivity_cubit.dart';
import '../../events/cubit/joined_event_cubit.dart';
import '../../events/data/event_repository.dart';
import '../../events/domain/event.dart';
import '../data/event_pack_repository.dart';
import '../data/pack_file_store.dart';
import 'event_pack_state.dart';

/// Keeps the joined event's "pack" — its quests, quiz questions and images —
/// on the device so the hunt works without signal. Prepares it when an event
/// is joined (and on every app start), refreshes it when the admin console
/// bumps the event's `contentVersion`, retries when the connection comes
/// back, and deletes it when the player leaves.
class EventPackCubit extends Cubit<EventPackState> {
  EventPackCubit({
    required this._repository,
    required this._fileStore,
    required this._eventRepository,
    required JoinedEventCubit joinedEventCubit,
    required ConnectivityCubit connectivityCubit,
  }) : super(const EventPackState()) {
    _joinedSubscription = joinedEventCubit.stream
        .map((state) => state.joinedEventId)
        .distinct()
        .listen(_onJoinedEventChanged);
    _connectivitySubscription = connectivityCubit.stream.distinct().listen((online) {
      if (online && state.status == EventPackStatus.incomplete) prepare();
    });
    _onJoinedEventChanged(joinedEventCubit.state.joinedEventId);
  }

  static const _downloadWorkers = 3;
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 3)];

  final EventPackRepository _repository;
  final PackFileStore _fileStore;
  final EventRepository _eventRepository;
  late final StreamSubscription<String?> _joinedSubscription;
  late final StreamSubscription<bool> _connectivitySubscription;
  StreamSubscription<Event?>? _eventSubscription;

  /// Bumped whenever a run starts or the event changes; a run that finds it
  /// changed stops emitting.
  int _generation = 0;
  int? _preparedVersion;
  bool _rerunRequested = false;

  void _onJoinedEventChanged(String? eventId) {
    final previous = state.eventId;
    if (eventId == previous) return;
    _generation++;
    _preparedVersion = null;
    _rerunRequested = false;
    _eventSubscription?.cancel();
    _eventSubscription = null;
    if (previous != null) unawaited(_fileStore.deleteEvent(previous));

    emit(EventPackState(eventId: eventId));
    if (eventId == null) return;

    _eventSubscription = _eventRepository.watchEvent(eventId).listen(_onEventUpdated, onError: (_) {});
    prepare();
  }

  void _onEventUpdated(Event? event) {
    if (event == null || isClosed) return;
    if (state.eventName != event.name) emit(state.copyWith(eventName: event.name));
    final prepared = _preparedVersion;
    if (prepared == null || event.contentVersion <= prepared) return;
    if (state.status == EventPackStatus.preparing) {
      _rerunRequested = true;
    } else {
      prepare();
    }
  }

  /// Fetches whatever is missing. Safe to call repeatedly; a call while a
  /// run is in progress is ignored.
  Future<void> prepare() async {
    final eventId = state.eventId;
    if (eventId == null || state.status == EventPackStatus.preparing) return;
    final generation = ++_generation;
    bool stale() => isClosed || generation != _generation;

    emit(EventPackState(eventId: eventId, status: EventPackStatus.preparing, eventName: state.eventName));

    EventPackContent? content;
    var fromServer = false;
    try {
      content = await _repository.load(eventId, source: Source.server).timeout(const Duration(seconds: 30));
      fromServer = content != null;
    } catch (_) {
      // Offline or a timeout — fall back to what's already on the device.
    }
    if (content == null) {
      try {
        content = await _repository.load(eventId, source: Source.cache);
      } catch (_) {}
    }
    if (stale()) return;

    if (content == null) {
      emit(state.copyWith(status: EventPackStatus.incomplete, reachedServer: fromServer));
      return;
    }

    final urls = content.imageUrls;
    final missing = Queue.of(urls.where((url) => !_fileStore.has(eventId, url)));
    emit(
      state.copyWith(
        eventName: content.event.name,
        dataReady: fromServer || content.hasAllQuestions,
        questCount: content.journals.length,
        questionCount: content.questionCount,
        imagesTotal: urls.length,
        imagesDone: urls.length - missing.length,
        reachedServer: fromServer,
      ),
    );

    if (fromServer) {
      Future<void> worker() async {
        while (missing.isNotEmpty) {
          final url = missing.removeFirst();
          final bytes = await _downloadWithRetry(eventId, url);
          if (stale()) return;
          emit(
            bytes == null
                ? state.copyWith(imagesFailed: state.imagesFailed + 1)
                : state.copyWith(imagesDone: state.imagesDone + 1, bytesDownloaded: state.bytesDownloaded + bytes),
          );
        }
      }

      await Future.wait([for (var i = 0; i < _downloadWorkers; i++) worker()]);
      if (stale()) return;
      await _fileStore.prune(eventId, urls);
      _preparedVersion = content.event.contentVersion;
    } else {
      // No point trying downloads that can't reach the server.
      emit(state.copyWith(imagesFailed: missing.length));
    }
    if (stale()) return;

    final complete = state.dataReady && state.imagesMissing == 0;
    emit(state.copyWith(status: complete ? EventPackStatus.ready : EventPackStatus.incomplete));

    if (_rerunRequested) {
      _rerunRequested = false;
      unawaited(prepare());
    }
  }

  Future<int?> _downloadWithRetry(String eventId, String url) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _fileStore.download(eventId, url);
      } catch (_) {
        if (attempt >= _retryDelays.length) return null;
        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }
  }

  @override
  Future<void> close() {
    _joinedSubscription.cancel();
    _connectivitySubscription.cancel();
    _eventSubscription?.cancel();
    return super.close();
  }
}
