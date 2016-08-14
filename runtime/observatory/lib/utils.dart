// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:math';

class Utils {

  static String formatPercentNormalized(double x) {
    var percent = 100.0 * x;
    return '${percent.toStringAsFixed(2)}%';
  }

  static String formatPercent(num a, num total) {
    return formatPercentNormalized(a / total);
  }

  static String zeroPad(int value, int pad) {
    String prefix = "";
    while (pad > 1) {
      int pow10 = pow(10, pad - 1);
      if (value < pow10) {
        prefix = prefix + "0";
      }
      pad--;
    }
    return "${prefix}${value}";
  }

  static String formatCommaSeparated(int v) {
    const COMMA_EVERY = 1000;
    if (v < COMMA_EVERY) {
      return v.toString();
    }
    var mod = v % COMMA_EVERY;
    v ~/= COMMA_EVERY;
    var r = '${zeroPad(mod, 3)}';
    while (v > COMMA_EVERY) {
      mod = v % COMMA_EVERY;
      r = '${zeroPad(mod, 3)},$r';
      v ~/= COMMA_EVERY;
    }
    if (v != 0) {
      r = '$v,$r';
    }
    return r;
  }

  static String formatTimePrecise(double time) {
    if (time == null) {
      return "-";
    }
    const millisPerSecond = 1000;

    var millis = (time * millisPerSecond).round();
    return formatTimeMilliseconds(millis);
  }

  static String formatTimeMilliseconds(int millis) {
    const millisPerHour = 60 * 60 * 1000;
    const millisPerMinute = 60 * 1000;
    const millisPerSecond = 1000;

    var hours = millis ~/ millisPerHour;
    millis = millis % millisPerHour;

    var minutes = millis ~/ millisPerMinute;
    millis = millis % millisPerMinute;

    var seconds = millis ~/ millisPerSecond;
    millis = millis % millisPerSecond;

    if (hours > 0) {
      return ("${zeroPad(hours,2)}"
               ":${zeroPad(minutes,2)}"
               ":${zeroPad(seconds,2)}"
               ".${zeroPad(millis,3)}");
    } else if (minutes > 0) {
      return ("${zeroPad(minutes,2)}"
              ":${zeroPad(seconds,2)}"
              ".${zeroPad(millis,3)}");
    } else {
      return ("${zeroPad(seconds,2)}"
              ".${zeroPad(millis,3)}");
    }
  }

  static String formatSize(int bytes) {
    const int digits = 1;
    const int bytesPerKB = 1024;
    const int bytesPerMB = 1024 * bytesPerKB;
    const int bytesPerGB = 1024 * bytesPerMB;
    const int bytesPerTB = 1024 * bytesPerGB;

    if (bytes < bytesPerKB) {
      return "${bytes}B";
    } else if (bytes < bytesPerMB) {
      return "${(bytes / bytesPerKB).toStringAsFixed(digits)}KB";
    } else if (bytes < bytesPerGB) {
      return "${(bytes / bytesPerMB).toStringAsFixed(digits)}MB";
    } else if (bytes < bytesPerTB) {
      return "${(bytes / bytesPerGB).toStringAsFixed(digits)}GB";
    } else {
      return "${(bytes / bytesPerTB).toStringAsFixed(digits)}TB";
    }
  }

  static String formatTime(double time) {
    if (time == null) {
      return "-";
    }
    const millisPerHour = 60 * 60 * 1000;
    const millisPerMinute = 60 * 1000;
    const millisPerSecond = 1000;

    var millis = (time * millisPerSecond).round();

    var hours = millis ~/ millisPerHour;
    millis = millis % millisPerHour;

    var minutes = millis ~/ millisPerMinute;
    millis = millis % millisPerMinute;

    var seconds = millis ~/ millisPerSecond;

    if (hours != 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes != 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static String formatDateTime(DateTime now) {
    return '${now.year}-${now.month}-${now.day} '
           '${now.hour.toString().padLeft(2)}:'
           '${now.minute.toString().padLeft(2)}:'
           '${now.second.toString().padLeft(2)}';
  }

  static String formatSeconds(double x) {
    return x.toStringAsFixed(2);
  }

  static String formatDurationInSeconds(Duration x) {
    return formatSeconds(x.inMilliseconds / Duration.MILLISECONDS_PER_SECOND);
  }

  static bool runningInJavaScript() => identical(1.0, 1);
}

/// A [Task] that can be scheduled on the Dart event queue.
class Task {
  Timer _timer;
  final Function callback;

  Task(this.callback);

  /// Queue [this] to run on the next Dart event queue pump. Does nothing
  /// if [this] is already queued.
  queue() {
    if (_timer != null) {
      // Already scheduled.
      return;
    }
    _timer = new Timer(Duration.ZERO, () {
     _timer = null;
     callback();
    });
  }
}
