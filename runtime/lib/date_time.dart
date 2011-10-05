// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

class TimeZoneImplementation implements TimeZone {
  Time get offset() {
    if (isUtc) return const Time.duration(0);
    throw "Unimplemented";
  }
  factory TimeZoneImplementation(Time offset) {
    if (offset.duration == 0) {
      return const TimeZoneImplementation.utc();
    } else {
      throw "Unimplemented";
    }
  }

  const TimeZoneImplementation.utc() : isUtc = true;
  TimeZoneImplementation.local() : isUtc = false {}

  bool operator ==(Object other) {
    if (!(other is TimeZoneImplementation)) return false;
    return isUtc == other.isUtc;
  }

  final bool isUtc;
}

// JavaScript implementation of DateTimeImplementation.
class DateTimeImplementation implements DateTime {
  factory DateTimeImplementation(int years,
                                 int month,
                                 int day,
                                 int hours,
                                 int minutes,
                                 int seconds,
                                 int milliseconds) {
    return new DateTimeImplementation.withTimeZone(
        years, month, day,
        hours, minutes, seconds, milliseconds,
        new TimeZoneImplementation.local());
  }

  DateTimeImplementation.withTimeZone(int years,
                                      int month,
                                      int day,
                                      int hours,
                                      int minutes,
                                      int seconds,
                                      int milliseconds,
                                      TimeZoneImplementation timeZone)
  : timeZone = timeZone,
    value = brokenDownDateTimeToMillisecondsSinceEpoch_(
               years, month, day, hours, minutes, seconds, milliseconds,
               timeZone.isUtc) {}

  factory DateTimeImplementation.fromDateAndTime(
      Date date,
      Time time,
      TimeZoneImplementation timeZone) {
    if (timeZone === null) {
      timeZone = new TimeZoneImplementation.local();
    }
    return new DateTimeImplementation.withTimeZone(date.year,
                                                   date.month,
                                                   date.day + time.days,
                                                   time.hours,
                                                   time.minutes,
                                                   time.seconds,
                                                   time.milliseconds,
                                                   timeZone);
  }

  DateTimeImplementation.now()
  : timeZone = new TimeZone.local(),
    value = getCurrentMs_() {
  }

  factory DateTimeImplementation.fromString(String formattedString) {
    int substringToNumber(String str, int from, int to) {
      int result = 0;
      for (int i = from; i < to; i++) {
        result = result * 10 + str.charCodeAt(i) - "0".charCodeAt(0);
      }
      return result;
    }

    // TODO(floitsch): improve DateTimeImplementation parsing.
    // Parse ISO 8601: "2011-05-14 00:37:18.231Z".
    int yearMonthSeparator = formattedString.indexOf("-", 0);
    if (yearMonthSeparator < 0) throw "UNIMPLEMENTED";
    int monthDaySeparator =
      formattedString.indexOf("-", yearMonthSeparator + 1);
    if (monthDaySeparator < 0) throw "UNIMPLEMENTED";
    int dateTimeSeparator = formattedString.indexOf(" ", monthDaySeparator + 1);
    if (dateTimeSeparator < 0) throw "UNIMPLEMENTED";
    int hoursMinutesSeparator =
        formattedString.indexOf(":", dateTimeSeparator + 1);
    if (hoursMinutesSeparator < 0) throw "UNIMPLEMENTED";
    int minutesSecondsSeparator =
        formattedString.indexOf(":", hoursMinutesSeparator + 1);
    if (minutesSecondsSeparator < 0) throw "UNIMPLEMENTED";
    int secondsMillisecondsSeparator =
        formattedString.indexOf(".", minutesSecondsSeparator + 1);
    bool isUtc = formattedString.endsWith("Z");
    int end = formattedString.length - (isUtc ? 1 : 0);
    if (secondsMillisecondsSeparator < 0) secondsMillisecondsSeparator = end;

    int year = substringToNumber(formattedString, 0, yearMonthSeparator);
    int month = substringToNumber(formattedString,
                                  yearMonthSeparator + 1,
                                  monthDaySeparator);
    int day = substringToNumber(formattedString,
                                monthDaySeparator + 1,
                                dateTimeSeparator);
    int hours = substringToNumber(formattedString,
                                  dateTimeSeparator + 1,
                                  hoursMinutesSeparator);
    int minutes = substringToNumber(formattedString,
                                    hoursMinutesSeparator + 1,
                                    minutesSecondsSeparator);
    int seconds = substringToNumber(formattedString,
                                    minutesSecondsSeparator + 1,
                                    secondsMillisecondsSeparator);
    int milliseconds = substringToNumber(formattedString,
                                         secondsMillisecondsSeparator + 1,
                                         end);
    TimeZone timeZone = (isUtc ? const TimeZone.utc() : new TimeZone.local());
    return new DateTimeImplementation.withTimeZone(
        year, month, day, hours, minutes, seconds, milliseconds, timeZone);
  }

  const DateTimeImplementation.fromEpoch(int this.value,
                                         TimeZone this.timeZone);

  bool operator ==(Object other) {
    if (!(other is DateTimeImplementation)) return false;
    return value == other.value && timeZone == other.timeZone;
  }

  int compareTo(DateTime other) {
    return value.compareTo(other.value);
  }

  DateTime changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone === null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new DateTime.fromEpoch(value, targetTimeZone);
  }

  Date get date() {
    return new DateImplementation(year, month, day);
  }

  Time get time() {
    return new TimeImplementation(0, hours, minutes, seconds, milliseconds);
  }

  int get year() {
    int secondsSinceEpoch = secondsSinceEpoch_;
    // According to V8 some library calls have troubles with negative values.
    // Therefore clamp to 0 - year 2035 (which is less than the size of 32bit).
    if (secondsSinceEpoch >= 0 && secondsSinceEpoch < SECONDS_YEAR_2035_) {
      return getYear_(secondsSinceEpoch, timeZone.isUtc);
    }

    // Approximate the result. We don't take timeZone into account.
    int approximateYear = yearsFromSecondsSinceEpoch_(secondsSinceEpoch);
    int equivalentYear = equivalentYear_(approximateYear);
    int y = getYear_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
    return approximateYear + (y - equivalentYear);
  }

  int get month() {
    return getMonth_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
  }

  int get day() {
    return getDay_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
  }

  int get hours() {
    return getHours_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
  }

  int get minutes() {
    return getMinutes_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
  }

  int get seconds() {
    return getSeconds_(equivalentSeconds_(secondsSinceEpoch_), timeZone.isUtc);
  }

  int get milliseconds() {
    return value % Time.MS_PER_SECOND;
  }

  int get secondsSinceEpoch_() {
    // Always round down.
    if (value < 0) {
      return (value + 1) ~/ Time.MS_PER_SECOND - 1;
    } else {
      return value ~/ Time.MS_PER_SECOND;
    }
  }

  int get weekday() {
    throw "Unimplemented";
  }

  bool isLocalTime() {
    return !timeZone.isUtc;
  }

  bool isUtc() {
    return timeZone.isUtc;
  }

  String toString() {
    // TODO(floitsch): switch to string-interpolation.
    if (timeZone.isUtc) {
      return date.toString() + " " + time.toString() + "Z";
    } else {
      return date.toString() + " " + time.toString();
    }
  }

  // Adds the duration [time] to this DateTime instance.
  DateTime add(Time time) {
    return new DateTimeImplementation.fromEpoch(value + time.duration,
                                                timeZone);
  }

  // Subtracts the duration [time] from this DateTime instance.
  DateTime subtract(Time time) {
    return new DateTimeImplementation.fromEpoch(value - time.duration,
                                                timeZone);
  }

  // Returns a [Time] with the difference of [this] and [other].
  Time difference(DateTime other) {
    return new TimeImplementation.duration(value - other.value);
  }

  final int value;
  final TimeZoneImplementation timeZone;

  static final int SECONDS_YEAR_2035_ = 2051222400;

  // Returns the UTC year for the corresponding [secondsSinceEpoch].
  // It is relatively fast for values in the range 0 to year 2098.
  // Code is adapted from V8.
  static int yearsFromSecondsSinceEpoch_(int secondsSinceEpoch) {
    final int DAYS_IN_4_YEARS = 4 * 365 + 1;
    final int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    final int DAYS_IN_400_YEARS = 4 * DAYS_IN_100_YEARS + 1;
    final int DAYS_1970_TO_2000 = 30 * 365 + 7;
    final int DAYS_OFFSET = 1000 * DAYS_IN_400_YEARS + 5 * DAYS_IN_400_YEARS -
                            DAYS_1970_TO_2000;
    final int YEARS_OFFSET = 400000;
    final int DAYS_YEAR_2098 = DAYS_IN_100_YEARS + 6 * DAYS_IN_4_YEARS;

    int days = secondsSinceEpoch ~/ Time.SECONDS_PER_DAY;
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
  // time in an equivalent year (see [equivalentYear_]).
  // Leap seconds are ignored.
  static int equivalentSeconds_(int secondsSinceEpoch) {
    if (secondsSinceEpoch >= 0 && secondsSinceEpoch < SECONDS_YEAR_2035_) {
      return secondsSinceEpoch;
    }
    int year = yearsFromSecondsSinceEpoch_(secondsSinceEpoch);
    int days = dayFromYear_(year);
    int equivalentYear = equivalentYear_(year);
    int equivalentDays = dayFromYear_(equivalentYear);
    int diffDays = equivalentDays - days;
    return secondsSinceEpoch + diffDays * Time.SECONDS_PER_DAY;
  }

  // Returns the days since 1970 for the start of the given [year].
  // [year] may be before epoch.
  static int dayFromYear_(int year) {
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
  static equivalentYear_(int year) {
    // Returns 1 if in leap year. 0 otherwise.
    bool inLeapYear(year) {
      return (year.remainder(4) == 0) &&
             ((year.remainder(100) != 0) || (year.remainder(400) == 0));
    }

    // Returns the week day (in range 0 - 6).
    int weekDay(year) {
      // 1/1/1970 was a Thursday.
      return (dayFromYear_(year) + 4) % 7;
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

  static brokenDownDateTimeToMillisecondsSinceEpoch_(
      int years, int month, int day,
      int hours, int minutes, int seconds, int milliseconds,
      bool isUtc) {
    if ((month < 1) || (month > 12)) {
      throw new IllegalArgumentException();
    }
    if ((day < 1) || (day > 31)) {
      throw new IllegalArgumentException();
    }
    // Leap seconds can lead to hours == 24.
    if ((hours < 0) || (hours > 24)) {
      throw new IllegalArgumentException();
    }
    if ((hours == 24) && ((minutes != 0) || (seconds != 0))) {
      throw new IllegalArgumentException();
    }
    if ((minutes < 0) || (minutes > 59)) {
      throw new IllegalArgumentException();
    }
    if ((seconds < 0) || (seconds > 59)) {
      throw new IllegalArgumentException();
    }
    if ((milliseconds < 0) || (milliseconds > 999)) {
      throw new IllegalArgumentException();
    }
    int equivalentYear;
    int offsetInSeconds;
    // According to V8 some library calls have troubles with negative values.
    // Therefore clamp to 1970 - year 2035 (which is less than the size of
    // 32bit).
    // We exclude the year 1970 when the time is not UTC, since the epoch
    // value could then be negative.
    if (years < (isUtc ? 1970 : 1971) || years > 2035) {
      equivalentYear = equivalentYear_(years);
      int offsetInDays = (dayFromYear_(years) - dayFromYear_(equivalentYear));
      // Leap seconds are ignored.
      offsetInSeconds = offsetInDays * Time.SECONDS_PER_DAY;
    } else {
      equivalentYear = years;
      offsetInSeconds = 0;
    }
    int secondsSinceEpoch = brokenDownDateTimeToSecondsSinceEpoch_(
        equivalentYear, month, day, hours, minutes, seconds, isUtc);
    int adjustedSeconds = secondsSinceEpoch + offsetInSeconds;
    return adjustedSeconds * Time.MS_PER_SECOND + milliseconds;
  }

  // Natives
  static brokenDownDateTimeToSecondsSinceEpoch_(
      int years, int month, int day, int hours, int minutes, int seconds,
      bool isUtc) native "DateTimeNatives_brokenDownToSecondsSinceEpoch";

  static int getCurrentMs_() native "DateTimeNatives_currentTimeMillis";

  // TODO(floitsch): it would be more efficient if we didn't call the native
  // function for every member, but cached the broken-down date.
  static int getYear_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getYear";

  static int getMonth_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getMonth";

  static int getDay_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getDay";

  static int getHours_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getHours";

  static int getMinutes_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getMinutes";

  static int getSeconds_(int secondsSinceEpoch, bool isUtc)
      native "DateTimeNatives_getSeconds";
}
