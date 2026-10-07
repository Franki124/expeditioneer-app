import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'pack_file_store.dart';

PackFileStore createPlatformPackFileStore() => IoPackFileStore();

/// Android/iOS: each event's images live in
/// `<app support>/event_packs/<eventId>/<sha1 of url>`.
class IoPackFileStore implements PackFileStore {
  /// [root] is for tests; the app uses the platform's app support folder.
  IoPackFileStore({http.Client? client, Directory? root}) : _client = client ?? http.Client(), _rootOverride = root;

  static const _downloadTimeout = Duration(seconds: 60);

  final http.Client _client;
  final Directory? _rootOverride;
  late final Directory _root;

  @override
  Future<void> init() async {
    final override = _rootOverride;
    if (override != null) {
      _root = override;
      return;
    }
    final support = await getApplicationSupportDirectory();
    _root = Directory('${support.path}/event_packs');
  }

  Directory _eventDir(String eventId) => Directory('${_root.path}/$eventId');

  String _fileName(String url) => sha1.convert(utf8.encode(url)).toString();

  File _fileFor(String eventId, String url) => File('${_eventDir(eventId).path}/${_fileName(url)}');

  @override
  ImageProvider? imageFor(String eventId, String url) {
    final file = _fileFor(eventId, url);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  bool has(String eventId, String url) => _fileFor(eventId, url).existsSync();

  @override
  Future<int> download(String eventId, String url) async {
    final target = _fileFor(eventId, url);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    final response = await _client.get(Uri.parse(packImageUrl(url))).timeout(_downloadTimeout);
    if (response.statusCode != 200) {
      throw HttpException('Download failed (${response.statusCode})', uri: Uri.parse(url));
    }
    // Written beside the target and renamed into place, so an interrupted
    // download never leaves a half file that looks complete.
    await partial.writeAsBytes(response.bodyBytes, flush: true);
    await partial.rename(target.path);
    return response.bodyBytes.length;
  }

  @override
  Future<void> prune(String eventId, Set<String> keepUrls) async {
    final dir = _eventDir(eventId);
    if (!await dir.exists()) return;
    final keep = keepUrls.map(_fileName).toSet();
    await for (final entity in dir.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && !keep.contains(name)) await entity.delete();
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final dir = _eventDir(eventId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
