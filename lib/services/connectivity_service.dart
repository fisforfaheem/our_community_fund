import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:our_community_fund/utils/toast_utils.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _wasConnected = true;

  void initialize(BuildContext context) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(context, result);
    });

    // Check initial connection state
    _connectivity.checkConnectivity().then((result) {
      _handleConnectivityChange(context, result, isInitial: true);
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void _handleConnectivityChange(
    BuildContext context,
    List<ConnectivityResult> result, {
    bool isInitial = false,
  }) {
    final isConnected = !result.contains(ConnectivityResult.none);

    // Only show messages for actual changes in connectivity
    if (!isInitial && isConnected != _wasConnected) {
      if (isConnected) {
        ToastUtils.showSuccess(
          context,
          message: 'Back online',
          duration: const Duration(seconds: 2),
        );
      } else {
        ToastUtils.showWarning(
          context,
          message: 'No internet connection',
          duration: const Duration(seconds: 3),
        );
      }
    }

    _wasConnected = isConnected;
  }

  // Helper method to run a function with connectivity check
  Future<T?> withConnectivity<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    if (await isConnected()) {
      try {
        return await action();
      } catch (e) {
        ToastUtils.showError(
          context,
          message: 'Network error: ${e.toString()}',
        );
        return null;
      }
    } else {
      ToastUtils.showWarning(
        context,
        message: 'No internet connection',
      );
      return null;
    }
  }
}
