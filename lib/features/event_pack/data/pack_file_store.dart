import 'package:flutter/widgets.dart';

import '../../../core/utils/cloudinary_image.dart';
import 'pack_file_store_stub.dart'
    if (dart.library.io) 'pack_file_store_io.dart'
    if (dart.library.js_interop) 'pack_file_store_web.dart';

/// The delivery URL used for every event-pack image, both when downloading
/// it ahead of time and when falling back to the network. Capped at 1200px
/// wide, which is more than any in-app image is shown at, so a large upload
/// doesn't cost players a large download.
String packImageUrl(String url) => cloudinaryDeliveryUrl(url, transform: 'f_auto,q_auto,c_limit,w_1200');

/// Where an event's images are kept so the hunt works without signal.
abstract class PackFileStore {
  Future<void> init();

  /// An image provider for the stored copy of [url], or null when there
  /// isn't one on this device.
  ImageProvider? imageFor(String eventId, String url);

  /// Whether [url] is already stored for [eventId].
  bool has(String eventId, String url);

  /// Downloads [url] for [eventId] and returns the bytes fetched. Throws on
  /// failure; a partial download is never reported as stored.
  Future<int> download(String eventId, String url);

  /// Removes stored files for [eventId] that aren't in [keepUrls].
  Future<void> prune(String eventId, Set<String> keepUrls);

  /// Removes everything stored for [eventId].
  Future<void> deleteEvent(String eventId);
}

PackFileStore createPackFileStore() => createPlatformPackFileStore();
