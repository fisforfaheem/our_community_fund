import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'toast_utils.dart';

class ErrorUtils {
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  static String getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this operation.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'A document with the same ID already exists.';
      case 'failed-precondition':
        return 'Operation failed due to the current state of the system.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Operation was attempted past the valid range.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'data-loss':
        return 'Unrecoverable data loss or corruption.';
      case 'unauthenticated':
        return 'User is not authenticated. Please log in.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  static void handleError(
    BuildContext context,
    dynamic error, {
    String? fallbackMessage,
  }) {
    String message;

    if (error is FirebaseAuthException) {
      message = getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      message = getFirestoreErrorMessage(error.code);
    } else {
      message =
          fallbackMessage ?? 'An unexpected error occurred. Please try again.';
    }

    ToastUtils.showError(context, message: message);
  }

  static void showNetworkError(BuildContext context) {
    ToastUtils.showError(
      context,
      message: 'Network error. Please check your internet connection.',
    );
  }

  static void showUnexpectedError(BuildContext context) {
    ToastUtils.showError(
      context,
      message: 'An unexpected error occurred. Please try again.',
    );
  }

  static void showPermissionDenied(BuildContext context) {
    ToastUtils.showError(
      context,
      message: 'You do not have permission to perform this operation.',
    );
  }

  static void showValidationError(BuildContext context, String message) {
    ToastUtils.showWarning(context, message: message);
  }

  static void showSessionExpired(BuildContext context) {
    ToastUtils.showWarning(
      context,
      message: 'Your session has expired. Please log in again.',
    );
  }

  static void showMaintenanceMode(BuildContext context) {
    ToastUtils.showInfo(
      context,
      message:
          'The app is currently under maintenance. Please try again later.',
    );
  }

  static void showVersionUpdateRequired(BuildContext context) {
    ToastUtils.showInfo(
      context,
      message:
          'A new version of the app is available. Please update to continue.',
    );
  }
}
