// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Adapted from package:pub lib/src/progress.dart to align progress updates
// visually with pub. It would be better to let pub stream updates to dartdev
// and have dartdev display progress in a consistent way for all kinds of
// progress.
// TODO(https://dartbug.com/61539): Standardize.

import 'dart:async';
import 'dart:io';

/// Runs [callback] while displaying a live-updating progress indicator.
///
/// The [message] is shown to the user, followed by "..." and a timer.
/// The progress indicator is only animated if output is going to a terminal.
/// When the [callback] completes, the progress indicator is stopped and the
/// final time is shown.
Future<T> progress<T>(
  String message,
  Future<T> Function() callback, {
  bool progressUpdatesOnStderr = false,
}) async {
  final progress = _Progress(message, progressUpdatesOnStderr);
  return callback().whenComplete(progress._stop);
}

/// A live-updating progress indicator for long-running log entries.
class _Progress {
  /// Whether progress updates should be printed to [stderr] instead of [stdout].
  final bool _progressUpdatesOnStderr;

  /// The timer used to write "..." during a progress log.
  late final Timer _timer;

  /// The [Stopwatch] used to track how long a progress log has been running.
  final _stopwatch = Stopwatch();

  /// The progress message as it's being incrementally appended.
  ///
  /// When the progress is done, a single entry will be added to the log for it.
  final String _message;

  /// Gets the current progress time as a parenthesized, formatted string.
  String get _time => '(${_niceDuration(_stopwatch.elapsed)})';

  /// The length of the most recently-printed [_time] string.
  var _timeLength = 0;

  /// The output sink for progress updates.
  IOSink get _sink => _progressUpdatesOnStderr ? stderr : stdout;

  /// Whether the output sink should be treated as a terminal.
  bool get _terminalOutput =>
      _progressUpdatesOnStderr ? stderr.hasTerminal : stdout.hasTerminal;

  /// Creates a new progress indicator.
  _Progress(this._message, this._progressUpdatesOnStderr) {
    _stopwatch.start();

    // The animation is only shown when it would be meaningful to a human.
    // That means we're writing a visible message to a TTY at normal log levels
    // with non-JSON output.
    if (!_terminalOutput) {
      // Not animating, so just log the start and wait until the task is
      // completed.
      _sink.write('$_message...');
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _update();
    });

    _sink.write('$_message... ');
  }

  /// Stops the progress indicator.
  void _stop() {
    if (!_terminalOutput) {
      // Not animating, so just log the start and wait until the task is
      // completed.
      _sink.write('$_message...');
      return;
    }

    _stopwatch.stop();
    _timer.cancel();
    // print one final update to show the user the final time.
    _update();
    _sink.writeln();
  }

  /// Refreshes the progress line.
  void _update() {
    // Show the time only once it gets noticeably long.
    if (_stopwatch.elapsed.inSeconds == 0) return;

    // Erase the last time that was printed. Erasing just the time using `\b`
    // rather than using `\r` to erase the entire line ensures that we don't
    // spam progress lines if they're wider than the terminal width.
    _sink.write('\b' * _timeLength);
    final time = _time;
    _timeLength = time.length;
    _sink.write(gray(time, _progressUpdatesOnStderr));
  }
}

/// Returns a human-friendly representation of [duration].
String _niceDuration(Duration duration) {
  final hasMinutes = duration.inMinutes > 0;
  final result = hasMinutes ? '${duration.inMinutes}:' : '';

  final s = duration.inSeconds % 60;
  final ms = duration.inMilliseconds % 1000;

  final msString = (ms ~/ 100).toString();

  return "$result${hasMinutes ? _padLeft(s.toString(), 2, '0') : s}"
      '.${msString}s';
}

/// Pads [source] to [length] by adding [char]s at the beginning.
///
/// If [char] is `null`, it defaults to a space.
String _padLeft(String source, int length, [String char = ' ']) {
  if (source.length >= length) return source;

  return char * (length - source.length) + source;
}

/// Wraps [text] in the ANSI escape codes to make it gray when on a platform
/// that supports that.
///
/// Use this for text that's less important than the text around it.
String gray(String text, bool progressUpdatesOnStderr) =>
    '${_gray(progressUpdatesOnStderr)}$text${_none(progressUpdatesOnStderr)}';

String _none(bool progressUpdatesOnStderr) =>
    _getAnsi('\u001b[0m', progressUpdatesOnStderr);
String _gray(bool progressUpdatesOnStderr) =>
    _getAnsi('\u001b[38;5;245m', progressUpdatesOnStderr);

String _getAnsi(String ansiCode, bool progressUpdatesOnStderr) =>
    canUseAnsiCodes(progressUpdatesOnStderr) ? ansiCode : '';

/// Whether ansi codes such as color escapes are safe to use.
///
/// On a terminal we can use ansi codes also on Windows.
///
/// Tests should make sure to run the subprocess with or without an attached
/// terminal to decide if colors will be provided.
bool canUseAnsiCodes(bool progressUpdatesOnStderr) {
  if (Platform.environment.containsKey('NO_COLOR')) return false;
  if (progressUpdatesOnStderr) {
    return stderr.hasTerminal && stderr.supportsAnsiEscapes;
  } else {
    return stdout.hasTerminal && stdout.supportsAnsiEscapes;
  }
}
