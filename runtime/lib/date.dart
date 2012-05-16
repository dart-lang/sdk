// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

class TimeZoneImplementation implements TimeZone {
  const TimeZoneImplementation.utc() : isUtc = true;
  TimeZoneImplementation.local() : isUtc = false {}

  bool operator ==(Object other) {
    if (!(other is TimeZoneImplementation)) return false;
    return isUtc == other.isUtc;
  }

  final bool isUtc;
}

// JavaScript implementation of DateImplementation.
class DateImplementation implements Date {
  factory DateImplementation(int years,
                             [int month = 1,
                              int day = 1,
                              int hours = 0,
                              int minutes = 0,
                              int seconds = 0,
                              int milliseconds = 0]) {
    return new DateImplementation.withTimeZone(
        years, month, day,
        hours, minutes, seconds, milliseconds,
        new TimeZoneImplementation.local());
  }

  DateImplementation.withTimeZone(int years,
                                  int month,
                                  int day,
                                  int hours,
                                  int minutes,
                                  int seconds,
                                  int milliseconds,
                                  TimeZone timeZone)
  : timeZone = timeZone,
    value = _brokenDownDateToMillisecondsSinceEpoch(
               years, month, day, hours, minutes, seconds, milliseconds,
               timeZone.isUtc) {
    if (value === null) throw new IllegalArgumentException();
  }

  DateImplementation.now()
  : timeZone = new TimeZone.local(),
    value = _getCurrentMs() {
  }

  factory DateImplementation.fromString(String formattedString) {
    // Read in (a subset of) ISO 8601.
    // Examples:
    //    - "2012-02-27 13:27:00"
    //    - "2012-02-27 13:27:00.423z"
    //    - "20120227 13:27:00"
    //    - "20120227T132700"
    //    - "20120227"
    //    - "2012-02-27T14Z"
    //    - "-123450101 00:00:00 Z"  // In the year -12345.
    final RegExp re = const RegExp(
        @'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)' +  // The day part.
        @'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match !== null) {
      int parseIntOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0;
        return Math.parseInt(matched);
      }

      double parseDoubleOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0.0;
        return Math.parseDouble(matched);
      }

      int years = Math.parseInt(match[1]);
      int month = Math.parseInt(match[2]);
      int day = Math.parseInt(match[3]);
      int hours = parseIntOrZero(match[4]);
      int minutes = parseIntOrZero(match[5]);
      int seconds = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int milliseconds = (parseDoubleOrZero(match[7]) * 1000).round().toInt();
      if (milliseconds == 1000) {
        addOneMillisecond = true;
        milliseconds = 999;
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] !== null) && (match[8] != "");
      TimeZone timezone = isUtc ? const TimeZone.utc() : new TimeZone.local();
      int epochValue = _brokenDownDateToMillisecondsSinceEpoch(
          years, month, day, hours, minutes, seconds, milliseconds, isUtc);
      if (epochValue === null) {
        throw new IllegalArgumentException(formattedString);
      }
      if (addOneMillisecond) epochValue++;
      return new DateImplementation.fromEpoch(epochValue, timezone);
    } else {
      throw new IllegalArgumentException(formattedString);
    }
  }

  const DateImplementation.fromEpoch(int this.value,
                                     TimeZone this.timeZone);

  bool operator ==(Object other) {
    if (!(other is DateImplementation)) return false;
    return value == other.value && timeZone == other.timeZone;
  }

  bool operator <(Date other) => value < other.value;

  bool operator <=(Date other) => value <= other.value;

  bool operator >(Date other) => value > other.value;

  bool operator >=(Date other) => value >= other.value;

  int compareTo(Date other) => value.compareTo(other.value);
  int hashCode() => value;

  Date changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone === null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new Date.fromEpoch(value, targetTimeZone);
  }

  int get year() {
    int secondsSinceEpoch = _secondsSinceEpoch;
    // According to V8 some library calls have troubles with negative values.
    // Therefore clamp to 0 - year 2035 (which is less than the size of 32bit).
    if (secondsSinceEpoch >= 0 && secondsSinceEpoch < _SECONDS_YEAR_2035) {
      return _getYear(secondsSinceEpoch, timeZone.isUtc);
    }

    // Approximate the result. We don't take timeZone into account.
    int approximateYear = _yearsFromSecondsSinceEpoch(secondsSinceEpoch);
    int equivalentYear = _equivalentYear(approximateYear);
    int y = _getYear(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
    return approximateYear + (y - equivalentYear);
  }

  int get month() {
    return _getMonth(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
  }

  int get day() {
    return _getDay(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
  }

  int get hours() {
    return _getHours(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
  }

  int get minutes() {
    return _getMinutes(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
  }

  int get seconds() {
    return _getSeconds(_equivalentSeconds(_secondsSinceEpoch), timeZone.isUtc);
  }

  int get milliseconds() {
    return value % Duration.MILLISECONDS_PER_SECOND;
  }

  int get _secondsSinceEpoch() {
    // Always round down.
    if (value < 0) {
      return (value + 1) ~/ Duration.MILLISECONDS_PER_SECOND - 1;
    } else {
      return value ~/ Duration.MILLISECONDS_PER_SECOND;
    }
  }

  int get weekday() {
    final Date unixTimeStart =
    new Date.withTimeZone(1970, 1, 1, 0, 0, 0, 0, timeZone);
    int msSince1970 = this.difference(unixTimeStart).inMilliseconds;
    // Adjust the milliseconds to avoid problems with summer-time.
    if (hours < 2) {
      msSince1970 += 2 * Duration.MILLISECONDS_PER_HOUR;
    }
    // Compute the floor of msSince1970 / Duration.MS_PER_DAY.
    int daysSince1970;
    if (msSince1970 >= 0) {
      daysSince1970 = msSince1970 ~/ Duration.MILLISECONDS_PER_DAY;
    } else {
      daysSince1970 = (msSince1970 - Duration.MILLISECONDS_PER_DAY + 1) ~/
                      Duration.MILLISECONDS_PER_DAY;
    }
    // 1970-1-1 was a Thursday.
    return ((daysSince1970 + Date.THU) % Date.DAYS_IN_WEEK);
  }

  bool isLocalTime() {
    return !timeZone.isUtc;
  }

  bool isUtc() {
    return timeZone.isUtc;
  }

  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      if (absN >= 1) return "${sign}000$absN";
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
    String h = twoDigits(hours);
    String min = twoDigits(minutes);
    String sec = twoDigits(seconds);
    String ms = threeDigits(milliseconds);
    if (timeZone.isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  // Adds the [duration] to this Date instance.
  Date add(Duration duration) {
    return new DateImplementation.fromEpoch(value + duration.inMilliseconds,
                                            timeZone);
  }

  // Subtracts the [duration] from this Date instance.
  Date subtract(Duration duration) {
    return new DateImplementation.fromEpoch(value - duration.inMilliseconds,
                                            timeZone);
  }

  // Returns a [Duration] with the difference of [this] and [other].
  Duration difference(Date other) {
    return new DurationImplementation(milliseconds: value - other.value);
  }

  final int value;
  final TimeZoneImplementation timeZone;

  static final int _SECONDS_YEAR_2035 = 2051222400;

  // Returns the UTC year for the corresponding [secondsSinceEpoch].
  // It is relatively fast for values in the range 0 to year 2098.
  // Code is adapted from V8.
  static int _yearsFromSecondsSinceEpoch(int secondsSinceEpoch) {
    final int DAYS_IN_4_YEARS = 4 * 365 + 1;
    final int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    final int DAYS_IN_400_YEARS = 4 * DAYS_IN_100_YEARS + 1;
    final int DAYS_1970_TO_2000 = 30 * 365 + 7;
    final int DAYS_OFFSET = 1000 * DAYS_IN_400_YEARS + 5 * DAYS_IN_400_YEARS -
                            DAYS_1970_TO_2000;
    final int YEARS_OFFSET = 400000;
    final int DAYS_YEAR_2098 = DAYS_IN_100_YEARS + 6 * DAYS_IN_4_YEARS;

    int days = secondsSinceEpoch ~/ Duration.SECONDS_PER_DAY;
    if (days > 0 && days < DAYS_YEAR_2098) {
      // According to V8 this fast case works for dates from 1970 to 2099.
      return 1970 + (4 * days + 2) ~/ DAYS_IN_4_YEARS;
    } else {
      days += DAYS_OFFSET;
      int result = 400 * (days ~/ DAYS_IN_400_YEARS) - YEARS_OFFSET;
      days = days.remainder(DAYS_IN_400_YEARS);
      days--;
      int yd1 = days ~/ DAYS_IN_100_YEARS;
      days = days.remainder(DAYS_IN_100_YEARS);
      result += 100 * yd1;
      days++;
      int yd2 = days ~/ DAYS_IN_4_YEARS;
      days = days.remainder(DAYS_IN_4_YEARS);
      result += 4 * yd2;
      days--;
      int yd3 = days ~/ 365;
      days = days.remainder(365);
      result += yd3;
      return result;
    }
  }

  // Given [secondsSinceEpoch] returns seconds such that they are at the same
  // time in an equivalent year (see [_equivalentYear]).
  // Leap seconds are ignored.
  static int _equivalentSeconds(int secondsSinceEpoch) {
    if (secondsSinceEpoch >= 0 && secondsSinceEpoch < _SECONDS_YEAR_2035) {
      return secondsSinceEpoch;
    }
    int year = _yearsFromSecondsSinceEpoch(secondsSinceEpoch);
    int days = _dayFromYear(year);
    int equivalentYear = _equivalentYear(year);
    int equivalentDays = _dayFromYear(equivalentYear);
    int diffDays = equivalentDays - days;
    return secondsSinceEpoch + diffDays * Duration.SECONDS_PER_DAY;
  }

  // Returns the days since 1970 for the start of the given [year].
  // [year] may be before epoch.
  static int _dayFromYear(int year) {
    int flooredDivision(int a, int b) {
      return (a - (a < 0 ? b - 1 : 0)) ~/ b;
    }

    return 365 * (year - 1970)
            + flooredDivision(year - 1969, 4)
            - flooredDivision(year - 1901, 100)
            + flooredDivision(year - 1601, 400);
  }

  // Returns a year in the range 2008-2035 matching
  // - leap year, and
  // - week day of first day.
  // Leap seconds are ignored.
  // Adapted from V8's date implementation. See ECMA 262 - 15.9.1.9.
  static _equivalentYear(int year) {
    // Returns 1 if in leap year. 0 otherwise.
    bool inLeapYear(year) {
      return (year.remainder(4) == 0) &&
             ((year.remainder(100) != 0) || (year.remainder(400) == 0));
    }

    // Returns the week day (in range 0 - 6).
    int weekDay(year) {
      // 1/1/1970 was a Thursday.
      return (_dayFromYear(year) + 4) % 7;
    }
    // 1/1/1956 was a Sunday (i.e. weekday 0). 1956 was a leap-year.
    // 1/1/1967 was a Sunday (i.e. weekday 0).
    // Without leap years a subsequent year has a week day + 1 (for example
    // 1/1/1968 was a Monday). With leap-years it jumps over one week day
    // (e.g. 1/1/1957 was a Tuesday).
    // After 12 years the weekdays have advanced by 12 days + 3 leap days =
    // 15 days. 15 % 7 = 1. So after 12 years the week day has always
    // (now independently of leap-years) advanced by one.
    // weekDay * 12 gives thus a year starting with the wanted weekDay.
    int recentYear = (inLeapYear(year) ? 1956 : 1967) + (weekDay(year) * 12);
    // Close to the year 2008 the calendar cycles every 4 * 7 years (4 for the
    // leap years, 7 for the weekdays).
    // Find the year in the range 2008..2037 that is equivalent mod 28.
    return 2008 + (recentYear - 2008) % 28;
  }

  static _brokenDownDateToMillisecondsSinceEpoch(
      int years, int month, int day,
      int hours, int minutes, int seconds, int milliseconds,
      bool isUtc) {
    if ((month < 1) || (month > 12)) return null;
    if ((day < 1) || (day > 31)) return null;
    // Leap seconds can lead to hours == 24.
    if ((hours < 0) || (hours > 24)) return null;
    if ((hours == 24) && ((minutes != 0) || (seconds != 0))) return null;
    if ((minutes < 0) || (minutes > 59)) return null;
    if ((seconds < 0) || (seconds > 59)) return null;
    if ((milliseconds < 0) || (milliseconds > 999)) return null;

    int equivalentYear;
    int offsetInSeconds;
    // According to V8 some library calls have troubles with negative values.
    // Therefore clamp to 1970 - year 2035 (which is less than the size of
    // 32bit).
    // We exclude the year 1970 when the time is not UTC, since the epoch
    // value could then be negative.
    if (years < (isUtc ? 1970 : 1971) || years > 2035) {
      equivalentYear = _equivalentYear(years);
      int offsetInDays = (_dayFromYear(years) - _dayFromYear(equivalentYear));
      // Leap seconds are ignored.
      offsetInSeconds = offsetInDays * Duration.SECONDS_PER_DAY;
    } else {
      equivalentYear = years;
      offsetInSeconds = 0;
    }
    int secondsSinceEpoch = _brokenDownDateToSecondsSinceEpoch(
        equivalentYear, month, day, hours, minutes, seconds, isUtc);
    int adjustedSeconds = secondsSinceEpoch + offsetInSeconds;
    return adjustedSeconds * Duration.MILLISECONDS_PER_SECOND + milliseconds;
  }

  // Natives
  static _brokenDownDateToSecondsSinceEpoch(
      int years, int month, int day, int hours, int minutes, int seconds,
      bool isUtc) native "DateNatives_brokenDownToSecondsSinceEpoch";

  static int _getCurrentMs() native "DateNatives_currentTimeMillis";

  // TODO(floitsch): it would be more efficient if we didn't call the native
  // function for every member, but cached the broken-down date.
  static int _getYear(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getYear";

  static int _getMonth(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getMonth";

  static int _getDay(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getDay";

  static int _getHours(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getHours";

  static int _getMinutes(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getMinutes";

  static int _getSeconds(int secondsSinceEpoch, bool isUtc)
      native "DateNatives_getSeconds";
}
