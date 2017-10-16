// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// VM implementation of DateTime.
@patch
class DateTime {
  // Natives.
  // The natives have been moved up here to work around Issue 10401.
  static int _getCurrentMicros() native "DateTime_currentTimeMicros";

  static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch)
      native "DateTime_timeZoneName";

  static int _timeZoneOffsetInSecondsForClampedSeconds(int secondsSinceEpoch)
      native "DateTime_timeZoneOffsetInSeconds";

  static int _localTimeZoneAdjustmentInSeconds()
      native "DateTime_localTimeZoneAdjustmentInSeconds";

  static const _MICROSECOND_INDEX = 0;
  static const _MILLISECOND_INDEX = 1;
  static const _SECOND_INDEX = 2;
  static const _MINUTE_INDEX = 3;
  static const _HOUR_INDEX = 4;
  static const _DAY_INDEX = 5;
  static const _WEEKDAY_INDEX = 6;
  static const _MONTH_INDEX = 7;
  static const _YEAR_INDEX = 8;

  List __parts;

  @patch
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc: false})
      : this._withValue(
            millisecondsSinceEpoch * Duration.MICROSECONDS_PER_MILLISECOND,
            isUtc: isUtc);

  @patch
  DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc: false})
      : this._withValue(microsecondsSinceEpoch, isUtc: isUtc);

  @patch
  DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, int microsecond, bool isUtc)
      : this.isUtc = isUtc,
        this._value = _brokenDownDateToValue(year, month, day, hour, minute,
            second, millisecond, microsecond, isUtc) {
    if (_value == null) throw new ArgumentError();
    if (isUtc == null) throw new ArgumentError();
  }

  @patch
  DateTime._now()
      : isUtc = false,
        _value = _getCurrentMicros() {}

  @patch
  String get timeZoneName {
    if (isUtc) return "UTC";
    return _timeZoneName(microsecondsSinceEpoch);
  }

  @patch
  Duration get timeZoneOffset {
    if (isUtc) return new Duration();
    int offsetInSeconds = _timeZoneOffsetInSeconds(microsecondsSinceEpoch);
    return new Duration(seconds: offsetInSeconds);
  }

  /** The first list contains the days until each month in non-leap years. The
    * second list contains the days in leap years. */
  static const List<List<int>> _DAYS_UNTIL_MONTH = const [
    const [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334],
    const [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
  ];

  static List _computeUpperPart(int localMicros) {
    const int DAYS_IN_4_YEARS = 4 * 365 + 1;
    const int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    const int DAYS_IN_400_YEARS = 4 * DAYS_IN_100_YEARS + 1;
    const int DAYS_1970_TO_2000 = 30 * 365 + 7;
    const int DAYS_OFFSET =
        1000 * DAYS_IN_400_YEARS + 5 * DAYS_IN_400_YEARS - DAYS_1970_TO_2000;
    const int YEARS_OFFSET = 400000;

    int resultYear = 0;
    int resultMonth = 0;
    int resultDay = 0;

    // Always round down.
    final int daysSince1970 =
        _flooredDivision(localMicros, Duration.MICROSECONDS_PER_DAY);
    int days = daysSince1970;
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

    int resultMicrosecond = localMicros % Duration.MICROSECONDS_PER_MILLISECOND;
    int resultMillisecond =
        _flooredDivision(localMicros, Duration.MICROSECONDS_PER_MILLISECOND) %
            Duration.MILLISECONDS_PER_SECOND;
    int resultSecond =
        _flooredDivision(localMicros, Duration.MICROSECONDS_PER_SECOND) %
            Duration.SECONDS_PER_MINUTE;

    int resultMinute =
        _flooredDivision(localMicros, Duration.MICROSECONDS_PER_MINUTE);
    resultMinute %= Duration.MINUTES_PER_HOUR;

    int resultHour =
        _flooredDivision(localMicros, Duration.MICROSECONDS_PER_HOUR);
    resultHour %= Duration.HOURS_PER_DAY;

    // In accordance with ISO 8601 a week
    // starts with Monday. Monday has the value 1 up to Sunday with 7.
    // 1970-1-1 was a Thursday.
    int resultWeekday = ((daysSince1970 + DateTime.THURSDAY - DateTime.MONDAY) %
            DateTime.DAYS_PER_WEEK) +
        DateTime.MONDAY;

    List list = new List(_YEAR_INDEX + 1);
    list[_MICROSECOND_INDEX] = resultMicrosecond;
    list[_MILLISECOND_INDEX] = resultMillisecond;
    list[_SECOND_INDEX] = resultSecond;
    list[_MINUTE_INDEX] = resultMinute;
    list[_HOUR_INDEX] = resultHour;
    list[_DAY_INDEX] = resultDay;
    list[_WEEKDAY_INDEX] = resultWeekday;
    list[_MONTH_INDEX] = resultMonth;
    list[_YEAR_INDEX] = resultYear;
    return list;
  }

  get _parts {
    if (__parts == null) {
      __parts = _computeUpperPart(_localDateInUtcMicros);
    }
    return __parts;
  }

  @patch
  DateTime add(Duration duration) {
    return new DateTime._withValue(_value + duration.inMicroseconds,
        isUtc: isUtc);
  }

  @patch
  DateTime subtract(Duration duration) {
    return new DateTime._withValue(_value - duration.inMicroseconds,
        isUtc: isUtc);
  }

  @patch
  Duration difference(DateTime other) {
    return new Duration(microseconds: _value - other._value);
  }

  @patch
  int get millisecondsSinceEpoch =>
      _value ~/ Duration.MICROSECONDS_PER_MILLISECOND;

  @patch
  int get microsecondsSinceEpoch => _value;

  @patch
  int get microsecond => _parts[_MICROSECOND_INDEX];

  @patch
  int get millisecond => _parts[_MILLISECOND_INDEX];

  @patch
  int get second => _parts[_SECOND_INDEX];

  @patch
  int get minute => _parts[_MINUTE_INDEX];

  @patch
  int get hour => _parts[_HOUR_INDEX];

  @patch
  int get day => _parts[_DAY_INDEX];

  @patch
  int get weekday => _parts[_WEEKDAY_INDEX];

  @patch
  int get month => _parts[_MONTH_INDEX];

  @patch
  int get year => _parts[_YEAR_INDEX];

  /**
   * Returns the amount of microseconds in UTC that represent the same values
   * as [this].
   *
   * Say `t` is the result of this function, then
   * * `this.year == new DateTime.fromMicrosecondsSinceEpoch(t, true).year`,
   * * `this.month == new DateTime.fromMicrosecondsSinceEpoch(t, true).month`,
   * * `this.day == new DateTime.fromMicrosecondsSinceEpoch(t, true).day`,
   * * `this.hour == new DateTime.fromMicrosecondsSinceEpoch(t, true).hour`,
   * * ...
   *
   * Daylight savings is computed as if the date was computed in [1970..2037].
   * If [this] lies outside this range then it is a year with similar
   * properties (leap year, weekdays) is used instead.
   */
  int get _localDateInUtcMicros {
    int micros = _value;
    if (isUtc) return micros;
    int offset =
        _timeZoneOffsetInSeconds(micros) * Duration.MICROSECONDS_PER_SECOND;
    return micros + offset;
  }

  static int _flooredDivision(int a, int b) {
    return (a - (a < 0 ? b - 1 : 0)) ~/ b;
  }

  // Returns the days since 1970 for the start of the given [year].
  // [year] may be before epoch.
  static int _dayFromYear(int year) {
    return 365 * (year - 1970) +
        _flooredDivision(year - 1969, 4) -
        _flooredDivision(year - 1901, 100) +
        _flooredDivision(year - 1601, 400);
  }

  static bool _isLeapYear(y) {
    // (y % 16 == 0) matches multiples of 400, and is faster than % 400.
    return (y % 4 == 0) && ((y % 16 == 0) || (y % 100 != 0));
  }

  /// Converts the given broken down date to microseconds.
  @patch
  static int _brokenDownDateToValue(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond, bool isUtc) {
    // Simplify calculations by working with zero-based month.
    --month;
    // Deal with under and overflow.
    if (month >= 12) {
      year += month ~/ 12;
      month = month % 12;
    } else if (month < 0) {
      int realMonth = month % 12;
      year += (month - realMonth) ~/ 12;
      month = realMonth;
    }

    // First compute the seconds in UTC, independent of the [isUtc] flag. If
    // necessary we will add the time-zone offset later on.
    int days = day - 1;
    days += _DAYS_UNTIL_MONTH[_isLeapYear(year) ? 1 : 0][month];
    days += _dayFromYear(year);
    int microsecondsSinceEpoch = days * Duration.MICROSECONDS_PER_DAY +
        hour * Duration.MICROSECONDS_PER_HOUR +
        minute * Duration.MICROSECONDS_PER_MINUTE +
        second * Duration.MICROSECONDS_PER_SECOND +
        millisecond * Duration.MICROSECONDS_PER_MILLISECOND +
        microsecond;

    // Since [_timeZoneOffsetInSeconds] will crash if the input is far out of
    // the valid range we do a preliminary test that weeds out values that can
    // not become valid even with timezone adjustments.
    // The timezone adjustment is always less than a day, so adding a security
    // margin of one day should be enough.
    if (microsecondsSinceEpoch.abs() >
        _MAX_MILLISECONDS_SINCE_EPOCH * 1000 + Duration.MICROSECONDS_PER_DAY) {
      return null;
    }

    if (!isUtc) {
      // Note that we need to remove the local timezone adjustment before
      // asking for the correct zone offset.
      int adjustment = _localTimeZoneAdjustmentInSeconds() *
          Duration.MICROSECONDS_PER_SECOND;
      // The adjustment is independent of the actual date and of the daylight
      // saving time. It is positive east of the Prime Meridian and negative
      // west of it, e.g. -28800 sec for America/Los_Angeles timezone.

      int zoneOffset =
          _timeZoneOffsetInSeconds(microsecondsSinceEpoch - adjustment);
      // The zoneOffset depends on the actual date and reflects any daylight
      // saving time and/or historical deviation relative to UTC time.
      // It is positive east of the Prime Meridian and negative west of it,
      // e.g. -25200 sec for America/Los_Angeles timezone during DST.
      microsecondsSinceEpoch -= zoneOffset * Duration.MICROSECONDS_PER_SECOND;
      // The resulting microsecondsSinceEpoch value is therefore the calculated
      // UTC value decreased by a (positive if east of GMT) timezone adjustment
      // and decreased by typically one hour if DST is in effect.
    }
    if (microsecondsSinceEpoch.abs() >
        _MAX_MILLISECONDS_SINCE_EPOCH * Duration.MICROSECONDS_PER_MILLISECOND) {
      return null;
    }
    return microsecondsSinceEpoch;
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
  static int _equivalentYear(int year) {
    // Returns year y so that _weekDay(y) == _weekDay(year).
    // _weekDay returns the week day (in range 0 - 6).
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
    const int DAYS_IN_4_YEARS = 4 * 365 + 1;
    const int DAYS_IN_100_YEARS = 25 * DAYS_IN_4_YEARS - 1;
    const int DAYS_YEAR_2098 = DAYS_IN_100_YEARS + 6 * DAYS_IN_4_YEARS;

    int days = secondsSinceEpoch ~/ Duration.SECONDS_PER_DAY;
    if (days > 0 && days < DAYS_YEAR_2098) {
      // According to V8 this fast case works for dates from 1970 to 2099.
      return 1970 + (4 * days + 2) ~/ DAYS_IN_4_YEARS;
    }
    int micros = secondsSinceEpoch * Duration.MICROSECONDS_PER_SECOND;
    return _computeUpperPart(micros)[_YEAR_INDEX];
  }

  /**
   * Returns a date in seconds that is equivalent to the given
   * date in microseconds [microsecondsSinceEpoch]. An equivalent
   * date has the same fields (`month`, `day`, etc.) as the given
   * date, but the `year` is in the range [1901..2038].
   *
   * * The time since the beginning of the year is the same.
   * * If the given date is in a leap year then the returned
   *   seconds are in a leap year, too.
   * * The week day of given date is the same as the one for the
   *   returned date.
   */
  static int _equivalentSeconds(int microsecondsSinceEpoch) {
    const int CUT_OFF_SECONDS = 0x7FFFFFFF;

    int secondsSinceEpoch = _flooredDivision(
        microsecondsSinceEpoch, Duration.MICROSECONDS_PER_SECOND);

    if (secondsSinceEpoch.abs() > CUT_OFF_SECONDS) {
      int year = _yearsFromSecondsSinceEpoch(secondsSinceEpoch);
      int days = _dayFromYear(year);
      int equivalentYear = _equivalentYear(year);
      int equivalentDays = _dayFromYear(equivalentYear);
      int diffDays = equivalentDays - days;
      secondsSinceEpoch += diffDays * Duration.SECONDS_PER_DAY;
    }
    return secondsSinceEpoch;
  }

  static int _timeZoneOffsetInSeconds(int microsecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(microsecondsSinceEpoch);
    return _timeZoneOffsetInSecondsForClampedSeconds(equivalentSeconds);
  }

  static String _timeZoneName(int microsecondsSinceEpoch) {
    int equivalentSeconds = _equivalentSeconds(microsecondsSinceEpoch);
    return _timeZoneNameForClampedSeconds(equivalentSeconds);
  }
}
