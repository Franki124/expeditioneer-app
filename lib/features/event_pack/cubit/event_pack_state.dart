import 'package:equatable/equatable.dart';

enum EventPackStatus {
  /// No joined event.
  idle,

  /// Fetching event data and downloading images.
  preparing,

  /// Everything the hunt needs is on this device.
  ready,

  /// Something couldn't be fetched; the game still works, missing pieces
  /// need signal.
  incomplete,
}

class EventPackState extends Equatable {
  const EventPackState({
    this.eventId,
    this.status = EventPackStatus.idle,
    this.eventName,
    this.dataReady = false,
    this.questCount = 0,
    this.questionCount = 0,
    this.imagesTotal = 0,
    this.imagesDone = 0,
    this.imagesFailed = 0,
    this.bytesDownloaded = 0,
    this.reachedServer = true,
  });

  final String? eventId;
  final EventPackStatus status;
  final String? eventName;

  /// Event details, quests and every quiz's questions are in the device
  /// cache.
  final bool dataReady;
  final int questCount;
  final int questionCount;
  final int imagesTotal;
  final int imagesDone;
  final int imagesFailed;
  final int bytesDownloaded;

  /// False when the last attempt couldn't reach the server at all.
  final bool reachedServer;

  int get imagesMissing => imagesTotal - imagesDone;

  /// 0..1 across the data step and every image.
  double get progress {
    final steps = 1 + imagesTotal;
    final done = (dataReady ? 1 : 0) + imagesDone;
    return steps == 0 ? 0 : done / steps;
  }

  EventPackState copyWith({
    EventPackStatus? status,
    String? eventName,
    bool? dataReady,
    int? questCount,
    int? questionCount,
    int? imagesTotal,
    int? imagesDone,
    int? imagesFailed,
    int? bytesDownloaded,
    bool? reachedServer,
  }) {
    return EventPackState(
      eventId: eventId,
      status: status ?? this.status,
      eventName: eventName ?? this.eventName,
      dataReady: dataReady ?? this.dataReady,
      questCount: questCount ?? this.questCount,
      questionCount: questionCount ?? this.questionCount,
      imagesTotal: imagesTotal ?? this.imagesTotal,
      imagesDone: imagesDone ?? this.imagesDone,
      imagesFailed: imagesFailed ?? this.imagesFailed,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      reachedServer: reachedServer ?? this.reachedServer,
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    status,
    eventName,
    dataReady,
    questCount,
    questionCount,
    imagesTotal,
    imagesDone,
    imagesFailed,
    bytesDownloaded,
    reachedServer,
  ];
}
