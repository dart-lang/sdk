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

import 'package:clock/clock.dart';

import 'core.dart';

/// Destination for progress and build status updates.
enum ProgressOutput {
  /// Write progress and status updates to [stdout].
  stdout,

  /// Write progress and status updates to [stderr].
  stderr,

  /// Suppress progress and status updates.
  none,
}

/// Runs [callback] while displaying a live-updating progress indicator.
///
/// The [message] is shown to the user, followed by "..." and a timer.
/// The progress indicator is only animated if output is going to a terminal
/// that supports ANSI escape codes. When [callback] completes, the progress
/// indicator is stopped and the final time is shown.
///
/// [output] controls whether progress updates are written to [stdout],
/// [stderr], or suppressed ([ProgressOutput.none]). If omitted, [output]
/// defaults to the active [DartdevLogger.output] in the current [Zone] (and is
/// always [ProgressOutput.none] if the zone logger is configured with
/// [ProgressOutput.none]).
Future<T> progress<T>(
  String message,
  FutureOr<T> Function() callback, {
  ProgressOutput? output,
}) {
  final currentOutput = dartdevLogger.output;
  final effectiveOutput = currentOutput == ProgressOutput.none
      ? ProgressOutput.none
      : (output ?? currentOutput);
  if (effectiveOutput == ProgressOutput.none) {
    return Future.sync(callback);
  }
  stopActiveProgress();
  final progress = _Progress(
    message,
    effectiveOutput == ProgressOutput.stderr,
  );
  return Future.sync(callback).whenComplete(progress._stop);
}

_Progress? _activeProgress;

/// Stops animating any currently active progress indicator.
void stopActiveProgress() {
  if (_activeProgress != null) {
    _activeProgress!._stopAnimating();
    _activeProgress = null;
  }
}

/// A live-updating progress indicator for long-running log entries.
final class _Progress {
  /// Whether progress updates should be printed to [stderr] instead of [stdout].
  final bool _progressUpdatesOnStderr;

  /// The timer used to write "..." during a progress log.
  Timer? _timer;

  /// The [Stopwatch] used to track how long a progress log has been running.
  ///
  /// Backed by the current [clock], so tests can control elapsed time.
  final _stopwatch = clock.stopwatch();

  /// The message displayed for this progress indicator.
  final String _message;

  /// Gets the current progress time as a parenthesized, formatted string.
  String get _time => '(${_niceDuration(_stopwatch.elapsed)})';

  /// The length of the most recently-printed [_time] string.
  var _timeLength = 0;

  /// The output sink for progress updates.
  IOSink get _sink => _progressUpdatesOnStderr ? stderr : stdout;

  /// Creates a new progress indicator.
  _Progress(this._message, this._progressUpdatesOnStderr) {
    _stopwatch.start();

    // The animation is only shown when it would be meaningful to a human.
    // That means we're writing a visible message to a TTY at normal log levels
    // with ANSI support and non-JSON output.
    if (!_canUseAnsiCodes(_progressUpdatesOnStderr)) {
      // Not animating, so just log the start and wait until the task is
      // completed.
      _sink.writeln('$_message...');
      return;
    }

    _activeProgress = this;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _update();
    });

    _sink.write('$_message... ');
  }

  /// Stops animating the progress indicator.
  void _stopAnimating() {
    if (_timer == null) return;
    _sink.write('\r$_message... $_eraseToLineEnd');
    _sink.writeln();
    _timeLength = 0;
    _timer!.cancel();
    _timer = null;
  }

  /// Stops the progress indicator.
  void _stop() {
    if (identical(_activeProgress, this)) _activeProgress = null;
    _stopwatch.stop();
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
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
    _sink.write(_grayText(time, _progressUpdatesOnStderr));
  }
}

/// Returns a human-friendly representation of [duration].
String _niceDuration(Duration duration) {
  final hasMinutes = duration.inMinutes > 0;
  final result = hasMinutes ? '${duration.inMinutes}:' : '';

  final s = duration.inSeconds % 60;
  final ms = duration.inMilliseconds % 1000;

  final msString = (ms ~/ 100).toString();

  return "$result${hasMinutes ? s.toString().padLeft(2, '0') : s}"
      '.${msString}s';
}

/// Wraps [text] in the ANSI escape codes to make it gray when on a platform
/// that supports that.
///
/// Honors the `NO_COLOR` convention (https://no-color.org): when the
/// `NO_COLOR` environment variable is set, [text] is returned uncolored.
/// `NO_COLOR` only affects colors, not the cursor-control sequences used to
/// animate the progress indicator.
String _grayText(String text, bool progressUpdatesOnStderr) {
  if (_noColor || !_canUseAnsiCodes(progressUpdatesOnStderr)) return text;
  return '\u001b[38;5;245m$text\u001b[0m';
}

/// ANSI escape sequence erasing from the cursor to the end of the line.
const _eraseToLineEnd = '\u001b[0K';

/// Whether the `NO_COLOR` environment variable is set.
bool get _noColor => Platform.environment.containsKey('NO_COLOR');

/// Whether the sink for progress updates is a terminal that supports ANSI
/// escape codes.
bool _canUseAnsiCodes(bool progressUpdatesOnStderr) {
  final sink = progressUpdatesOnStderr ? stderr : stdout;
  return sink.hasTerminal && sink.supportsAnsiEscapes;
}
