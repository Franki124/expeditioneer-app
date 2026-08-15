import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges one or more Bloc/Cubit state streams (already broadcast) into
/// go_router's [Listenable]-based `refreshListenable`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Iterable<Stream<dynamic>> streams) {
    _subscriptions = [
      for (final stream in streams) stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
