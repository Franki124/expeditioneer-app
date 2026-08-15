import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/event.dart';

class EventRepository {
  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  Future<Event?> getEventByJoinCode(String joinCode) async {
    final query =
        await _events.where('joinCode', isEqualTo: joinCode).limit(1).get();
    if (query.docs.isEmpty) return null;
    return Event.fromDoc(query.docs.first);
  }

  Stream<Event?> watchEvent(String eventId) {
    return _events
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? Event.fromDoc(doc) : null);
  }
}
