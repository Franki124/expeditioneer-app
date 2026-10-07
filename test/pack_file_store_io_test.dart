import 'dart:io';

import 'package:expeditioneer_journal/features/event_pack/data/pack_file_store_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('event_packs_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<IoPackFileStore> storeWith(MockClient client) async {
    final store = IoPackFileStore(client: client, root: root);
    await store.init();
    return store;
  }

  test('downloads an image and serves it from the device afterwards', () async {
    final requested = <Uri>[];
    final store = await storeWith(
      MockClient((request) async {
        requested.add(request.url);
        return http.Response.bytes([1, 2, 3], 200);
      }),
    );
    const url = 'https://res.cloudinary.com/demo/image/upload/v1/a.jpg';

    expect(store.has('e1', url), isFalse);
    expect(store.imageFor('e1', url), isNull);

    final bytes = await store.download('e1', url);

    expect(bytes, 3);
    expect(store.has('e1', url), isTrue);
    expect(store.imageFor('e1', url), isNotNull);
    expect(requested.single.toString(), contains('c_limit,w_1200'));
  });

  test('a failed download leaves nothing stored', () async {
    final store = await storeWith(MockClient((request) async => http.Response('nope', 503)));
    const url = 'https://example.com/a.jpg';

    await expectLater(store.download('e1', url), throwsA(isA<HttpException>()));
    expect(store.has('e1', url), isFalse);
  });

  test('prune keeps only the listed images and deleteEvent removes the rest', () async {
    final store = await storeWith(MockClient((request) async => http.Response.bytes([1], 200)));
    await store.download('e1', 'https://example.com/keep.jpg');
    await store.download('e1', 'https://example.com/old.jpg');

    await store.prune('e1', {'https://example.com/keep.jpg'});
    expect(store.has('e1', 'https://example.com/keep.jpg'), isTrue);
    expect(store.has('e1', 'https://example.com/old.jpg'), isFalse);

    await store.deleteEvent('e1');
    expect(store.has('e1', 'https://example.com/keep.jpg'), isFalse);
  });
}
