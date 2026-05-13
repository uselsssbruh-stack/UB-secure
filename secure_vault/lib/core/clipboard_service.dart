import 'dart:async';
import 'package:flutter/services.dart';
import '../shared/constants.dart';

/// Manages clipboard operations with automatic clearing
/// to prevent sensitive data from persisting.
class ClipboardService {
  ClipboardService._();

  static Timer? _clearTimer;

  /// Copies text to clipboard and auto-clears after [seconds].
  static Future<void> copyWithAutoClear(
    String text, {
    int seconds = AppConstants.clipboardClearSeconds,
  }) async {
    // Cancel any pending clear
    _clearTimer?.cancel();

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));

    // Schedule auto-clear
    _clearTimer = Timer(Duration(seconds: seconds), () async {
      await Clipboard.setData(ClipboardData(text: ''));
    });
  }

  /// Immediately clears the clipboard.
  static Future<void> clearClipboard() async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: ''));
  }

  /// Cancels any pending clipboard clear timer.
  static void cancelTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
