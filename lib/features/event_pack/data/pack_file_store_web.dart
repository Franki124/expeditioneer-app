import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'pack_file_store.dart';

PackFileStore createPlatformPackFileStore() => WebPackFileStore();

/// Web: there's no file system to write to, so a "download" fetches the
/// image once, leaving it in the browser's HTTP cache, where the same URL
/// loaded by `Image.network` later finds it. Best effort: the browser may
/// evict it, and the app itself still needs a connection to load, so this
/// only helps while the tab stays open.
class WebPackFileStore implements PackFileStore {
  WebPackFileStore({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Set<String>> _fetched = {};

  @override
  Future<void> init() async {}

  @override
  ImageProvider? imageFor(String eventId, String url) => null;

  @override
  bool has(String eventId, String url) => _fetched[eventId]?.contains(url) ?? false;

  @override
  Future<int> download(String eventId, String url) async {
    final response = await _client.get(Uri.parse(packImageUrl(url))).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception('Download failed (${response.statusCode})');
    _fetched.putIfAbsent(eventId, () => {}).add(url);
    return response.bodyBytes.length;
  }

  @override
  Future<void> prune(String eventId, Set<String> keepUrls) async {
    _fetched[eventId]?.removeWhere((url) => !keepUrls.contains(url));
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _fetched.remove(eventId);
  }
}
