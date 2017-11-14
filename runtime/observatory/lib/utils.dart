// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:math';

enum DurationComponent {
  Days,
  Hours,
  Minutes,
  Seconds,
  Milliseconds,
  Microseconds
}

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

  static String formatDuration(Duration duration,
      {DurationComponent precision = DurationComponent.Microseconds,
      String future = '',
      String past = 'ago'}) {
    var value = duration.inMicroseconds.abs();
    switch (precision) {
      case DurationComponent.Days:
        value = (value / Duration.microsecondsPerDay).round();
        break;
      case DurationComponent.Hours:
        value = (value / Duration.microsecondsPerHour).round();
        break;
      case DurationComponent.Minutes:
        value = (value / Duration.microsecondsPerMinute).round();
        break;
      case DurationComponent.Seconds:
        value = (value / Duration.microsecondsPerSecond).round();
        break;
      case DurationComponent.Milliseconds:
        value = (value / Duration.microsecondsPerMillisecond).round();
        break;
      case DurationComponent.Microseconds:
        break;
    }
    final components = <String>[];
    if (duration.isNegative) {
      if (!past.isEmpty) {
        components.add(past);
      }
    } else {
      if (!future.isEmpty) {
        components.add(future);
      }
    }
    switch (precision) {
      case DurationComponent.Microseconds:
        components.add('${value % Duration.microsecondsPerMillisecond}μs');
        value = (value / Duration.microsecondsPerMillisecond).floor();
        if (value != 0) {
          continue Milliseconds;
        }
        break;
      Milliseconds:
      case DurationComponent.Milliseconds:
        components.add('${value % Duration.millisecondsPerSecond}ms');
        value = (value / Duration.millisecondsPerSecond).floor();
        if (value != 0) {
          continue Seconds;
        }
        break;
      Seconds:
      case DurationComponent.Seconds:
        components.add('${value % Duration.secondsPerMinute}s');
        value = (value / Duration.secondsPerMinute).floor();
        ;
        if (value != 0) {
          continue Minutes;
        }
        break;
      Minutes:
      case DurationComponent.Minutes:
        components.add('${value % Duration.minutesPerHour}m');
        value = (value / Duration.minutesPerHour).floor();
        if (value != 0) {
          continue Hours;
        }
        break;
      Hours:
      case DurationComponent.Hours:
        components.add('${value % Duration.hoursPerDay}h');
        value = (value / Duration.hoursPerDay).floor();
        if (value != 0) {
          continue Days;
        }
        break;
      Days:
      case DurationComponent.Days:
        components.add('${value}d');
    }
    return components.reversed.join(' ');
  }

  static String formatSeconds(double x) {
    return x.toStringAsFixed(2);
  }

  static String formatMillis(double x) {
    return x.toStringAsFixed(2);
  }

  static String formatDurationInSeconds(Duration x) =>
      formatSeconds(x.inMicroseconds / Duration.microsecondsPerSecond);

  static String formatDurationInMilliseconds(Duration x) =>
      formatMillis(x.inMicroseconds / Duration.microsecondsPerMillisecond);

  static bool runningInJavaScript() => identical(1.0, 1);

  static formatStringAsLiteral(String value, [bool wasTruncated = false]) {
    var result = new List();
    result.add("'".codeUnitAt(0));
    for (int codeUnit in value.codeUnits) {
      if (codeUnit == '\n'.codeUnitAt(0))
        result.addAll('\\n'.codeUnits);
      else if (codeUnit == '\r'.codeUnitAt(0))
        result.addAll('\\r'.codeUnits);
      else if (codeUnit == '\f'.codeUnitAt(0))
        result.addAll('\\f'.codeUnits);
      else if (codeUnit == '\b'.codeUnitAt(0))
        result.addAll('\\b'.codeUnits);
      else if (codeUnit == '\t'.codeUnitAt(0))
        result.addAll('\\t'.codeUnits);
      else if (codeUnit == '\v'.codeUnitAt(0))
        result.addAll('\\v'.codeUnits);
      else if (codeUnit == '\$'.codeUnitAt(0))
        result.addAll('\\\$'.codeUnits);
      else if (codeUnit == '\\'.codeUnitAt(0))
        result.addAll('\\\\'.codeUnits);
      else if (codeUnit == "'".codeUnitAt(0))
        result.addAll("'".codeUnits);
      else if (codeUnit < 32) {
        var escapeSequence = "\\u" + codeUnit.toRadixString(16).padLeft(4, "0");
        result.addAll(escapeSequence.codeUnits);
      } else
        result.add(codeUnit);
    }
    if (wasTruncated) {
      result.addAll("...".codeUnits);
    } else {
      result.add("'".codeUnitAt(0));
    }
    return new String.fromCharCodes(result);
  }
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
    _timer = new Timer(Duration.zero, () {
      _timer = null;
      callback();
    });
  }
}
