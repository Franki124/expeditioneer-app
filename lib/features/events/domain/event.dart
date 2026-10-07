import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  const Event({
    required this.id,
    required this.name,
    required this.location,
    required this.joinCode,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.journalCount,
    this.maxParticipants,
    this.contentVersion = 0,
  });

  final String id;
  final String name;
  final String location;
  final String joinCode;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // draft | live | closed | archived
  final int journalCount;
  final int? maxParticipants;

  /// Bumped by the admin console whenever a quest, quiz question or image
  /// changes, so a player's downloaded event pack knows to refresh.
  final int contentVersion;

  bool get isLive => status == 'live';

  factory Event.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Event(
      id: doc.id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      joinCode: data['joinCode'] as String? ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'draft',
      journalCount: (data['journalCount'] as num?)?.toInt() ?? 0,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt(),
      contentVersion: (data['contentVersion'] as num?)?.toInt() ?? 0,
    );
  }
}
