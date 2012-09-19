// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * A [Duration] represents a time span. A duration can be negative.
 */
class Duration implements Comparable, Hashable {
  static const int MILLISECONDS_PER_SECOND = 1000;
  static const int SECONDS_PER_MINUTE = 60;
  static const int MINUTES_PER_HOUR = 60;
  static const int HOURS_PER_DAY = 24;

  static const int MILLISECONDS_PER_MINUTE =
      MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE;
  static const int MILLISECONDS_PER_HOUR =
      MILLISECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int MILLISECONDS_PER_DAY =
      MILLISECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;

  /**
   * This [Duration] in milliseconds.
   */
  final int inMilliseconds;

  /**
   * The duration is the sum of all individual parts. This means that individual
   * parts don't need to be less than the next-bigger unit. For example [hours]
   * is allowed to have a value greater than 23.
   *
   * All individual parts are allowed to be negative.
   * All arguments are by default 0.
   */
  const Duration({int days: 0,
                  int hours: 0,
                  int minutes: 0,
                  int seconds: 0,
                  int milliseconds: 0})
      : inMilliseconds = days * Duration.MILLISECONDS_PER_DAY +
                         hours * Duration.MILLISECONDS_PER_HOUR +
                         minutes * Duration.MILLISECONDS_PER_MINUTE +
                         seconds * Duration.MILLISECONDS_PER_SECOND +
                         milliseconds;

  /**
   * This [Duration] in days. Incomplete days are discarded
   */
  int get inDays {
    return inMilliseconds ~/ Duration.MILLISECONDS_PER_DAY;
  }

  /**
   * This [Duration] in hours. Incomplete hours are discarded.
   * The returned value can be greater than 23.
   */
  int get inHours {
    return inMilliseconds ~/ Duration.MILLISECONDS_PER_HOUR;
  }

  /**
   * This [Duration] in minutes. Incomplete minutes are discarded.
   * The returned value can be greater than 59.
   */
  int get inMinutes {
    return inMilliseconds ~/ Duration.MILLISECONDS_PER_MINUTE;
  }

  /**
   * This [Duration] in seconds. Incomplete seconds are discarded.
   * The returned value can be greater than 59.
   */
  int get inSeconds {
    return inMilliseconds ~/ Duration.MILLISECONDS_PER_SECOND;
  }

  bool operator ==(other) {
    if (other is !Duration) return false;
    return inMilliseconds == other.inMilliseconds;
  }

  int hashCode() {
    return inMilliseconds.hashCode();
  }

  int compareTo(Duration other) {
    return inMilliseconds.compareTo(other.inMilliseconds);
  }

  String toString() {
    String threeDigits(int n) {
      if (n >= 100) return "$n";
      if (n > 10) return "0$n";
      return "00$n";
    }
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    if (inMilliseconds < 0) {
      Duration duration =
          new Duration(milliseconds: -inMilliseconds);
      return "-$duration";
    }
    String twoDigitMinutes =
        twoDigits(inMinutes.remainder(Duration.MINUTES_PER_HOUR));
    String twoDigitSeconds =
        twoDigits(inSeconds.remainder(Duration.SECONDS_PER_MINUTE));
    String threeDigitMs =
        threeDigits(inMilliseconds.remainder(Duration.MILLISECONDS_PER_SECOND));
    return "$inHours:$twoDigitMinutes:$twoDigitSeconds.$threeDigitMs";
  }
}
