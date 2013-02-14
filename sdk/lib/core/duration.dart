// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [Duration] represents a time span. A duration can be negative.
 */
class Duration implements Comparable {
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
   * Returns the sum of this [Duration] and [other]  as a new [Duration].
   */
  Duration operator +(Duration other) {
    return new Duration(milliseconds: inMilliseconds + other.inMilliseconds);
  }

  /**
   * Returns the difference of this [Duration] and [other] as a new
   * [Duration].
   */
  Duration operator -(Duration other) {
    return new Duration(milliseconds: inMilliseconds - other.inMilliseconds);
  }

  /**
   * Multiplies this [Duration] by the given [factor] and returns the result
   * as a new [Duration].
   */
  Duration operator *(int factor) {
    return new Duration(milliseconds: inMilliseconds * factor);
  }

  /**
   * Divides this [Duration] by the given [quotient] and returns the truncated
   * result as a new [Duration].
   *
   * Throws an [IntegerDivisionByZeroException] if [quotient] is `0`.
   */
  Duration operator ~/(int quotient) {
    // By doing the check here instead of relying on "~/" below we get the
    // exception even with dart2js.
    if (quotient == 0) throw new IntegerDivisionByZeroException();
    return new Duration(milliseconds: inMilliseconds ~/ quotient);
  }

  bool operator <(Duration other) => this.inMilliseconds < other.inMilliseconds;

  bool operator >(Duration other) => this.inMilliseconds > other.inMilliseconds;

  bool operator <=(Duration other) =>
      this.inMilliseconds <= other.inMilliseconds;

  bool operator >=(Duration other) =>
      this.inMilliseconds >= other.inMilliseconds;

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

  int get hashCode {
    return inMilliseconds.hashCode;
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
