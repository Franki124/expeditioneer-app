import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'features/event_pack/data/pack_file_store.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline play: keep every event document on the device (no size-based
  // eviction) and queue writes made without signal. On by default on
  // Android/iOS, off by default on web.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    webPersistentTabManager: WebPersistentMultipleTabManager(),
  );
  _registerFontLicenses();
  final packFileStore = createPackFileStore();
  await packFileStore.init();
  runApp(ExpeditioneerApp(packFileStore: packFileStore));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [('Cinzel', 'Cinzel-OFL.txt'), ('EB Garamond', 'EBGaramond-OFL.txt')]) {
      final license = await rootBundle.loadString('assets/licenses/$file');
      yield LicenseEntryWithLineBreaks([font], license);
    }
  });
}
