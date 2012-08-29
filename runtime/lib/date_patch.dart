// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of DateImplementation.
patch class DateImplementation {
  /* patch */ DateImplementation(int year,
                                 [int month = 1,
                                  int day = 1,
                                  int hour = 0,
                                  int minute = 0,
                                  int second = 0,
                                  int millisecond = 0,
                                  bool isUtc = false])
      : this.isUtc = isUtc,
        this.millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(
            year, month, day, hour, minute, second, millisecond, isUtc) {
    if (millisecondsSinceEpoch === null) throw new IllegalArgumentException();
    if (isUtc === null) throw new IllegalArgumentException();
  }

  /* patch */ DateImplementation.now()
      : isUtc = false,
        millisecondsSinceEpoch = _getCurrentMs() {
  }

  /* patch */ String get timeZoneName() {
    if (isUtc) return "UTC";
    return _timeZoneName(millisecondsSinceEpoch);
  }

  /* patch */ Duration get timeZoneOffset() {
    if (isUtc) return new Duration(0);
    int offsetInSeconds = _timeZoneOffsetInSeconds(millisecondsSinceEpoch);
    return new Duration(seconds: offsetInSeconds);
  }

  /* patch */ int get year() => _decomposeIntoYearMonthDay(_localDateInUtcMs)[0];

  /* patch */ int get month() => _decomposeIntoYearMonthDay(_localDateInUtcMs)[1];

  /* patch */ int get day() => _decomposeIntoYearMonthDay(_localDateInUtcMs)[2];

  /* patch */ int get hour() {
    int valueInHours = _flooredDivision(_localDateInUtcMs,
                                        Duration.MILLISECONDS_PER_HOUR);
    return valueInHours % Duration.HOURS_PER_DAY;
  }

  /* patch */ int get minute() {
    int valueInMinutes = _flooredDivision(_localDateInUtcMs,
                                          Duration.MILLISECONDS_PER_MINUTE);
    return valueInMinutes % Duration.MINUTES_PER_HOUR;
  }

  /* patch */ int get second() {
    // Seconds are unaffected by the timezone the user is in. So we can
    // directly use the millisecondsSinceEpoch and not [_localDateInUtcMs].
    int valueInSeconds =
        _flooredDivision(millisecondsSinceEpoch,
                         Duration.MILLISECONDS_PER_SECOND);
    return valueInSeconds % Duration.SECONDS_PER_MINUTE;
  }

  /* patch */ int get millisecond() {
    // Milliseconds are unaffected by the timezone the user is in. So we can
    // directly use the value and not the [_localDateInUtcValue].
    return millisecondsSinceEpoch % Duration.MILLISECONDS_PER_SECOND;
  }

  /** Returns the weekday of [this]. In accordance with ISO 8601 a week
    * starts with Monday. Monday has the value 1 up to Sunday with 7. */
  /* patch */ int get weekday() {
    int daysSince1970 =
        _flooredDivision(_localDateInUtcMs, Duration.MILLISECONDS_PER_DAY);
    // 1970-1-1 was a Thursday.
    return ((daysSince1970 + Date.THU - Date.MON) % Date.DAYS_IN_WEEK) +
        Date.MON;
  }


  /** The first list contains the days until each month in non-leap years. The
    * second list contains the days in leap years. */
  static const List<List<int>> _DAYS_UNTIL_MONTH =
      const [const [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
             const [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]];

  // Returns the UTC year, month and day for the corresponding
  // [millisecondsSinceEpoch].
  // Code is adapted from V8.
  static List<int> _decomposeIntoYearMonthDay(int millisecondsSinceEpoch) {
    // TODO(floitsch): cache result.
    final int DAYS_IN_4_YEARS = 4 * 365 + 1;
    final int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    final int DAYS_IN_400_YEARS = 4 * DAYS_IN_100_YEARS + 1;
    final int DAYS_1970_TO_2000 = 30 * 365 + 7;
    final int DAYS_OFFSET = 1000 * DAYS_IN_400_YEARS + 5 * DAYS_IN_400_YEARS -
                            DAYS_1970_TO_2000;
    final int YEARS_OFFSET = 400000;

    int resultYear = 0;
    int resultMonth = 0;
    int resultDay = 0;

    // Always round down.
    int days = _flooredDivision(millisecondsSinceEpoch,
                                Duration.MILLISECONDS_PER_DAY);
    days += DAYS_OFFSET;
    resultYear = 400 * (days ~/ DAYS_IN_400_YEARS) - YEARS_OFFSET;
    days = days.remainder(DAYS_IN_400_YEARS);
    days--;
    int yd1 = days ~/ DAYS_IN_100_YEARS;
    days = days.remainder(DAYS_IN_100_YEARS);
    resultYear += 100 * yd1;
    days++;
    int yd2 = days ~/ DAYS_IN_4_YEARS;
    days = days.remainder(DAYS_IN_4_YEARS);
    resultYear += 4 * yd2;
    days--;
    int yd3 = days ~/ 365;
    days = days.remainder(365);
    resultYear += yd3;

    bool isLeap = (yd1 == 0 || yd2 != 0) && yd3 == 0;
    if (isLeap) days++;

    List<int> daysUntilMonth = _DAYS_UNTIL_MONTH[isLeap ? 1 : 0];
    for (resultMonth = 12;
         daysUntilMonth[resultMonth - 1] > days;
         resultMonth--) {
      // Do nothing.
    }
    resultDay = days - daysUntilMonth[resultMonth - 1] + 1;
    return <int>[resultYear, resultMonth, resultDay];
  }

  /**
   * Returns the amount of milliseconds in UTC that represent the same values
   * as [this].
   *
   * Say [:t:] is the result of this function, then
   * * [:this.year == new Date.fromMillisecondsSinceEpoch(t, true).year:],
   * * [:this.month == new Date.fromMillisecondsSinceEpoch(t, true).month:],
   * * [:this.day == new Date.fromMillisecondsSinceEpoch(t, true).day:],
   * * [:this.hour == new Date.fromMillisecondsSinceEpoch(t, true).hour:],
   * * ...
   *
   * Daylight savings is computed as if the date was computed in [1970..2037].
   * If [this] lies outside this range then it is a year with similar
   * properties (leap year, weekdays) is used instead.
   */
  int get _localDateInUtcMs() {
    int ms = millisecondsSinceEpoch;
    if (isUtc) return ms;
    int offset =
        _timeZoneOffsetInSeconds(ms) * Duration.MILLISECONDS_PER_SECOND;
    return ms + offset;
  }

  static int _flooredDivision(int a, int b) {
    return (a - (a < 0 ? b - 1 : 0)) ~/ b;
  }

  // Returns the days since 1970 for the start of the given [year].
  // [year] may be before epoch.
  static int _dayFromYear(int year) {
    return 365 * (year - 1970)
            + _flooredDivision(year - 1969, 4)
            - _flooredDivision(year - 1901, 100)
            + _flooredDivision(year - 1601, 400);
  }

  static bool _isLeapYear(y) {
    return (y.remainder(4) == 0) &&
        ((y.remainder(100) != 0) || (y.remainder(400) == 0));
  }

  static _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day,
      int hour, int minute, int second, int millisecond,
      bool isUtc) {
    // Simplify calculations by working with zero-based month.
    --month;
    // Deal with under and overflow.
    year += (month / 12).floor().toInt();
    month = month % 12;

    // First compute the seconds in UTC, independent of the [isUtc] flag. If
    // necessary we will add the time-zone offset later on.
    int days = day - 1;
    days += _DAYS_UNTIL_MONTH[_isLeapYear(year) ? 1 : 0][month];
    days += _dayFromYear(year);
    int millisecondsSinceEpoch = days * Duration.MILLISECONDS_PER_DAY +
        hour * Duration.MILLISECONDS_PER_HOUR +
        minute * Duration.MILLISECONDS_PER_MINUTE+
        second * Duration.MILLISECONDS_PER_SECOND +
        millisecond;

    // Since [_timeZoneOffsetInSeconds] will crash if the input is far out of
    // the valid range we do a preliminary test that weeds out values that can
    // not become valid even with timezone adjustments.
    // The timezone adjustment is always less than a day, so adding a security
    // margin of one day should be enough.
    if (millisecondsSinceEpoch.abs() >
        (_MAX_MILLISECONDS_SINCE_EPOCH + Duration.MILLISECONDS_PER_DAY)) {
      return null;
    }

    if (!isUtc) {
      // Note that we need to remove the local timezone adjustement before
      // asking for the correct zone offset.
      int adjustment = _localTimeZoneAdjustmentInSeconds() *
          Duration.MILLISECONDS_PER_SECOND;
      int zoneOffset =
          _timeZoneOffsetInSeconds(millisecondsSinceEpoch - adjustment);
      millisecondsSinceEpoch -= zoneOffset * Duration.MILLISECONDS_PER_SECOND;
    }
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
      return null;
    }
    return millisecondsSinceEpoch;
  }

  static int _weekDay(y) {
    // 1/1/1970 was a Thursday.
    return (_dayFromYear(y) + 4) % 7;
  }

  /**
   * Returns a year in the range 2008-2035 matching
   * * leap year, and
   * * week day of first day.
   *
   * Leap seconds are ignored.
   * Adapted from V8's date implementation. See ECMA 262 - 15.9.1.9.
   */
  static _equivalentYear(int year) {
    // Returns the week day (in range 0 - 6).
    // 1/1/1956 was a Sunday (i.e. weekday 0). 1956 was a leap-year.
    // 1/1/1967 was a Sunday (i.e. weekday 0).
    // Without leap years a subsequent year has a week day + 1 (for example
    // 1/1/1968 was a Monday). With leap-years it jumps over one week day
    // (e.g. 1/1/1957 was a Tuesday).
    // After 12 years the weekdays have advanced by 12 days + 3 leap days =
    // 15 days. 15 % 7 = 1. So after 12 years the week day has always
    // (now independently of leap-years) advanced by one.
    // weekDay * 12 gives thus a year starting with the wanted weekDay.
    int recentYear = (_isLeapYear(year) ? 1956 : 1967) + (_weekDay(year) * 12);
    // Close to the year 2008 the calendar cycles every 4 * 7 years (4 for the
    // leap years, 7 for the weekdays).
    // Find the year in the range 2008..2037 that is equivalent mod 28.
    return 2008 + (recentYear - 2008) % 28;
  }

  /**
   * Returns the UTC year for the corresponding [secondsSinceEpoch].
   * It is relatively fast for values in the range 0 to year 2098.
   *
   * Code is adapted from V8.
   */
  static int _yearsFromSecondsSinceEpoch(int secondsSinceEpoch) {
    final int DAYS_IN_4_YEARS = 4 * 365 + 1;
    final int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    final int DAYS_YEAR_2098 = DAYS_IN_100_YEARS + 6 * DAYS_IN_4_YEARS;

    int days = secondsSinceEpoch ~/ Duration.SECONDS_PER_DAY;
    if (days > 0 && days < DAYS_YEAR_2098) {
      // According to V8 this fast case works for dates from 1970 to 2099.
      return 1970 + (4 * days + 2) ~/ DAYS_IN_4_YEARS;
    }
    int ms = secondsSinceEpoch * Duration.MILLISECONDS_PER_SECOND;
    return _decomposeIntoYearMonthDay(ms)[0];
  }

  /**
   * Returns a date in seconds that is equivalent to the current date. An
   * equivalent date has the same fields ([:month:], [:day:], etc.) as the
   * [this], but the [:year:] is in the range [1970..2037].
   *
   * * The time since the beginning of the year is the same.
   * * If [this] is in a leap year then the returned seconds are in a leap
   *   year, too.
   * * The week day of [this] is the same as the one for the returned date.
   */
  static int _equivalentSeconds(int millisecondsSinceEpoch) {
    final int CUT_OFF_SECONDS = 2100000000;

    int secondsSinceEpoch = _flooredDivision(millisecondsSinceEpoch,
                                             Duration.MILLISECONDS_PER_SECOND);

    if (secondsSinceEpoch < 0 || secondsSinceEpoch >= CUT_OFF_SECONDS) {
      int year = _yearsFromSecondsSinceEpoch(secondsSinceEpoch);
      int days = _dayFromYear(year);
      int equivalentYear = _equivalentYear(year);
      int equivalentDays = _dayFromYear(equivalentYear);
      int diffDays = equivalentDays - days;
      secondsSinceEpoch += diffDays * Duration.SECONDS_PER_DAY;
    }
    return secondsSinceEpoch;
  }

  static int _timeZoneOffsetInSeconds(int millisecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(millisecondsSinceEpoch);
    return _timeZoneOffsetInSecondsForClampedSeconds(equivalentSeconds);
  }

  static String _timeZoneName(int millisecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(millisecondsSinceEpoch);
    return _timeZoneNameForClampedSeconds(equivalentSeconds);
  }

  // Natives
  static int _getCurrentMs() native "DateNatives_currentTimeMillis";

  static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch)
      native "DateNatives_timeZoneName";

  static int _timeZoneOffsetInSecondsForClampedSeconds(int secondsSinceEpoch)
      native "DateNatives_timeZoneOffsetInSeconds";

  static int _localTimeZoneAdjustmentInSeconds()
      native "DateNatives_localTimeZoneAdjustmentInSeconds";
}
