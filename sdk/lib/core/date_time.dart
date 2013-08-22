// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An instant in time, such as July 20, 1969, 8:18pm PST.
 *
 * Create a DateTime object by using one of the constructors
 * or by parsing a correctly formatted string,
 * which complies with a subset of ISO 8601.
 * Note that hours are specified between 0 and 23,
 * as in a 24-hour clock.
 * For example:
 *
 *     DateTime now = new DateTime.now();
 *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
 *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");  // 8:18pm
 *
 * A DateTime object is anchored either in the UTC time zone
 * or in the local time zone of the current computer
 * when the object is created.
 *
 * Once created, neither the value nor the time zone
 * of a DateTime object may be changed.
 *
 * You can use properties to get
 * the individual units of a DateTime object.
 *
 *     assert(berlinWallFell.month == 11);
 *     assert(moonLanding.hour == 20);
 *
 * For convenience and readability,
 * the DateTime class provides a constant for each day and month
 * name&mdash;for example, [AUGUST] and [FRIDAY].
 * You can use these constants to improve code readibility:
 *
 *     DateTime berlinWallFell = new DateTime(1989, DateTime.NOVEMBER, 9);
 *     assert(berlinWallFell.month == DateTime.SATURDAY);
 *
 * Day and month values begin at 1, and the week starts on Monday.
 * That is, the constants [JANUARY] and [MONDAY] are both 1.
 *
 * ## Working with UTC and local time
 *
 * A DateTime object is in the local time zone
 * unless explicitly created in the UTC time zone.
 *
 *     DateTime dDay = new DateTime.utc(1944, 6, 6);
 *    
 * Use [isUtc] to determine whether a DateTime object is based in UTC.
 * Use the methods [toLocal] and [toUtc]
 * to get the equivalent date/time value specified in the other time zone.
 * Use [timeZoneName] to get an abbreviated name of the time zone
 * for the DateTime object.
 * To find the difference
 * between UTC and the time zone of a DateTime object
 * call [timeZoneOffset].
 *
 * ## Comparing DateTime objects
 *
 * The DateTime class contains several handy methods,
 * such as [isAfter], [isBefore], and [isAtSameMomentAs],
 * for comparing DateTime objects.
 *
 *     assert(berlinWallFell.isAfter(moonLanding) == true);
 *     assert(berlinWallFell.isBefore(moonLanding) == false);
 *
 * ## Using DateTime with Duration
 *
 * Use the [add] and [subtract] methods with a [Duration] object
 * to create a new DateTime object based on another.
 * For example, to find the date that is sixty days after today, write:
 *
 *     DateTime today = new DateTime.now();
 *     DateTime sixtyDaysFromNow = today.add(new Duration(days: 60));
 *
 * To find out how much time is between two DateTime objects use
 * [difference], which returns a [Duration] object:
 *
 *     Duration difference = berlinWallFell.difference(dDay);
 *     assert(difference.inDays == 16592);
 *
 * ## Other resources
 *
 * See [Duration] to represent a span of time.
 * See [Stopwatch] to measure timespans.
 *
 * The DateTime class does not provide internationalization.
 * To internationalize your code, use
 * the [intl](http://pub.dartlang.org/packages/intl) package.
 *
 */
class DateTime implements Comparable {
  // Weekday constants that are returned by [weekday] method:
  static const int MONDAY = 1;
  static const int TUESDAY = 2;
  static const int WEDNESDAY = 3;
  static const int THURSDAY = 4;
  static const int FRIDAY = 5;
  static const int SATURDAY = 6;
  static const int SUNDAY = 7;
  static const int DAYS_PER_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static const int JANUARY = 1;
  static const int FEBRUARY = 2;
  static const int MARCH = 3;
  static const int APRIL = 4;
  static const int MAY = 5;
  static const int JUNE = 6;
  static const int JULY = 7;
  static const int AUGUST = 8;
  static const int SEPTEMBER = 9;
  static const int OCTOBER = 10;
  static const int NOVEMBER = 11;
  static const int DECEMBER = 12;
  static const int MONTHS_PER_YEAR = 12;

  /**
   * The number of milliseconds since
   * the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
   *
   * This value is independent of the time zone.
   *
   * This value is at most
   * 8,640,000,000,000,000ms (100,000,000 days) from the Unix epoch.
   * In other words: [:millisecondsSinceEpoch.abs() <= 8640000000000000:].
   *
   */
  final int millisecondsSinceEpoch;

  /**
   * True if this [DateTime] is set to UTC time.
   *
   *     DateTime dDay = new DateTime.utc(1944, 6, 6);
   *     assert(dDay.isUtc);
   *
   */
  final bool isUtc;

  /**
   * Constructs a [DateTime] instance specified in the local time zone.
   *
   * For example,
   * to create a new DateTime object representing April 29, 2014, 6:04am:
   *
   *     DateTime annularEclipse = new DateTime(2014, DateTime.APRIL, 29, 6, 4);
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
   * Constructs a [DateTime] instance specified in the UTC time zone.
   *
   *     DateTime dDay = new DateTime.utc(1944, DateTime.JUNE, 6);
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
   * Constructs a [DateTime] instance with current date and time in the
   * local time zone.
   *
   *     DateTime thisInstant = new DateTime.now();
   *
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
      int millisecond = (parseDoubleOrZero(match[7]) * 1000).round();
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
   * Constructs a new [DateTime] instance
   * with the given [millisecondsSinceEpoch].
   *
   * If [isUtc] is false then the date is in the local time zone.
   *
   * The constructed [DateTime] represents
   * 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
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
   * same time zone (UTC or local).
   *
   *     DateTime dDayUtc   = new DateTime.utc(1944, DateTime.JUNE, 6);
   *     DateTime dDayLocal = new DateTime(1944, DateTime.JUNE, 6);
   *
   *     assert(dDayUtc.isAtSameMomentAs(dDayLocal) == false);
   *
   * See [isAtSameMomentAs] for a comparison that adjusts for time zone.
   */
  bool operator ==(other) {
    if (!(other is DateTime)) return false;
    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
            isUtc == other.isUtc);
  }

  /**
   * Returns true if [this] occurs before [other].
   *
   * The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
   *     DateTime moonLanding    = DateTime.parse("1969-07-20 20:18:00");
   *
   *     assert(berlinWallFell.isBefore(moonLanding) == false);
   *
   */
  bool isBefore(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  /**
   * Returns true if [this] occurs after [other].
   *
   * The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
   *     DateTime moonLanding    = DateTime.parse("1969-07-20 20:18:00");
   *
   *     assert(berlinWallFell.isAfter(moonLanding) == true);
   *
   */
  bool isAfter(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  /**
   * Returns true if [this] occurs at the same moment as [other].
   *
   * The comparison is independent of whether the time is in UTC or in the local
   * time zone.
   *
   *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
   *     DateTime moonLanding    = DateTime.parse("1969-07-20 20:18:00");
   *
   *     assert(berlinWallFell.isAtSameMomentAs(moonLanding) == false);
   */
  bool isAtSameMomentAs(DateTime other) {
    return millisecondsSinceEpoch == other.millisecondsSinceEpoch;
  }

  /**
   * Compares this DateTime object to [other],
   * returning zero if the values are equal.
   *
   * This function returns a negative integer
   * if this DateTime is smaller (earlier) than [other],
   * or a positive integer if it is greater (later).
   */
  int compareTo(DateTime other)
      => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  int get hashCode => millisecondsSinceEpoch;

  /**
   * Returns this DateTime value in the local time zone.
   *
   * Returns [this] if it is already in the local time zone.
   * Otherwise this method is equivalent to:
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
   * Returns this DateTime value in the UTC time zone.
   *
   * Returns [this] if it is already in UTC.
   * Otherwise this method is equivalent to:
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
   * Returns a human-readable string for this instance.
   *
   * The returned string is constructed for the time zone of this instance.
   * The `toString()` method provides a simply formatted string.
   * It does not support internationalized strings.
   * Use the [intl](http://pub.dartlang.org/packages/intl) package
   * at the pub shared packages repo.
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

  /**
   * Returns a new [DateTime] instance with [duration] added to [this].
   *
   *     DateTime today = new DateTime.now();
   *     DateTime sixtyDaysFromNow = today.add(new Duration(days: 60));
   */

  DateTime add(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(
        ms + duration.inMilliseconds, isUtc: isUtc);
  }

  /**
   * Returns a new [DateTime] instance with [duration] subtracted from [this].
   *
   *     DateTime today = new DateTime.now();
   *     DateTime sixtyDaysAgo = today.subtract(new Duration(days: 60));
   */
  DateTime subtract(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(
        ms - duration.inMilliseconds, isUtc: isUtc);
  }

  /**
   * Returns a [Duration] with the difference between [this] and [other].
   *
   *     DateTime berlinWallFell = new DateTime(1989, DateTime.NOVEMBER, 9);
   *     DateTime dDay = new DateTime(1944, DateTime.JUNE, 6);
   *
   *     Duration difference = berlinWallFell.difference(dDay);
   *     assert(difference.inDays == 16592);
   */

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
   * The abbreviated time zone name&mdash;for example,
   * [:"CET":] or [:"CEST":].
   */
  external String get timeZoneName;

  /**
   * The time zone offset, which
   * is the difference between local time and UTC.
   *
   * The offset is positive for time zones west of UTC.
   *
   * Note, that JavaScript, Python and C return the difference between UTC and
   * local time. Java, C# and Ruby return the difference between local time and
   * UTC.
   */
  external Duration get timeZoneOffset;

  /**
   * The year.
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.year == 1969);
   */
  external int get year;

  /**
   * The month [1..12].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.month == 7);
   *     assert(moonLanding.month == DateTime.JULY);
   */
  external int get month;

  /**
   * The day of the month [1..31].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.day == 20);
   */
  external int get day;

  /**
   * The hour of the day, expressed as in a 24-hour clock [0..23].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.hour == 20);
   */
  external int get hour;

  /**
   * The minute [0...59].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.minute == 18);
   */
  external int get minute;

  /**
   * The second [0...59].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.second == 0);
   */
  external int get second;

  /**
   * The millisecond [0...999].
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.millisecond == 0);
   */
  external int get millisecond;

  /**
   * The day of the week [MONDAY]..[SUNDAY].
   *
   * In accordance with ISO 8601
   * a week starts with Monday, which has the value 1.
   *
   *     DateTime moonLanding = DateTime.parse("1969-07-20 20:18:00");
   *     assert(moonLanding.weekday == 7);
   *     assert(moonLanding.weekday == DateTime.SUNDAY);
   *
   */
  external int get weekday;
}
