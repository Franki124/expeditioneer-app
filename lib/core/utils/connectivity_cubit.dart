import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(true) {
    _connectivity.checkConnectivity().then((results) => emit(_isOnline(results)));
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => emit(_isOnline(results)),
    );
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
