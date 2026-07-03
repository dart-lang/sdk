// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

/// A difference between points in time.
///
/// A `Duration` is a signed number of microseconds, which represents
/// an offset from a point in time to another.
/// You can add a `Duration` to a [DateTime], which gives the
/// point in time that is offset by that duration from the original.
///
/// Most durations are _positive_ and represent an offset
/// to a later time. A positive duration is useful for representing
/// a delay, a point in the future relative to now (as used by
/// [Future.delayed]),
/// or as a measure of time that has passed from an earlier
/// time until now (as reported by [Stopwatch.elapsed]).
///
/// A negative duration is the difference from a later time to an
/// earlier, and adding it to a time gives an earlier time.
/// You cannot wait for a negative amount of time using
/// [Future.delayed].
///
/// Durations are independent of calendars. For example, a duration of 2 days
/// is always 48 hours, even when it is added to a `DateTime` just when the
/// time zone is about to make a daylight-savings switch. (See [DateTime.add]).
///
/// A duration is a (positive or negative) number of microseconds.
/// Durations are ordered by this number of microseconds when compared
/// using [operator <] or [compareTo].
///
/// Despite the same name, a `Duration` object does not implement "Durations"
/// as specified by ISO 8601. In particular, a duration object does not keep
/// track of the individually provided members (such as "days" or "hours"), but
/// only uses these arguments to compute the length of the corresponding time
/// interval.
///
/// To create a new `Duration` object, use this class's single constructor
/// giving the appropriate arguments:
/// ```dart
/// const fastestMarathon = Duration(hours: 2, minutes: 3, seconds: 2);
/// ```
/// The created [Duration] is defined by the number of microseconds
/// that is the sum of all the individual arguments to the constructor.
///
/// Properties can access that single number in different ways.
/// The [inMicroseconds] is the entire value, and, for example,
/// [inMinutes] gives the number of whole minutes in the total duration,
/// which includes any minutes that were provided as "hours" to the constructor
/// or provided as "seconds" with a value of 60 or above.
///
/// ```dart
/// const fastestMarathon = Duration(hours: 2, minutes: 0, seconds: 35);
/// print(fastestMarathon.inDays); // 0
/// print(fastestMarathon.inHours); // 2
/// print(fastestMarathon.inMinutes); // 120
/// print(fastestMarathon.inSeconds); // 7235
/// print(fastestMarathon.inMilliseconds); // 7235000
/// ```
/// If a duration is negative, all the properties derived from the duration are
/// non-positive (negative unless they are zero).
/// ```dart
/// const overDayAgo = Duration(days: -1, hours: -10);
/// print(overDayAgo.inDays); // -1
/// print(overDayAgo.inHours); // -34
/// print(overDayAgo.inMinutes); // -2040
/// ```
///
/// Use one of the properties, such as [inDays],
/// to retrieve the integer value of the `Duration` in the specified time unit.
/// Note that the returned value is rounded towards zero.
/// For example,
/// ```dart
/// const aLongWeekend = Duration(hours: 88);
/// print(aLongWeekend.inDays); // 3
/// const aLongWeekendAgo = Duration(hours: -88);
/// print(aLongWeekendAgo.inDays); // -3
/// ```
///
/// A duration also provides arithmetic and comparison operators,
/// all based on the microsecond offset of the duration.
/// and the class provides a set of constants useful for converting
/// between time units.
/// ```dart
/// const firstHalf = Duration(minutes: 45); // 00:45:00.000000
/// const secondHalf = Duration(minutes: 45); // 00:45:00.000000
/// const overTime = Duration(minutes: 30); // 00:30:00.000000
/// final maxGameTime = firstHalf + secondHalf + overTime;
/// print(maxGameTime.inMinutes); // 120
///
/// // The duration of the firstHalf and secondHalf is the same, returns 0.
/// var result = firstHalf.compareTo(secondHalf);
/// print(result); // 0
///
/// // Duration of overTime is shorter than firstHalf, returns < 0.
/// result = overTime.compareTo(firstHalf);
/// print(result); // < 0
///
/// // Duration of secondHalf is longer than overTime, returns > 0.
/// result = secondHalf.compareTo(overTime);
/// print(result); // > 0
/// ```
///
/// **See also:**
/// * [DateTime] to represent a point in time.
/// * [Stopwatch] to measure time-spans.
class Duration implements Comparable<Duration> {
  /// The number of microseconds per millisecond.
  static const int microsecondsPerMillisecond = 1000;

  /// The number of milliseconds per second.
  static const int millisecondsPerSecond = 1000;

  /// The number of seconds per minute.
  ///
  /// Notice that some minutes of official clock time might
  /// differ in length because of leap seconds.
  /// The [Duration] and [DateTime] classes ignore leap seconds
  /// and consider all minutes to have 60 seconds.
  static const int secondsPerMinute = 60;

  /// The number of minutes per hour.
  static const int minutesPerHour = 60;

  /// The number of hours per day.
  ///
  /// Notice that some calendar days may differ in length because
  /// of time zone changes due to daylight saving.
  /// The [Duration] class is calendar and time zone agnostic and
  /// considers all days to have 24 hours.
  static const int hoursPerDay = 24;

  /// The number of microseconds per second.
  static const int microsecondsPerSecond =
      microsecondsPerMillisecond * millisecondsPerSecond;

  /// The number of microseconds per minute.
  static const int microsecondsPerMinute =
      microsecondsPerSecond * secondsPerMinute;

  /// The number of microseconds per hour.
  static const int microsecondsPerHour = microsecondsPerMinute * minutesPerHour;

  /// The number of microseconds per day.
  static const int microsecondsPerDay = microsecondsPerHour * hoursPerDay;

  /// The number of milliseconds per minute.
  static const int millisecondsPerMinute =
      millisecondsPerSecond * secondsPerMinute;

  /// The number of milliseconds per hour.
  static const int millisecondsPerHour = millisecondsPerMinute * minutesPerHour;

  /// The number of milliseconds per day.
  static const int millisecondsPerDay = millisecondsPerHour * hoursPerDay;

  /// The number of seconds per hour.
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;

  /// The number of seconds per day.
  static const int secondsPerDay = secondsPerHour * hoursPerDay;

  /// The number of minutes per day.
  static const int minutesPerDay = minutesPerHour * hoursPerDay;

  /// An empty duration, representing zero time.
  static const Duration zero = Duration(seconds: 0);

  /// The time offset of this duration in microseconds.
  ///
  /// The value can be greater than 999999.
  /// For example, a duration of nine seconds, 123 milliseconds and
  /// 678 microseconds has 9123678 microseconds.
  /// ```dart
  /// const duration = Duration(seconds: 9, milliseconds: 123,
  ///     microseconds: 567);
  /// print(duration.inMicroseconds); // 9123678
  /// ```
  final int inMicroseconds;

  /// Creates a new [Duration] object whose value
  /// is the sum of all individual parts.
  ///
  /// Individual parts can be larger than the number of those
  /// parts in the next larger unit.
  /// For example, [hours] can be greater than 23.
  /// If this happens, the value overflows into the next larger
  /// unit, so 26 [hours] is the same as 2 [hours] and
  /// one more [days].
  /// Likewise, values can be negative, in which case they
  /// underflow and subtract from the next larger unit.
  ///
  /// If the total number of microseconds cannot be represented
  /// as an integer value, the number of microseconds might overflow
  /// and be truncated to a smaller number of bits,
  /// or it might lose precision.
  ///
  /// All arguments are 0 by default.
  /// ```dart
  /// const duration = Duration(days: 1, hours: 8, minutes: 56, seconds: 59,
  ///   milliseconds: 30, microseconds: 10);
  /// print(duration); // 32:56:59.030010
  /// ```
  const Duration({
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int milliseconds = 0,
    int microseconds = 0,
  }) : this._microseconds(
         microseconds +
             microsecondsPerMillisecond * milliseconds +
             microsecondsPerSecond * seconds +
             microsecondsPerMinute * minutes +
             microsecondsPerHour * hours +
             microsecondsPerDay * days,
       );

  // Fast path internal direct constructor to avoids the optional arguments
  // and [_microseconds] recomputation.
  // The `+ 0` prevents -0.0 on the web, if the incoming duration happens to be -0.0.
  const Duration._microseconds(int duration) : inMicroseconds = duration + 0;

  /// Adds this `Duration` and [other] and
  /// returns the sum as a new `Duration` object.
  Duration operator +(Duration other) {
    return Duration._microseconds(inMicroseconds + other.inMicroseconds);
  }

  /// The offset of this duration minus the offset of [other].
  Duration operator -(Duration other) {
    return Duration._microseconds(inMicroseconds - other.inMicroseconds);
  }

  /// This [Duration] scaled by [factor].
  ///
  /// Note that when [factor] is a double, and the duration is greater than
  /// 53 bits, precision is lost because of double-precision arithmetic.
  Duration operator *(num factor) {
    return Duration._microseconds((inMicroseconds * factor).round());
  }

  /// One-[quotient]th of this duration.
  ///
  /// Divides the offset in microseconds of this duration by [quotient]
  /// rounding towards zero, and provides a new `Duration` with that
  /// as its [inMicroseconds].
  ///
  /// The [quotient] must not be `0`. If it is negative, the result
  /// is equivalent to dividing by the absolute value and then negating.
  Duration operator ~/(int quotient) {
    // By doing the check here instead of relying on "~/" below we get the
    // exception even with dart2js.
    if (quotient == 0) throw IntegerDivisionByZeroException();
    return Duration._microseconds(inMicroseconds ~/ quotient);
  }

  /// Whether this duration's offset is smaller than that of [other].
  ///
  /// A negative duration's offset is always smaller than a positive one's.
  /// Equivalent to comparing [inMicroseconds]
  bool operator <(Duration other) => this.inMicroseconds < other.inMicroseconds;

  /// Whether this duration's offset is greater than that of [other].
  ///
  /// A negative duration's offset is always smaller than a positive one's.
  /// Equivalent to comparing [inMicroseconds]
  bool operator >(Duration other) => this.inMicroseconds > other.inMicroseconds;

  /// Whether this duration's offset is not greater than that of [other].
  ///
  /// A negative duration's offset is always smaller than a positive one's.
  /// Equivalent to comparing [inMicroseconds]
  bool operator <=(Duration other) =>
      this.inMicroseconds <= other.inMicroseconds;

  /// Whether this duration's offset is not smaller than that of [other].
  ///
  /// A negative duration's offset is always smaller than a positive one's.
  /// Equivalent to comparing [inMicroseconds]
  bool operator >=(Duration other) =>
      this.inMicroseconds >= other.inMicroseconds;

  /// The number of entire days spanned by this [Duration].
  ///
  /// For example, a duration of four days and three hours
  /// has four entire days.
  /// ```dart
  /// const duration = Duration(days: 4, hours: 3);
  /// print(duration.inDays); // 4
  /// ```
  /// A negative duration has a negative number of whole days,
  /// so that `(-duration).inDays` = `-(duration.inDays)`.
  int get inDays => inMicroseconds ~/ Duration.microsecondsPerDay;

  /// The number of entire hours spanned by this [Duration].
  ///
  /// The returned value can be greater than 23.
  /// For example, a duration of four days and three hours
  /// has 99 entire hours.
  /// ```dart
  /// const duration = Duration(days: 4, hours: 3);
  /// print(duration.inHours); // 99 = 4 * 24 + 3
  /// ```
  /// A negative duration has a negative number of whole hours,
  /// so that `(-duration).inHours` = `-(duration.inHours)`.
  int get inHours => inMicroseconds ~/ Duration.microsecondsPerHour;

  /// The number of whole minutes spanned by this [Duration].
  ///
  /// The returned value can be greater than 59.
  /// For example, a duration of three hours and 12 minutes
  /// has 192 minutes.
  /// ```dart
  /// const duration = Duration(hours: 3, minutes: 12);
  /// print(duration.inMinutes); // 192 = 3 * 60 + 12
  /// ```
  /// A negative duration has a negative number of whole minutes,
  /// so that `(-duration).inMinutes` = `-(duration.inMinutes)`.
  int get inMinutes => inMicroseconds ~/ Duration.microsecondsPerMinute;

  /// The number of whole seconds spanned by this [Duration].
  ///
  /// The returned value can be greater than 59.
  /// For example, a duration of three minutes and 12 seconds
  /// has 192 seconds.
  /// ```dart
  /// const duration = Duration(minutes: 3, seconds: 12);
  /// print(duration.inSeconds); // 192 = 3 * 60 + 12
  /// ```
  /// A negative duration has a negative number of whole seconds,
  /// so that `(-duration).inSeconds` = `-(duration.inSeconds)`.
  int get inSeconds => inMicroseconds ~/ Duration.microsecondsPerSecond;

  /// The number of whole milliseconds spanned by this [Duration].
  ///
  /// The returned value can be greater than 999.
  /// For example, a duration of nine seconds and 123 milliseconds
  /// has 9125 milliseconds.
  /// ```dart
  /// const duration = Duration(seconds: 9, milliseconds: 123);
  /// print(duration.inMilliseconds); // 9123 = 9 * 1000 + 123
  /// ```
  int get inMilliseconds =>
      inMicroseconds ~/ Duration.microsecondsPerMillisecond;

  /// Whether this [Duration] is equivalent to [other].
  ///
  /// Durations are equivalent if they have the same number
  /// of microseconds, as reported by [inMicroseconds].
  bool operator ==(Object other) =>
      other is Duration && inMicroseconds == other.inMicroseconds;

  /// The hash code of a duration is the hash code of its [inMicroseconds].
  int get hashCode => inMicroseconds.hashCode;

  /// Compares this [Duration] to [other].
  ///
  /// Returns a negative integer if this [Duration]'s offset is smaller
  /// than that of [other], a positive integer if this duration's offset
  /// is greater than that of [other], and 0 if they are equivalent.
  ///
  /// A longer positive duration ends after a shorter positive duration,
  /// a positive duration ends after a negative duration,
  /// and a shorter negative duration ends after a longer negative duration.
  /// Equivalent to comparing the [inMicroseconds] of the duration).
  ///
  /// It is always the case that `duration1.compareTo(duration2) < 0`
  /// if and only if
  /// `(someDate + duration1).compareTo(someDate + duration2) < 0`.
  int compareTo(Duration other) =>
      inMicroseconds.compareTo(other.inMicroseconds);

  /// A string representation of this [Duration].
  ///
  /// A string with hours, minutes, seconds, and microseconds, in the
  /// following format: `H:MM:SS.mmmmmm`. For example,
  /// ```dart
  /// var d = const Duration(days: 1, hours: 1, minutes: 33, microseconds: 500);
  /// print(d.toString()); // 25:33:00.000500
  ///
  /// d = const Duration(hours: 1, minutes: 10, microseconds: 500);
  /// print(d.toString()); // 1:10:00.000500
  /// ```
  String toString() {
    var microseconds = inMicroseconds;
    var sign = "";
    var negative = microseconds < 0;

    var hours = microseconds ~/ microsecondsPerHour;
    microseconds = microseconds.remainder(microsecondsPerHour);

    // Correcting for being negative after first division, instead of before,
    // to avoid negating min-int, -(2^31-1), of a native int64.
    if (negative) {
      hours = 0 - hours; // Not using `-hours` to avoid creating -0.0 on web.
      microseconds = 0 - microseconds;
      sign = "-";
    }

    var minutes = microseconds ~/ microsecondsPerMinute;
    microseconds = microseconds.remainder(microsecondsPerMinute);

    var minutesPadding = minutes < 10 ? "0" : "";

    var seconds = microseconds ~/ microsecondsPerSecond;
    microseconds = microseconds.remainder(microsecondsPerSecond);

    var secondsPadding = seconds < 10 ? "0" : "";

    // Padding up to six digits for microseconds.
    var microsecondsText = microseconds.toString().padLeft(6, "0");

    return "$sign$hours:"
        "$minutesPadding$minutes:"
        "$secondsPadding$seconds."
        "$microsecondsText";
  }

  /// Whether this [Duration] is negative.
  ///
  /// A negative [Duration] represents the difference from a later time to an
  /// earlier time.
  bool get isNegative => inMicroseconds < 0;

  /// A positive [Duration] with the same absolute length as this [Duration].
  ///
  /// The returned [Duration] has the same length as this one, but is always
  /// positive where possible.
  Duration abs() =>
      inMicroseconds >= 0 ? this : Duration._microseconds(0 - inMicroseconds);

  /// Creates a new [Duration] with the opposite  sign of this [Duration].
  ///
  /// The returned [Duration] has the absolute length as this one, but has the
  /// opposite sign (as reported by [isNegative]) where possible.
  // Using subtraction helps dart2js avoid negative zeros.
  Duration operator -() => Duration._microseconds(0 - inMicroseconds);
}
