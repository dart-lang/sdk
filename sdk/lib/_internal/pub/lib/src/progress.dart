// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.progress;

import 'dart:async';
import 'dart:io';

import 'log.dart' as log;
import 'utils.dart';

/// A live-updating progress indicator for long-running log entries.
class Progress {
  /// The timer used to write "..." during a progress log.
  Timer _timer;

  /// The [Stopwatch] used to track how long a progress log has been running.
  final _stopwatch = new Stopwatch();

  /// The progress message as it's being incrementally appended. When the
  /// progress is done, a single entry will be added to the log for it.
  final String _message;

  /// Gets the current progress time as a parenthesized, formatted string.
  String get _time => "(${niceDuration(_stopwatch.elapsed)})";

  /// Creates a new progress indicator.
  ///
  /// If [fine] is passed, this will log progress messages on [log.Level.FINE]
  /// as opposed to [log.Level.MESSAGE].
  Progress(this._message, {bool fine: false}) {
    _stopwatch.start();

    var level = fine ? log.Level.FINE : log.Level.MESSAGE;

    // The animation is only shown when it would be meaningful to a human.
    // That means we're writing a visible message to a TTY at normal log levels
    // with non-JSON output.
    if (stdioType(stdout) != StdioType.TERMINAL ||
        !log.verbosity.isLevelVisible(level) ||
        log.json.enabled || fine ||
        log.verbosity.isLevelVisible(log.Level.FINE)) {
      // Not animating, so just log the start and wait until the task is
      // completed.
      log.write(level, "$_message...");
      return;
    }

    _update();
    _timer = new Timer.periodic(new Duration(milliseconds: 100), (_) {
      _update();
    });
  }

  /// Stops the progress indicator.
  void stop() {
    _stopwatch.stop();

    // Always log the final time as [log.fine] because for the most part normal
    // users don't care about the precise time information beyond what's shown
    // in the animation.
    log.fine("$_message finished $_time.");

    // If we were animating, print one final update to show the user the final
    // time.
    if (_timer == null) return;
    _timer.cancel();
    _timer = null;
    _update();
    stdout.writeln();
  }

  /// Stop animating the progress indicator.
  ///
  /// This will continue running the stopwatch so that the full time can be
  /// logged in [stop].
  void stopAnimating() {
    if (_timer == null) return;

    // Print a final message without a time indicator so that we don't leave a
    // misleading half-complete time indicator on the console.
    stdout.writeln("\r$_message...");
    _timer.cancel();
    _timer = null;
  }

  /// Refreshes the progress line.
  void _update() {
    stdout.write("\r$_message... ");

    // Show the time only once it gets noticeably long.
    if (_stopwatch.elapsed.inSeconds > 0) {
      stdout.write(log.gray(_time));
    }
  }
}
