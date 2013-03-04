// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [Duration] represents a time span. A duration can be negative.
 */
class Duration implements Comparable<Duration> {
  static const int MICROSECONDS_PER_MILLISECOND = 1000;
  static const int MILLISECONDS_PER_SECOND = 1000;
  static const int SECONDS_PER_MINUTE = 60;
  static const int MINUTES_PER_HOUR = 60;
  static const int HOURS_PER_DAY = 24;

  static const int MICROSECONDS_PER_SECOND =
      MICROSECONDS_PER_MILLISECOND * MILLISECONDS_PER_SECOND;
  static const int MICROSECONDS_PER_MINUTE =
      MICROSECONDS_PER_SECOND * SECONDS_PER_MINUTE;
  static const int MICROSECONDS_PER_HOUR =
      MICROSECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int MICROSECONDS_PER_DAY =
      MICROSECONDS_PER_HOUR * HOURS_PER_DAY;


  static const int MILLISECONDS_PER_MINUTE =
      MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE;
  static const int MILLISECONDS_PER_HOUR =
      MILLISECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int MILLISECONDS_PER_DAY =
      MILLISECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;

  static const Duration ZERO = const Duration(seconds: 0);

  /**
   * This [Duration] in microseconds.
   */
  final int _duration;

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
                  int milliseconds: 0,
                  int microseconds: 0})
      : _duration = days * MICROSECONDS_PER_DAY +
                    hours * MICROSECONDS_PER_HOUR +
                    minutes * MICROSECONDS_PER_MINUTE +
                    seconds * MICROSECONDS_PER_SECOND +
                    milliseconds * MICROSECONDS_PER_MILLISECOND +
                    microseconds;

  /**
   * Returns the sum of this [Duration] and [other]  as a new [Duration].
   */
  Duration operator +(Duration other) {
    return new Duration(microseconds: _duration + other._duration);
  }

  /**
   * Returns the difference of this [Duration] and [other] as a new
   * [Duration].
   */
  Duration operator -(Duration other) {
    return new Duration(microseconds: _duration - other._duration);
  }

  /**
   * Multiplies this [Duration] by the given [factor] and returns the result
   * as a new [Duration].
   */
  Duration operator *(int factor) {
    return new Duration(microseconds: _duration * factor);
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
    return new Duration(microseconds: _duration ~/ quotient);
  }

  bool operator <(Duration other) => this._duration < other._duration;

  bool operator >(Duration other) => this._duration > other._duration;

  bool operator <=(Duration other) => this._duration <= other._duration;

  bool operator >=(Duration other) => this._duration >= other._duration;

  /**
   * This [Duration] in days. Incomplete days are discarded
   */
  int get inDays => _duration ~/ Duration.MICROSECONDS_PER_DAY;

  /**
   * This [Duration] in hours. Incomplete hours are discarded.
   *
   * The returned value can be greater than 23.
   */
  int get inHours => _duration ~/ Duration.MICROSECONDS_PER_HOUR;

  /**
   * This [Duration] in minutes. Incomplete minutes are discarded.
   *
   * The returned value can be greater than 59.
   */
  int get inMinutes => _duration ~/ Duration.MICROSECONDS_PER_MINUTE;

  /**
   * This [Duration] in seconds. Incomplete seconds are discarded.
   *
   * The returned value can be greater than 59.
   */
  int get inSeconds => _duration ~/ Duration.MICROSECONDS_PER_SECOND;

  /**
   * This [Duration] in milliseconds. Incomplete milliseconds are discarded.
   *
   * The returned value can be greater than 999.
   */
  int get inMilliseconds => _duration ~/ Duration.MICROSECONDS_PER_MILLISECOND;

  /**
   * This [Duration] in microseconds.
   */
  int get inMicroseconds => _duration;

  bool operator ==(other) {
    if (other is !Duration) return false;
    return _duration == other._duration;
  }

  int get hashCode => _duration.hashCode;

  int compareTo(Duration other) => _duration.compareTo(other._duration);

  String toString() {
    String sixDigits(int n) {
      if (n >= 100000) return "$n";
      if (n >= 10000) return "0$n";
      if (n >= 1000) return "00$n";
      if (n >= 100) return "000$n";
      if (n > 10) return "0000$n";
      return "00000$n";
    }
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    if (inMicroseconds < 0) {
      Duration duration =
          new Duration(microseconds: -inMicroseconds);
      return "-$duration";
    }
    String twoDigitMinutes = twoDigits(inMinutes.remainder(MINUTES_PER_HOUR));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(SECONDS_PER_MINUTE));
    String sixDigitUs =
        sixDigits(inMicroseconds.remainder(MICROSECONDS_PER_SECOND));
    return "$inHours:$twoDigitMinutes:$twoDigitSeconds.$sixDigitUs";
  }
}
