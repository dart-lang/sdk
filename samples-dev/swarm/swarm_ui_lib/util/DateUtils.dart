// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utilslib;

/**
 * General purpose date/time utilities.
 */
class DateUtils {
  // TODO(jmesserly): localized strings
  static const WEEKDAYS = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  static const YESTERDAY = 'Yesterday';

  static const MS_IN_WEEK =
      DateTime.DAYS_PER_WEEK * Duration.MILLISECONDS_PER_DAY;

  // TODO(jmesserly): workaround for missing DateTime.fromDate in Dartium
  // Remove this once that is implemented. See b/5055106
  // Parse a string like: "Mon, 27 Jun 2011 15:22:00 -0700"
  static DateTime fromString(String text) {
    final parts = text.split(' ');
    if (parts.length == 1) {
      return _parseIsoDate(text);
    }

    if (parts.length != 6) {
      throw 'bad date format, expected 6 parts: $text';
    }

    // skip parts[0], the weekday

    int day = int.parse(parts[1]);

    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    int month = months.indexOf(parts[2], 0) + 1;
    if (month < 0) {
      throw 'bad month, expected 3 letter month code, got: ${parts[2]}';
    }

    int year = int.parse(parts[3]);

    final timeParts = parts[4].split(':');
    if (timeParts.length != 3) {
      throw 'bad time format, expected 3 parts: ${parts[4]}';
    }

    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    int seconds = int.parse(timeParts[2]);

    // TODO(jmesserly): TimeZone is not implemented in Dartium. This ugly
    // hack applies the timezone from the string to the final time
    int zoneOffset = int.parse(parts[5]) ~/ 100;

    // Pretend it's a UTC time
    DateTime result =
        new DateTime.utc(year, month, day, hours, minutes, seconds, 0);
    // Shift it to the proper zone, but it's still a UTC time
    result = result.subtract(new Duration(hours: zoneOffset));
    // Then render it as a local time
    return result.toLocal();
  }

  /** Parse a string like: 2011-07-19T22:03:04.000Z */
  // TODO(jmesserly): workaround for DateTime.fromDate, which has issues:
  //   * on Dart VM it doesn't handle all of ISO 8601. See b/5055106.
  //   * on DartC it doesn't work on Safari. See b/5062557.
  // Remove this once that function is fully implemented
  static DateTime _parseIsoDate(String text) {
    void ensure(bool value) {
      if (!value) {
        throw 'bad date format, expected YYYY-MM-DDTHH:MM:SS.mmmZ: $text';
      }
    }

    bool isUtc = text.endsWith('Z');
    if (isUtc) {
      text = text.substring(0, text.length - 1);
    }

    final parts = text.split('T');
    ensure(parts.length == 2);

    final date = parts[0].split('-');
    ensure(date.length == 3);

    final time = parts[1].split(':');
    ensure(time.length == 3);

    final seconds = time[2].split('.');
    ensure(seconds.length >= 1 && seconds.length <= 2);
    int milliseconds = 0;
    if (seconds.length == 2) {
      milliseconds = int.parse(seconds[1]);
    }

    return new DateTime(
        int.parse(date[0]),
        int.parse(date[1]),
        int.parse(date[2]),
        int.parse(time[0]),
        int.parse(time[1]),
        int.parse(seconds[0]),
        milliseconds);
  }

  /**
   * A date/time formatter that takes into account the current date/time:
   *  - if it's from today, just show the time
   *  - if it's from yesterday, just show 'Yesterday'
   *  - if it's from the same week, just show the weekday
   *  - otherwise, show just the date
   */
  static String toRecentTimeString(DateTime then) {
    bool datesAreEqual(DateTime d1, DateTime d2) {
      return (d1.year == d2.year) &&
          (d1.month == d2.month) &&
          (d1.day == d2.day);
    }

    final now = new DateTime.now();
    if (datesAreEqual(then, now)) {
      return toHourMinutesString(new Duration(
          days: 0,
          hours: then.hour,
          minutes: then.minute,
          seconds: then.second,
          milliseconds: then.millisecond));
    }

    final today = new DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    Duration delta = today.difference(then);
    if (delta.inMilliseconds < Duration.MILLISECONDS_PER_DAY) {
      return YESTERDAY;
    } else if (delta.inMilliseconds < MS_IN_WEEK) {
      return WEEKDAYS[getWeekday(then)];
    } else {
      // TODO(jmesserly): locale specific date format
      String twoDigits(int n) {
        if (n >= 10) return "${n}";
        return "0${n}";
      }

      String twoDigitMonth = twoDigits(then.month);
      String twoDigitDay = twoDigits(then.day);
      return "${then.year}-${twoDigitMonth}-${twoDigitDay}";
    }
  }

  // TODO(jmesserly): this is a workaround for unimplemented DateTime.weekday
  // Code inspired by v8/src/date.js
  static int getWeekday(DateTime dateTime) {
    final unixTimeStart = new DateTime(1970, 1, 1, 0, 0, 0, 0);
    int msSince1970 = dateTime.difference(unixTimeStart).inMilliseconds;
    int daysSince1970 = msSince1970 ~/ Duration.MILLISECONDS_PER_DAY;
    // 1970-1-1 was Thursday
    return ((daysSince1970 + DateTime.THURSDAY) % DateTime.DAYS_PER_WEEK);
  }

  /** Formats a time in H:MM A format */
  // TODO(jmesserly): should get 12 vs 24 hour clock setting from the locale
  static String toHourMinutesString(Duration duration) {
    assert(duration.inDays == 0);
    int hours = duration.inHours;
    String a;
    if (hours >= 12) {
      a = 'pm';
      if (hours != 12) {
        hours -= 12;
      }
    } else {
      a = 'am';
      if (hours == 0) {
        hours += 12;
      }
    }
    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String mm =
        twoDigits(duration.inMinutes.remainder(Duration.MINUTES_PER_HOUR));
    return "${hours}:${mm} ${a}";
  }
}
