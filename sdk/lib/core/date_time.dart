// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Deprecated class. Please use [DateTime] instead.
 */
@deprecated
abstract class Date implements Comparable<Date> {
  // Weekday constants that are returned by [weekday] method:
  static const int MON = 1;
  static const int TUE = 2;
  static const int WED = 3;
  static const int THU = 4;
  static const int FRI = 5;
  static const int SAT = 6;
  static const int SUN = 7;
  static const int DAYS_IN_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static const int JAN = 1;
  static const int FEB = 2;
  static const int MAR = 3;
  static const int APR = 4;
  static const int MAY = 5;
  static const int JUN = 6;
  static const int JUL = 7;
  static const int AUG = 8;
  static const int SEP = 9;
  static const int OCT = 10;
  static const int NOV = 11;
  static const int DEC = 12;

  factory Date(int year,
               [int month = 1,
                int day = 1,
                int hour = 0,
                int minute = 0,
                int second = 0,
                int millisecond = 0]) {
    return new DateTime(year, month, day, hour, minute, second, millisecond);
  }

  factory Date.utc(int year,
                   [int month = 1,
                    int day = 1,
                    int hour = 0,
                    int minute = 0,
                    int second = 0,
                    int millisecond = 0]) {
    return
        new DateTime.utc(year, month, day, hour, minute, second, millisecond);
  }

  factory Date.now() => new DateTime.now();

  factory Date.fromString(String formattedString)
      => DateTime.parse(formattedString);

  factory Date.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
                                          {bool isUtc: false}) {
    return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                   isUtc: isUtc);
  }

  bool operator ==(DateTime other);
  bool operator <(DateTime other);
  bool operator <=(DateTime other);
  bool operator >(DateTime other);
  bool operator >=(DateTime other);


  DateTime toLocal();
  DateTime toUtc();

  String get timeZoneName;
  Duration get timeZoneOffset;

  int get year;
  int get month;
  int get day;
  int get hour;
  int get minute;
  int get second;
  int get millisecond;

  int get weekday;

  int get millisecondsSinceEpoch;

  bool get isUtc;

  String toString();

  DateTime add(Duration duration);
  DateTime subtract(Duration duration);
  Duration difference(DateTime other);
}

/**
 * A DateTime object represents a point in time.
 *
 * It can represent time values that are at a distance of at most
 * 8,640,000,000,000,000ms (100,000,000 days) from epoch (1970-01-01 UTC). In
 * other words: [:millisecondsSinceEpoch.abs() <= 8640000000000000:].
 *
 * Also see [Stopwatch] for means to measure time-spans.
 */
class DateTime implements Date {
  // Weekday constants that are returned by [weekday] method:
  static const int MON = 1;
  static const int TUE = 2;
  static const int WED = 3;
  static const int THU = 4;
  static const int FRI = 5;
  static const int SAT = 6;
  static const int SUN = 7;
  static const int DAYS_IN_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static const int JAN = 1;
  static const int FEB = 2;
  static const int MAR = 3;
  static const int APR = 4;
  static const int MAY = 5;
  static const int JUN = 6;
  static const int JUL = 7;
  static const int AUG = 8;
  static const int SEP = 9;
  static const int OCT = 10;
  static const int NOV = 11;
  static const int DEC = 12;

  /**
   * The milliseconds since 1970-01-01T00:00:00Z (UTC). This value is
   * independent of the time zone.
   *
   * See [Stopwatch] for means to measure time-spans.
   */
  final int millisecondsSinceEpoch;

  /**
   * True if this [DateTime] is set to UTC time.
   */
  final bool isUtc;

  /**
   * Constructs a [DateTime] instance based on the individual parts. The date is
   * in the local time zone.
   *
   * [month] and [day] are one-based. For example
   * [:new DateTime(1938, 1, 10):] represents the 10th of January 1938.
   */
  // TODO(8042): This should be a redirecting constructor and not a factory.
  factory DateTime(int year,
           [int month = 1,
            int day = 1,
            int hour = 0,
            int minute = 0,
            int second = 0,
            int millisecond = 0]) {
    return new DateTime._internal(
          year, month, day, hour, minute, second, millisecond, false);
  }

  /**
   * Constructs a [DateTime] instance based on the individual parts. The date is
   * in the UTC time zone.
   *
   * [month] and [day] are one-based. For example
   * [:new DateTime.utc(1938, 1, 10):] represents the 10th of January 1938 in
   * Coordinated Universal Time.
   */
  // TODO(8042): This should be a redirecting constructor and not a factory.
  factory DateTime.utc(int year,
                       [int month = 1,
                        int day = 1,
                        int hour = 0,
                        int minute = 0,
                        int second = 0,
                        int millisecond = 0]) {
    return new DateTime._internal(
          year, month, day, hour, minute, second, millisecond, true);
  }

  /**
   * Constructs a new [DateTime] instance with current date time value in the
   * local time zone.
   */
  // TODO(8042): This should be a redirecting constructor and not a factory.
  factory DateTime.now() { return new DateTime._now(); }

  /**
   * Constructs a new [DateTime] instance based on [formattedString].
   *
   * The function parses a subset of ISO 8601. Examples of accepted strings:
   *
   * * `"2012-02-27 13:27:00"`
   * * `"2012-02-27 13:27:00.123456z"`
   * * `"20120227 13:27:00"`
   * * `"20120227T132700"`
   * * `"20120227"`
   * * `"+20120227"`
   * * `"2012-02-27T14Z"`
   * * `"-123450101 00:00:00 Z"`: in the year -12345.
   */
  // TODO(floitsch): specify grammar.
  static DateTime parse(String formattedString) {
    final RegExp re = new RegExp(
        r'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)'  // The day part.
        r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match != null) {
      int parseIntOrZero(String matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }

      double parseDoubleOrZero(String matched) {
        if (matched == null) return 0.0;
        return double.parse(matched);
      }

      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int millisecond = (parseDoubleOrZero(match[7]) * 1000).round().toInt();
      if (millisecond == 1000) {
        addOneMillisecond = true;
        millisecond = 999;
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] != null) && (match[8] != "");
      int millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(
          years, month, day, hour, minute, second, millisecond, isUtc);
      if (millisecondsSinceEpoch == null) {
        throw new ArgumentError(formattedString);
      }
      if (addOneMillisecond) millisecondsSinceEpoch++;
      return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                     isUtc: isUtc);
    } else {
      throw new ArgumentError(formattedString);
    }
  }

  static const int _MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;

  /**
   * Constructs a new [DateTime] instance with the given [millisecondsSinceEpoch].
   * If [isUtc] is false then the date is in the local time zone.
   *
   * The constructed [DateTime] represents
   * 1970-01-01T00:00:00Z + [millisecondsSinceEpoch]ms in the given
   * time zone (local or UTC).
   */
  // TODO(lrn): Have two constructors instead of taking an optional bool.
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
                                      {bool isUtc: false})
      : this.millisecondsSinceEpoch = millisecondsSinceEpoch,
        this.isUtc = isUtc {
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new ArgumentError(millisecondsSinceEpoch);
    }
    if (isUtc == null) throw new ArgumentError(isUtc);
  }

  /**
   * Returns true if [other] is a [DateTime] at the same moment and in the
   * same timezone (UTC or local).
   *
   * See [isAtSameMomentAs] for a comparison that ignores the timezone.
   */
  bool operator ==(other) {
    if (!(other is DateTime)) return false;
    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
            isUtc == other.isUtc);
  }

  /**
   * Returns true if [this] occurs before [other]. The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   * *Deprecated* Use [isBefore] instead.
   */
  @deprecated
  bool operator <(DateTime other)
      => millisecondsSinceEpoch < other.millisecondsSinceEpoch;

  /**
   * Returns true if [this] occurs at the same time or before [other]. The
   * comparison is independent of whether the time is in UTC or in the local
   * time zone.
   *
   * *Deprecated* Use [isAfter] instead ([:!isAfter:]).
   */
  @deprecated
  bool operator <=(DateTime other)
      => millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  /**
   * Returns true if [this] occurs after [other]. The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   * *Deprecated* Use [isAfter] instead.
   */
  @deprecated
  bool operator >(DateTime other)
      => millisecondsSinceEpoch > other.millisecondsSinceEpoch;

  /**
   * Returns true if [this] occurs at the same time or after [other]. The
   * comparison is independent of whether the time is in UTC or in the local
   * time zone.
   *
   * *Deprecated* Use [isBefore] instead ([:!isBefore:]).
   */
  @deprecated
  bool operator >=(DateTime other)
      => millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  /**
   * Returns true if [this] occurs before [other]. The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   */
  bool isBefore(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  /**
   * Returns true if [this] occurs after [other]. The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   */
  bool isAfter(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  /**
   * Returns true if [this] occurs at the same moment as [other]. The
   * comparison is independent of whether the time is in UTC or in the local
   * time zone.
   */
  bool isAtSameMomentAs(DateTime other) {
    return millisecondsSinceEpoch == other.millisecondsSinceEpoch;
  }

  int compareTo(DateTime other)
      => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  int get hashCode => millisecondsSinceEpoch;

  /**
   * Returns [this] in the local time zone. Returns itself if it is already in
   * the local time zone. Otherwise, this method is equivalent to
   *
   *     new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
   *                                             isUtc: false)
   */
  DateTime toLocal() {
    if (isUtc) {
      return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                     isUtc: false);
    }
    return this;
  }

  /**
   * Returns [this] in UTC. Returns itself if it is already in UTC. Otherwise,
   * this method is equivalent to
   *
   *     new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
   *                                             isUtc: true)
   */
  DateTime toUtc() {
    if (isUtc) return this;
    return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                   isUtc: true);
  }

  /**
   * Returns a human readable string for this instance.
   * The returned string is constructed for the time zone of this instance.
   */
  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      return "${sign}000$absN";
    }

    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n >= 10) return "0${n}";
      return "00${n}";
    }

    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String y = fourDigits(year);
    String m = twoDigits(month);
    String d = twoDigits(day);
    String h = twoDigits(hour);
    String min = twoDigits(minute);
    String sec = twoDigits(second);
    String ms = threeDigits(millisecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  /** Returns a new [DateTime] with the [duration] added to [this]. */
  DateTime add(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(
        ms + duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a new [DateTime] with the [duration] subtracted from [this]. */
  DateTime subtract(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(
        ms - duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a [Duration] with the difference of [this] and [other]. */
  Duration difference(DateTime other) {
    int ms = millisecondsSinceEpoch;
    int otherMs = other.millisecondsSinceEpoch;
    return new Duration(milliseconds: ms - otherMs);
  }

  external DateTime._internal(int year,
                              int month,
                              int day,
                              int hour,
                              int minute,
                              int second,
                              int millisecond,
                              bool isUtc);
  external DateTime._now();
  external static int _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day, int hour, int minute, int second,
      int millisecond, bool isUtc);

  /**
   * Returns the abbreviated time-zone name.
   *
   * Examples: [:"CET":] or [:"CEST":].
   */
  external String get timeZoneName;

  /**
   * The time-zone offset is the difference between local time and UTC. That is,
   * the offset is positive for time zones west of UTC.
   *
   * Note, that JavaScript, Python and C return the difference between UTC and
   * local time. Java, C# and Ruby return the difference between local time and
   * UTC.
   */
  external Duration get timeZoneOffset;

  /**
   * Returns the year.
   */
  external int get year;

  /**
   * Returns the month into the year [1..12].
   */
  external int get month;

  /**
   * Returns the day into the month [1..31].
   */
  external int get day;

  /**
   * Returns the hour into the day [0..23].
   */
  external int get hour;

  /**
   * Returns the minute into the hour [0...59].
   */
  external int get minute;

  /**
   * Returns the second into the minute [0...59].
   */
  external int get second;

  /**
   * Returns the millisecond into the second [0...999].
   */
  external int get millisecond;

  /**
   * Returns the week day [MON..SUN]. In accordance with ISO 8601
   * a week starts with Monday which has the value 1.
   */
  external int get weekday;
}
