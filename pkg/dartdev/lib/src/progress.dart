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

import 'package:cli_util/cli_logging.dart' as cli_logging;
import 'package:clock/clock.dart';
import 'package:pub/pub.dart';

import 'core.dart';

/// The shared progress grace period instance for dartdev.
final progressGracePeriod = ProgressGracePeriod();

/// Resets the shared grace period timer.
void resetProgressGracePeriod() {
  progressGracePeriod.reset();
}

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
/// that supports ANSI escape codes.
///
/// If [transient] is `true`, the progress indicator is erased from the terminal
/// when [callback] completes (and omitted entirely when ANSI escape codes are
/// not supported). By default, transient progress is only shown after the
/// shared [progressGracePeriod] (500ms since program start or last
/// non-progress output), unless overridden by [delay].
///
/// If [transient] is `false`, the progress indicator is stopped and the final
/// time is shown on completion. If omitted, [transient] defaults to the active
/// [DartdevLogger.transientProgress] in the current [Zone].
///
/// [output] controls whether progress updates are written to [stdout],
/// [stderr], or suppressed ([ProgressOutput.none]). If omitted, [output]
/// defaults to the active [DartdevLogger.output] in the current [Zone] (and is
/// always [ProgressOutput.none] if the zone logger is configured with
/// [ProgressOutput.none]).
Future<T> progress<T>(
  String message,
  FutureOr<T> Function() callback, {
  bool? transient,
  ProgressOutput? output,
  Duration? delay,
}) {
  final currentOutput = dartdevLogger.output;
  final effectiveOutput = currentOutput == ProgressOutput.none
      ? ProgressOutput.none
      : (output ?? currentOutput);
  if (effectiveOutput == ProgressOutput.none) {
    return Future.sync(callback);
  }
  stopActiveProgress();
  final effectiveTransient = transient ?? dartdevLogger.transientProgress;
  final effectiveDelay =
      delay ??
      (effectiveTransient ? progressGracePeriod.remainingDelay : Duration.zero);
  final progress = _Progress(
    message,
    effectiveOutput == ProgressOutput.stderr,
    transient: effectiveTransient,
    delay: effectiveDelay,
  );
  return Future.sync(
    callback,
  ).whenComplete(
    effectiveTransient ? progress._stopAndClear : progress._stop,
  );
}

/// Starts a live-updating progress indicator and returns its
/// [cli_logging.Progress] handle.
///
/// Prefer [progress] when wrapping a callback.
cli_logging.Progress startProgress(
  String message, {
  bool? transient,
  ProgressOutput? output,
}) {
  final currentOutput = dartdevLogger.output;
  final effectiveOutput = currentOutput == ProgressOutput.none
      ? ProgressOutput.none
      : (output ?? currentOutput);
  if (effectiveOutput != ProgressOutput.none) {
    stopActiveProgress();
  }
  final effectiveTransient = transient ?? dartdevLogger.transientProgress;
  final effectiveDelay = effectiveTransient
      ? progressGracePeriod.remainingDelay
      : Duration.zero;
  return _Progress(
    message,
    effectiveOutput == ProgressOutput.stderr,
    transient: effectiveTransient,
    delay: effectiveDelay,
    suppressed: effectiveOutput == ProgressOutput.none,
  );
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
final class _Progress implements cli_logging.Progress {
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

  @override
  String get message => _message;

  @override
  Duration get elapsed => _stopwatch.elapsed;

  /// Gets the current progress time as a parenthesized, formatted string.
  String get _time => '(${_niceDuration(_stopwatch.elapsed)})';

  /// The length of the most recently-printed [_time] string.
  var _timeLength = 0;

  /// Whether the initial start message has been printed.
  var _hasStarted = false;

  /// The output sink for progress updates.
  IOSink get _sink => _progressUpdatesOnStderr ? stderr : stdout;

  /// Whether this progress indicator is transient (erased upon completion).
  final bool _transient;

  /// Whether all output of this progress indicator is suppressed.
  final bool _suppressed;

  /// Creates a new progress indicator.
  _Progress(
    this._message,
    this._progressUpdatesOnStderr, {
    bool transient = false,
    Duration delay = Duration.zero,
    bool suppressed = false,
  }) : _transient = transient,
       _suppressed = suppressed {
    _stopwatch.start();
    if (suppressed) {
      return;
    }

    // The animation is only shown when it would be meaningful to a human.
    // That means we're writing a visible message to a TTY at normal log levels
    // with ANSI support and non-JSON output.
    if (!_canUseAnsiCodes(_progressUpdatesOnStderr)) {
      if (transient) {
        // In non-terminal mode or without ANSI, transient progress produces no output.
        return;
      }
      // Not animating, so just log the start and wait until the task is
      // completed.
      _sink.writeln('$_message...');
      resetProgressGracePeriod();
      return;
    }

    _activeProgress = this;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_stopwatch.elapsed < delay) return;
      if (!_hasStarted) {
        _sink.write('$_message... ');
        _hasStarted = true;
        progressGracePeriod.markProgressShown();
      }
      _update();
    });

    if (delay == Duration.zero) {
      _sink.write('$_message... ');
      _hasStarted = true;
      progressGracePeriod.markProgressShown();
    }
  }

  /// Erases the progress message from the terminal.
  void _erase() {
    _sink.write('\r$_eraseLine');
  }

  /// Stops animating the progress indicator.
  void _stopAnimating() {
    if (_timer == null) return;
    if (_hasStarted) {
      if (_transient) {
        _erase();
      } else {
        _sink.write('\r$_message... $_eraseToLineEnd');
        _sink.writeln();
        resetProgressGracePeriod();
      }
    }
    _timeLength = 0;
    _timer!.cancel();
    _timer = null;
  }

  /// Stops the progress indicator, leaving its line on the terminal.
  ///
  /// The final elapsed time is shown if [showTiming] is `true`; otherwise any
  /// time shown by the animation is erased.
  void _stop({bool showTiming = true}) {
    if (identical(_activeProgress, this)) _activeProgress = null;
    _stopwatch.stop();
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    if (!_hasStarted) return;
    if (showTiming) {
      // Print one final update to show the user the final time.
      _update();
    } else if (_timeLength > 0) {
      // Erase the time shown by the animation.
      _sink.write('\r$_message... $_eraseToLineEnd');
      _timeLength = 0;
    }
    _sink.writeln();
    resetProgressGracePeriod();
  }

  /// Stops the progress indicator and erases it from the terminal.
  void _stopAndClear() {
    if (identical(_activeProgress, this)) _activeProgress = null;
    _stopwatch.stop();
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      if (_hasStarted) {
        _erase();
      }
    }
  }

  /// Stops the progress indicator.
  ///
  /// A transient indicator is erased from the terminal. Otherwise its line is
  /// left on the terminal, showing the final elapsed time if [showTiming] is
  /// `true`. A [message], if given, is then written on a line of its own
  /// (unless progress output is suppressed).
  @override
  void finish({String? message, bool showTiming = false}) {
    if (_transient) {
      _stopAndClear();
    } else {
      _stop(showTiming: showTiming);
    }
    if (message != null && !_suppressed) {
      _sink.writeln(message);
      resetProgressGracePeriod();
    }
  }

  /// Stops the progress indicator and erases it from the terminal.
  @override
  void cancel() {
    _stopAndClear();
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

/// ANSI escape sequence erasing the entire current line.
const _eraseLine = '\u001b[2K';

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
