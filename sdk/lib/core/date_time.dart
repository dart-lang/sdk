// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An instant in time, such as July 20, 1969, 8:18pm GMT.
 *
 * DateTimes can represent time values that are at a distance of at most
 * 100,000,000 days from epoch (1970-01-01 UTC): -271821-04-20 to 275760-09-13.
 *
 * Create a DateTime object by using one of the constructors
 * or by parsing a correctly formatted string,
 * which complies with a subset of ISO 8601.
 * Note that hours are specified between 0 and 23,
 * as in a 24-hour clock.
 * For example:
 *
 * ```
 * var now = new DateTime.now();
 * var berlinWallFell = new DateTime.utc(1989, 11, 9);
 * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");  // 8:18pm
 * ```
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
 * ```
 * assert(berlinWallFell.month == 11);
 * assert(moonLanding.hour == 20);
 * ```
 *
 * For convenience and readability,
 * the DateTime class provides a constant for each day and month
 * name - for example, [AUGUST] and [FRIDAY].
 * You can use these constants to improve code readability:
 *
 * ```
 * var berlinWallFell = new DateTime.utc(1989, DateTime.NOVEMBER, 9);
 * assert(berlinWallFell.weekday == DateTime.THURSDAY);
 * ```
 *
 * Day and month values begin at 1, and the week starts on Monday.
 * That is, the constants [JANUARY] and [MONDAY] are both 1.
 *
 * ## Working with UTC and local time
 *
 * A DateTime object is in the local time zone
 * unless explicitly created in the UTC time zone.
 *
 * ```
 * var dDay = new DateTime.utc(1944, 6, 6);
 * ```
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
 * ```
 * assert(berlinWallFell.isAfter(moonLanding) == true);
 * assert(berlinWallFell.isBefore(moonLanding) == false);
 * ```
 *
 * ## Using DateTime with Duration
 *
 * Use the [add] and [subtract] methods with a [Duration] object
 * to create a new DateTime object based on another.
 * For example, to find the date that is sixty days (24 * 60 hours) after today,
 * write:
 *
 * ```
 * var now = new DateTime.now();
 * var sixtyDaysFromNow = now.add(new Duration(days: 60));
 * ```
 *
 * To find out how much time is between two DateTime objects use
 * [difference], which returns a [Duration] object:
 *
 * ```
 * var difference = berlinWallFell.difference(moonLanding);
 * assert(difference.inDays == 7416);
 * ```
 *
 * The difference between two dates in different time zones
 * is just the number of nanoseconds between the two points in time.
 * It doesn't take calendar days into account.
 * That means that the difference between two midnights in local time may be
 * less than 24 hours times the number of days between them,
 * if there is a daylight saving change in between.
 * If the difference above is calculated using Australian local time, the
 * difference is 7415 days and 23 hours, which is only 7415 whole days as
 * reported by `inDays`.
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
class DateTime implements Comparable<DateTime> {
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
   * The value of this DateTime.
   *
   * The content of this field is implementation dependent. On JavaScript it is
   * equal to [millisecondsSinceEpoch]. On the VM it is equal to
   * [microsecondsSinceEpoch].
   */
  final int _value;

  /**
   * True if this [DateTime] is set to UTC time.
   *
   * ```
   * var dDay = new DateTime.utc(1944, 6, 6);
   * assert(dDay.isUtc);
   * ```
   *
   */
  final bool isUtc;

  /**
   * Constructs a [DateTime] instance specified in the local time zone.
   *
   * For example,
   * to create a new DateTime object representing the 7th of September 2017,
   * 5:30pm
   *
   * ```
   * var dentistAppointment = new DateTime(2017, 9, 7, 17, 30);
   * ```
   */
  DateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this._internal(year, month, day, hour, minute, second, millisecond,
            microsecond, false);

  /**
   * Constructs a [DateTime] instance specified in the UTC time zone.
   *
   * ```
   * var moonLanding = new DateTime.utc(1969, 7, 20, 20, 18, 04);
   * ```
   *
   * When dealing with dates or historic events prefer to use UTC DateTimes,
   * since they are unaffected by daylight-saving changes and are unaffected
   * by the local timezone.
   */
  DateTime.utc(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this._internal(year, month, day, hour, minute, second, millisecond,
            microsecond, true);

  /**
   * Constructs a [DateTime] instance with current date and time in the
   * local time zone.
   *
   * ```
   * var thisInstant = new DateTime.now();
   * ```
   */
  DateTime.now() : this._now();

  /**
   * Constructs a new [DateTime] instance based on [formattedString].
   *
   * Throws a [FormatException] if the input cannot be parsed.
   *
   * The function parses a subset of ISO 8601
   * which includes the subset accepted by RFC 3339.
   *
   * The accepted inputs are currently:
   *
   * * A date: A signed four-to-six digit year, two digit month and
   *   two digit day, optionally separated by `-` characters.
   *   Examples: "19700101", "-0004-12-24", "81030-04-01".
   * * An optional time part, separated from the date by either `T` or a space.
   *   The time part is a two digit hour,
   *   then optionally a two digit minutes value,
   *   then optionally a two digit seconds value, and
   *   then optionally a '.' followed by a one-to-six digit second fraction.
   *   The minutes and seconds may be separated from the previous parts by a
   *   ':'.
   *   Examples: "12", "12:30:24.124", "123010.50".
   * * An optional time-zone offset part,
   *   possibly separated from the previous by a space.
   *   The time zone is either 'z' or 'Z', or it is a signed two digit hour
   *   part and an optional two digit minute part. The sign must be either
   *   "+" or "-", and can not be omitted.
   *   The minutes may be separated from the hours by a ':'.
   *   Examples: "Z", "-10", "01:30", "1130".
   *
   * This includes the output of both [toString] and [toIso8601String], which
   * will be parsed back into a `DateTime` object with the same time as the
   * original.
   *
   * The result is always in either local time or UTC.
   * If a time zone offset other than UTC is specified,
   * the time is converted to the equivalent UTC time.
   *
   * Examples of accepted strings:
   *
   * * `"2012-02-27 13:27:00"`
   * * `"2012-02-27 13:27:00.123456z"`
   * * `"20120227 13:27:00"`
   * * `"20120227T132700"`
   * * `"20120227"`
   * * `"+20120227"`
   * * `"2012-02-27T14Z"`
   * * `"2012-02-27T14+00:00"`
   * * `"-123450101 00:00:00 Z"`: in the year -12345.
   * * `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
   */
  // TODO(lrn): restrict incorrect values like  2003-02-29T50:70:80.
  // Or not, that may be a breaking change.
  static DateTime parse(String formattedString) {
    /*
     * date ::= yeardate time_opt timezone_opt
     * yeardate ::= year colon_opt month colon_opt day
     * year ::= sign_opt digit{4,6}
     * colon_opt :: <empty> | ':'
     * sign ::= '+' | '-'
     * sign_opt ::=  <empty> | sign
     * month ::= digit{2}
     * day ::= digit{2}
     * time_opt ::= <empty> | (' ' | 'T') hour minutes_opt
     * minutes_opt ::= <empty> | colon_opt digit{2} seconds_opt
     * seconds_opt ::= <empty> | colon_opt digit{2} millis_opt
     * micros_opt ::= <empty> | '.' digit{1,6}
     * timezone_opt ::= <empty> | space_opt timezone
     * space_opt :: ' ' | <empty>
     * timezone ::= 'z' | 'Z' | sign digit{2} timezonemins_opt
     * timezonemins_opt ::= <empty> | colon_opt digit{2}
     */
    final RegExp re = new RegExp(r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' // Day part.
        r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:\.(\d{1,6}))?)?)?' // Time part.
        r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$'); // Timezone part.

    Match match = re.firstMatch(formattedString);
    if (match != null) {
      int parseIntOrZero(String matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }

      // Parses fractional second digits of '.(\d{1,6})' into the combined
      // microseconds.
      int parseMilliAndMicroseconds(String matched) {
        if (matched == null) return 0;
        int length = matched.length;
        assert(length >= 1);
        assert(length <= 6);

        int result = 0;
        for (int i = 0; i < 6; i++) {
          result *= 10;
          if (i < matched.length) {
            result += matched.codeUnitAt(i) ^ 0x30;
          }
        }
        return result;
      }

      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int milliAndMicroseconds = parseMilliAndMicroseconds(match[7]);
      int millisecond =
          milliAndMicroseconds ~/ Duration.MICROSECONDS_PER_MILLISECOND;
      int microsecond =
          milliAndMicroseconds.remainder(Duration.MICROSECONDS_PER_MILLISECOND);
      bool isUtc = false;
      if (match[8] != null) {
        // timezone part
        isUtc = true;
        if (match[9] != null) {
          // timezone other than 'Z' and 'z'.
          int sign = (match[9] == '-') ? -1 : 1;
          int hourDifference = int.parse(match[10]);
          int minuteDifference = parseIntOrZero(match[11]);
          minuteDifference += 60 * hourDifference;
          minute -= sign * minuteDifference;
        }
      }
      int value = _brokenDownDateToValue(years, month, day, hour, minute,
          second, millisecond, microsecond, isUtc);
      if (value == null) {
        throw new FormatException("Time out of range", formattedString);
      }
      return new DateTime._withValue(value, isUtc: isUtc);
    } else {
      throw new FormatException("Invalid date format", formattedString);
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
  external DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc: false});

  /**
   * Constructs a new [DateTime] instance
   * with the given [microsecondsSinceEpoch].
   *
   * If [isUtc] is false then the date is in the local time zone.
   *
   * The constructed [DateTime] represents
   * 1970-01-01T00:00:00Z + [microsecondsSinceEpoch] us in the given
   * time zone (local or UTC).
   */
  external DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc: false});

  /**
   * Constructs a new [DateTime] instance with the given value.
   *
   * If [isUtc] is false then the date is in the local time zone.
   */
  DateTime._withValue(this._value, {this.isUtc}) {
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH ||
        (millisecondsSinceEpoch.abs() == _MAX_MILLISECONDS_SINCE_EPOCH &&
            microsecond != 0)) {
      throw new ArgumentError(
          "DateTime is outside valid range: $millisecondsSinceEpoch");
    }
    if (isUtc == null) {
      throw new ArgumentError("'isUtc' flag may not be 'null'");
    }
  }

  /**
   * Returns true if [other] is a [DateTime] at the same moment and in the
   * same time zone (UTC or local).
   *
   * ```
   * var dDayUtc = new DateTime.utc(1944, 6, 6);
   * var dDayLocal = dDayUtc.toLocal();
   *
   * // These two dates are at the same moment, but are in different zones.
   * assert(dDayUtc != dDayLocal);
   * ```
   *
   * See [isAtSameMomentAs] for a comparison that compares moments in time
   * independently of their zones.
   */
  bool operator ==(other) {
    if (!(other is DateTime)) return false;
    return (_value == other._value && isUtc == other.isUtc);
  }

  /**
   * Returns true if [this] occurs before [other].
   *
   * The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   * ```
   * var now = new DateTime.now();
   * var earlier = now.subtract(const Duration(seconds: 5));
   * assert(earlier.isBefore(now));
   * assert(!now.isBefore(now));
   *
   * // This relation stays the same, even when changing timezones.
   * assert(earlier.isBefore(now.toUtc()));
   * assert(earlier.toUtc().isBefore(now));
   *
   * assert(!now.toUtc().isBefore(now));
   * assert(!now.isBefore(now.toUtc()));
   * ```
   */
  bool isBefore(DateTime other) {
    return _value < other._value;
  }

  /**
   * Returns true if [this] occurs after [other].
   *
   * The comparison is independent
   * of whether the time is in UTC or in the local time zone.
   *
   * ```
   * var now = new DateTime.now();
   * var later = now.add(const Duration(seconds: 5));
   * assert(later.isAfter(now));
   * assert(!now.isBefore(now));
   *
   * // This relation stays the same, even when changing timezones.
   * assert(later.isAfter(now.toUtc()));
   * assert(later.toUtc().isAfter(now));
   *
   * assert(!now.toUtc().isBefore(now));
   * assert(!now.isBefore(now.toUtc()));
   * ```
   */
  bool isAfter(DateTime other) {
    return _value > other._value;
  }

  /**
   * Returns true if [this] occurs at the same moment as [other].
   *
   * The comparison is independent of whether the time is in UTC or in the local
   * time zone.
   *
   * ```
   * var now = new DateTime.now();
   * var later = now.add(const Duration(seconds: 5));
   * assert(!later.isAtSameMomentAs(now));
   * assert(now.isAtSameMomentAs(now));
   *
   * // This relation stays the same, even when changing timezones.
   * assert(!later.isAtSameMomentAs(now.toUtc()));
   * assert(!later.toUtc().isAtSameMomentAs(now));
   *
   * assert(now.toUtc().isAtSameMomentAs(now));
   * assert(now.isAtSameMomentAs(now.toUtc()));
   * ```
   */
  bool isAtSameMomentAs(DateTime other) {
    return _value == other._value;
  }

  /**
   * Compares this DateTime object to [other],
   * returning zero if the values are equal.
   *
   * Returns a negative value if this DateTime [isBefore] [other]. It returns 0
   * if it [isAtSameMomentAs] [other], and returns a positive value otherwise
   * (when this [isAfter] [other]).
   */
  int compareTo(DateTime other) => _value.compareTo(other._value);

  int get hashCode => (_value ^ (_value >> 30)) & 0x3FFFFFFF;

  /**
   * Returns this DateTime value in the local time zone.
   *
   * Returns [this] if it is already in the local time zone.
   * Otherwise this method is equivalent to:
   *
   * ```
   * new DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
   *                                         isUtc: false)
   * ```
   */
  DateTime toLocal() {
    if (isUtc) {
      return new DateTime._withValue(_value, isUtc: false);
    }
    return this;
  }

  /**
   * Returns this DateTime value in the UTC time zone.
   *
   * Returns [this] if it is already in UTC.
   * Otherwise this method is equivalent to:
   *
   * ```
   * new DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
   *                                         isUtc: true)
   * ```
   */
  DateTime toUtc() {
    if (isUtc) return this;
    return new DateTime._withValue(_value, isUtc: true);
  }

  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    int absN = n.abs();
    String sign = n < 0 ? "-" : "+";
    if (absN >= 100000) return "$sign$absN";
    return "${sign}0$absN";
  }

  static String _threeDigits(int n) {
    if (n >= 100) return "${n}";
    if (n >= 10) return "0${n}";
    return "00${n}";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "${n}";
    return "0${n}";
  }

  /**
   * Returns a human-readable string for this instance.
   *
   * The returned string is constructed for the time zone of this instance.
   * The `toString()` method provides a simply formatted string.
   * It does not support internationalized strings.
   * Use the [intl](http://pub.dartlang.org/packages/intl) package
   * at the pub shared packages repo.
   *
   * The resulting string can be parsed back using [parse].
   */
  String toString() {
    String y = _fourDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms$us";
    }
  }

  /**
   * Returns an ISO-8601 full-precision extended format representation.
   *
   * The format is `yyyy-MM-ddTHH:mm:ss.mmmuuuZ` for UTC time, and
   * `yyyy-MM-ddTHH:mm:ss.mmmuuu` (no trailing "Z") for local/non-UTC time,
   * where:
   *
   * * `yyyy` is a, possibly negative, four digit representation of the year,
   *   if the year is in the range -9999 to 9999,
   *   otherwise it is a signed six digit representation of the year.
   * * `MM` is the month in the range 01 to 12,
   * * `dd` is the day of the month in the range 01 to 31,
   * * `HH` are hours in the range 00 to 23,
   * * `mm` are minutes in the range 00 to 59,
   * * `ss` are seconds in the range 00 to 59 (no leap seconds),
   * * `mmm` are milliseconds in the range 000 to 999, and
   * * `uuu` are microseconds in the range 001 to 999. If [microsecond] equals
   *   0, then this part is omitted.
   *
   * The resulting string can be parsed back using [parse].
   */
  String toIso8601String() {
    String y =
        (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-${d}T$h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-${d}T$h:$min:$sec.$ms$us";
    }
  }

  /**
   * Returns a new [DateTime] instance with [duration] added to [this].
   *
   * ```
   * var today = new DateTime.now();
   * var fiftyDaysFromNow = today.add(new Duration(days: 50));
   * ```
   *
   * Notice that the duration being added is actually 50 * 24 * 60 * 60
   * seconds. If the resulting `DateTime` has a different daylight saving offset
   * than `this`, then the result won't have the same time-of-day as `this`, and
   * may not even hit the calendar date 50 days later.
   *
   * Be careful when working with dates in local time.
   */
  external DateTime add(Duration duration);

  /**
   * Returns a new [DateTime] instance with [duration] subtracted from [this].
   *
   * ```
   * DateTime today = new DateTime.now();
   * DateTime fiftyDaysAgo = today.subtract(new Duration(days: 50));
   * ```
   *
   * Notice that the duration being subtracted is actually 50 * 24 * 60 * 60
   * seconds. If the resulting `DateTime` has a different daylight saving offset
   * than `this`, then the result won't have the same time-of-day as `this`, and
   * may not even hit the calendar date 50 days earlier.
   *
   * Be careful when working with dates in local time.
   */
  external DateTime subtract(Duration duration);

  /**
   * Returns a [Duration] with the difference between [this] and [other].
   *
   * ```
   * var berlinWallFell = new DateTime.utc(1989, DateTime.NOVEMBER, 9);
   * var dDay = new DateTime.utc(1944, DateTime.JUNE, 6);
   *
   * Duration difference = berlinWallFell.difference(dDay);
   * assert(difference.inDays == 16592);
   * ```
   *
   * The difference is measured in seconds and fractions of seconds.
   * The difference above counts the number of fractional seconds between
   * midnight at the beginning of those dates.
   * If the dates above had been in local time, not UTC, then the difference
   * between two midnights may not be a multiple of 24 hours due to daylight
   * saving differences.
   *
   * For example, in Australia, similar code using local time instead of UTC:
   *
   * ```
   * var berlinWallFell = new DateTime(1989, DateTime.NOVEMBER, 9);
   * var dDay = new DateTime(1944, DateTime.JUNE, 6);
   * Duration difference = berlinWallFell.difference(dDay);
   * assert(difference.inDays == 16592);
   * ```
   * will fail because the difference is actually 16591 days and 23 hours, and
   * [Duration.inDays] only returns the number of whole days.
   */
  external Duration difference(DateTime other);

  external DateTime._internal(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc);

  external DateTime._now();

  /// Returns the time as value (millisecond or microsecond since epoch), or
  /// null if the values are out of range.
  external static int _brokenDownDateToValue(
      int year,
      int month,
      int day,
      int hour,
      int minute,
      int second,
      int millisecond,
      int microsecond,
      bool isUtc);

  /**
   * The number of milliseconds since
   * the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
   *
   * This value is independent of the time zone.
   *
   * This value is at most
   * 8,640,000,000,000,000ms (100,000,000 days) from the Unix epoch.
   * In other words: `millisecondsSinceEpoch.abs() <= 8640000000000000`.
   */
  external int get millisecondsSinceEpoch;

  /**
   * The number of microseconds since
   * the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
   *
   * This value is independent of the time zone.
   *
   * This value is at most
   * 8,640,000,000,000,000,000us (100,000,000 days) from the Unix epoch.
   * In other words: `microsecondsSinceEpoch.abs() <= 8640000000000000000`.
   *
   * Note that this value does not fit into 53 bits (the size of a IEEE double).
   * A JavaScript number is not able to hold this value.
   */
  external int get microsecondsSinceEpoch;

  /**
   * The time zone name.
   *
   * This value is provided by the operating system and may be an
   * abbreviation or a full name.
   *
   * In the browser or on Unix-like systems commonly returns abbreviations,
   * such as "CET" or "CEST". On Windows returns the full name, for example
   * "Pacific Standard Time".
   */
  external String get timeZoneName;

  /**
   * The time zone offset, which
   * is the difference between local time and UTC.
   *
   * The offset is positive for time zones east of UTC.
   *
   * Note, that JavaScript, Python and C return the difference between UTC and
   * local time. Java, C# and Ruby return the difference between local time and
   * UTC.
   */
  external Duration get timeZoneOffset;

  /**
   * The year.
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.year == 1969);
   * ```
   */
  external int get year;

  /**
   * The month [1..12].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.month == 7);
   * assert(moonLanding.month == DateTime.JULY);
   * ```
   */
  external int get month;

  /**
   * The day of the month [1..31].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.day == 20);
   * ```
   */
  external int get day;

  /**
   * The hour of the day, expressed as in a 24-hour clock [0..23].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.hour == 20);
   * ```
   */
  external int get hour;

  /**
   * The minute [0...59].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.minute == 18);
   * ```
   */
  external int get minute;

  /**
   * The second [0...59].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.second == 4);
   * ```
   */
  external int get second;

  /**
   * The millisecond [0...999].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.millisecond == 0);
   * ```
   */
  external int get millisecond;

  /**
   * The microsecond [0...999].
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.microsecond == 0);
   * ```
   */
  external int get microsecond;

  /**
   * The day of the week [MONDAY]..[SUNDAY].
   *
   * In accordance with ISO 8601
   * a week starts with Monday, which has the value 1.
   *
   * ```
   * var moonLanding = DateTime.parse("1969-07-20 20:18:04Z");
   * assert(moonLanding.weekday == 7);
   * assert(moonLanding.weekday == DateTime.SUNDAY);
   * ```
   */
  external int get weekday;
}
