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

  Progress(this._message) {
    _stopwatch.start();

    if (log.json.enabled) return;

    // Only animate if we're writing to a TTY in human format.
    if (stdioType(stdout) == StdioType.TERMINAL) {
      _update();
      _timer = new Timer.periodic(new Duration(milliseconds: 100), (_) {
        _update();
      });
    } else {
      stdout.write("$_message... ");
    }
  }

  /// Stops the progress indicator.
  ///
  /// Returns the complete final progress message.
  String stop() {
    _stopwatch.stop();

    // If we aren't animating, just log the final time.
    if (log.json.enabled) {
      // Do nothing.
    } else if (_timer == null) {
      stdout.writeln(_time);
    } else {
      _timer.cancel();

      // Show one final update.
      _update();
      stdout.writeln();
    }

    return "$_message... ${_time}";
  }

  /// Gets the current progress time as a parenthesized, formatted string.
  String get _time => "(${niceDuration(_stopwatch.elapsed)})";

  /// Refreshes the progress line.
  void _update() {
    stdout.write("\r$_message... ");

    // Show the time only once it gets noticeably long.
    if (_stopwatch.elapsed.inSeconds > 0) {
      stdout.write(log.gray(_time));
    }
  }
}
