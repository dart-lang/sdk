// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

/**
 * A span of time, such as 27 days, 4 hours, 12 minutes, and 3 seconds.
 *
 * A `Duration` represents a difference from one point in time to another. The
 * duration may be "negative" if the difference is from a later time to an
 * earlier.
 *
 * Durations are context independent. For example, a duration of 2 days is
 * always 48 hours, even when it is added to a `DateTime` just when the
 * time zone is about to do a daylight-savings switch. (See [DateTime.add]).
 *
 * Despite the same name, a `Duration` object does not implement "Durations"
 * as specified by ISO 8601. In particular, a duration object does not keep
 * track of the individually provided members (such as "days" or "hours"), but
 * only uses these arguments to compute the length of the corresponding time
 * interval.
 *
 * To create a new Duration object, use this class's single constructor
 * giving the appropriate arguments:
 *
 *     Duration fastestMarathon = new Duration(hours:2, minutes:3, seconds:2);
 *
 * The [Duration] is the sum of all individual parts.
 * This means that individual parts can be larger than the next-bigger unit.
 * For example, [inMinutes] can be greater than 59.
 *
 *     assert(fastestMarathon.inMinutes == 123);
 *
 * All individual parts are allowed to be negative.
 *
 * Use one of the properties, such as [inDays],
 * to retrieve the integer value of the Duration in the specified time unit.
 * Note that the returned value is rounded down.
 * For example,
 *
 *     Duration aLongWeekend = new Duration(hours:88);
 *     assert(aLongWeekend.inDays == 3);
 *
 * This class provides a collection of arithmetic
 * and comparison operators,
 * plus a set of constants useful for converting time units.
 *
 * See [DateTime] to represent a point in time.
 * See [Stopwatch] to measure time-spans.
 *
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
  static const int MICROSECONDS_PER_DAY = MICROSECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int MILLISECONDS_PER_MINUTE =
      MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE;
  static const int MILLISECONDS_PER_HOUR =
      MILLISECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int MILLISECONDS_PER_DAY = MILLISECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static const int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;

  static const int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;

  static const Duration ZERO = const Duration(seconds: 0);

  /*
   * The value of this Duration object in microseconds.
   */
  final int _duration;

  /**
   * Creates a new Duration object whose value
   * is the sum of all individual parts.
   *
   * Individual parts can be larger than the next-bigger unit.
   * For example, [hours] can be greater than 23.
   *
   * All individual parts are allowed to be negative.
   * All arguments are 0 by default.
   */
  const Duration(
      {int days: 0,
      int hours: 0,
      int minutes: 0,
      int seconds: 0,
      int milliseconds: 0,
      int microseconds: 0})
      : this._microseconds(MICROSECONDS_PER_DAY * days +
            MICROSECONDS_PER_HOUR * hours +
            MICROSECONDS_PER_MINUTE * minutes +
            MICROSECONDS_PER_SECOND * seconds +
            MICROSECONDS_PER_MILLISECOND * milliseconds +
            microseconds);

  // Fast path internal direct constructor to avoids the optional arguments and
  // [_microseconds] recomputation.
  const Duration._microseconds(this._duration);

  /**
   * Adds this Duration and [other] and
   * returns the sum as a new Duration object.
   */
  Duration operator +(Duration other) {
    return new Duration._microseconds(_duration + other._duration);
  }

  /**
   * Subtracts [other] from this Duration and
   * returns the difference as a new Duration object.
   */
  Duration operator -(Duration other) {
    return new Duration._microseconds(_duration - other._duration);
  }

  /**
   * Multiplies this Duration by the given [factor] and returns the result
   * as a new Duration object.
   *
   * Note that when [factor] is a double, and the duration is greater than
   * 53 bits, precision is lost because of double-precision arithmetic.
   */
  Duration operator *(num factor) {
    return new Duration._microseconds((_duration * factor).round());
  }

  /**
   * Divides this Duration by the given [quotient] and returns the truncated
   * result as a new Duration object.
   *
   * Throws an [IntegerDivisionByZeroException] if [quotient] is `0`.
   */
  Duration operator ~/(int quotient) {
    // By doing the check here instead of relying on "~/" below we get the
    // exception even with dart2js.
    if (quotient == 0) throw new IntegerDivisionByZeroException();
    return new Duration._microseconds(_duration ~/ quotient);
  }

  /**
   * Returns `true` if the value of this Duration
   * is less than the value of [other].
   */
  bool operator <(Duration other) => this._duration < other._duration;

  /**
   * Returns `true` if the value of this Duration
   * is greater than the value of [other].
   */
  bool operator >(Duration other) => this._duration > other._duration;

  /**
   * Returns `true` if the value of this Duration
   * is less than or equal to the value of [other].
   */
  bool operator <=(Duration other) => this._duration <= other._duration;

  /**
   * Returns `true` if the value of this Duration
   * is greater than or equal to the value of [other].
   */
  bool operator >=(Duration other) => this._duration >= other._duration;

  /**
   * Returns the number of whole days spanned by this Duration.
   */
  int get inDays => _duration ~/ Duration.MICROSECONDS_PER_DAY;

  /**
   * Returns the number of whole hours spanned by this Duration.
   *
   * The returned value can be greater than 23.
   */
  int get inHours => _duration ~/ Duration.MICROSECONDS_PER_HOUR;

  /**
   * Returns the number of whole minutes spanned by this Duration.
   *
   * The returned value can be greater than 59.
   */
  int get inMinutes => _duration ~/ Duration.MICROSECONDS_PER_MINUTE;

  /**
   * Returns the number of whole seconds spanned by this Duration.
   *
   * The returned value can be greater than 59.
   */
  int get inSeconds => _duration ~/ Duration.MICROSECONDS_PER_SECOND;

  /**
   * Returns number of whole milliseconds spanned by this Duration.
   *
   * The returned value can be greater than 999.
   */
  int get inMilliseconds => _duration ~/ Duration.MICROSECONDS_PER_MILLISECOND;

  /**
   * Returns number of whole microseconds spanned by this Duration.
   */
  int get inMicroseconds => _duration;

  /**
   * Returns `true` if this Duration is the same object as [other].
   */
  bool operator ==(other) {
    if (other is! Duration) return false;
    return _duration == other._duration;
  }

  int get hashCode => _duration.hashCode;

  /**
   * Compares this Duration to [other], returning zero if the values are equal.
   *
   * Returns a negative integer if this `Duration` is shorter than
   * [other], or a positive integer if it is longer.
   *
   * A negative `Duration` is always considered shorter than a positive one.
   *
   * It is always the case that `duration1.compareTo(duration2) < 0` iff
   * `(someDate + duration1).compareTo(someDate + duration2) < 0`.
   */
  int compareTo(Duration other) => _duration.compareTo(other._duration);

  /**
   * Returns a string representation of this `Duration`.
   *
   * Returns a string with hours, minutes, seconds, and microseconds, in the
   * following format: `HH:MM:SS.mmmmmm`. For example,
   *
   *     var d = new Duration(days:1, hours:1, minutes:33, microseconds: 500);
   *     d.toString();  // "25:33:00.000500"
   */
  String toString() {
    String sixDigits(int n) {
      if (n >= 100000) return "$n";
      if (n >= 10000) return "0$n";
      if (n >= 1000) return "00$n";
      if (n >= 100) return "000$n";
      if (n >= 10) return "0000$n";
      return "00000$n";
    }

    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    if (inMicroseconds < 0) {
      return "-${-this}";
    }
    String twoDigitMinutes = twoDigits(inMinutes.remainder(MINUTES_PER_HOUR));
    String twoDigitSeconds = twoDigits(inSeconds.remainder(SECONDS_PER_MINUTE));
    String sixDigitUs =
        sixDigits(inMicroseconds.remainder(MICROSECONDS_PER_SECOND));
    return "$inHours:$twoDigitMinutes:$twoDigitSeconds.$sixDigitUs";
  }

  /**
   * Returns whether this `Duration` is negative.
   *
   * A negative `Duration` represents the difference from a later time to an
   * earlier time.
   */
  bool get isNegative => _duration < 0;

  /**
   * Returns a new `Duration` representing the absolute value of this
   * `Duration`.
   *
   * The returned `Duration` has the same length as this one, but is always
   * positive.
   */
  Duration abs() => new Duration._microseconds(_duration.abs());

  /**
   * Returns a new `Duration` representing this `Duration` negated.
   *
   * The returned `Duration` has the same length as this one, but will have the
   * opposite sign of this one.
   */
  // Using subtraction helps dart2js avoid negative zeros.
  Duration operator -() => new Duration._microseconds(0 - _duration);
}
