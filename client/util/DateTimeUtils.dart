// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * General purpose date/time utilities.
 */
class DateTimeUtils {
  // TODO(jmesserly): localized strings
  static final WEEKDAYS = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                                 'Friday', 'Saturday', 'Sunday'];

  static final YESTERDAY = 'Yesterday';

  static final MS_IN_WEEK = Date.DAYS_IN_WEEK * Time.MS_PER_DAY;

  // TODO(jmesserly): workaround for missing DateTime.fromDate in Dartium
  // Remove this once that is implemented. See b/5055106
  // Parse a string like: "Mon, 27 Jun 2011 15:22:00 -0700"
  static DateTime fromString(String text) {
    final parts = text.split(' ');
    if (parts.length == 1) {
      return _parseIsoDateTime(text);
    }

    if (parts.length != 6) {
      throw 'bad date format, expected 6 parts: ' + text;
    }

    // skip parts[0], the weekday

    int day = Math.parseInt(parts[1]);

    final months = const['Jan', 'Feb', 'Mar', 'Apr',
                         'May', 'Jun', 'Jul', 'Aug',
                         'Sep', 'Oct', 'Nov', 'Dec'];
    int month = months.indexOf(parts[2], 0) + 1;
    if (month < 0) {
      throw 'bad month, expected 3 letter month code, got: ' + parts[2];
    }

    int year = Math.parseInt(parts[3]);

    final timeParts = parts[4].split(':');
    if (timeParts.length != 3) {
      throw 'bad time format, expected 3 parts: ' + parts[4];
    }

    int hours = Math.parseInt(timeParts[0]);
    int minutes = Math.parseInt(timeParts[1]);
    int seconds = Math.parseInt(timeParts[2]);

    // TODO(jmesserly): TimeZone is not implemented in Dartium. This ugly
    // hack applies the timezone from the string to the final time
    int zoneOffset = Math.parseInt(parts[5]) ~/ 100;

    // Pretend it's a UTC time
    DateTime result = new DateTime.withTimeZone(
        year, month, day, hours, minutes, seconds, 0, new TimeZone.utc());
    // Shift it to the proper zone, but it's still a UTC time
    result = result.subtract(new Time(0, zoneOffset, 0, 0, 0));
    // Then render it as a local time
    return result.changeTimeZone(new TimeZone.local());
  }

  /** Parse a string like: 2011-07-19T22:03:04.000Z */
  // TODO(jmesserly): workaround for DateTime.fromDate, which has issues:
  //   * on Dart VM it doesn't handle all of ISO 8601. See b/5055106.
  //   * on DartC it doesn't work on Safari. See b/5062557.
  // Remove this once that function is fully implemented
  static DateTime _parseIsoDateTime(String text) {
    void ensure(bool value) {
      if (!value) {
        throw 'bad date format, expected YYYY-MM-DDTHH:MM:SS.mmmZ: ' + text;
      }
    }

    TimeZone zone;
    if (text.endsWith('Z')) {
      text = text.substring(0, text.length - 1);
      zone = new TimeZone.utc();
    } else {
      zone = new TimeZone.local();
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
      milliseconds = Math.parseInt(seconds[1]);
    }

    return new DateTime.withTimeZone(
        Math.parseInt(date[0]),
        Math.parseInt(date[1]),
        Math.parseInt(date[2]),
        Math.parseInt(time[0]),
        Math.parseInt(time[1]),
        Math.parseInt(seconds[0]),
        milliseconds,
        zone);
  }

  /**
   * A date/time formatter that takes into account the current date/time:
   *  - if it's from today, just show the time
   *  - if it's from yesterday, just show 'Yesterday'
   *  - if it's from the same week, just show the weekday
   *  - otherwise, show just the date
   */
  static String toRecentTimeString(DateTime then) {
    final now = new DateTime.now();
    if (then.date == now.date) {
      return toHourMinutesString(then.time);
    }

    final today = new DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    Time delta = today.difference(then);
    if (delta.duration < Time.MS_PER_DAY) {
      return YESTERDAY;
    } else if (delta.duration < MS_IN_WEEK) {
      return WEEKDAYS[getWeekday(then)];
    } else {
      // TODO(jmesserly): locale specific date format
      return then.date.toString();
    }
  }

  // TODO(jmesserly): this is a workaround for unimplemented DateTime.weekday
  // Code inspired by v8/src/date.js
  static int getWeekday(DateTime dateTime) {
    final unixTimeStart = new DateTime(1970, 1, 1, 0, 0, 0, 0);
    int msSince1970 = dateTime.difference(unixTimeStart).duration;
    int daysSince1970 = msSince1970 ~/ Time.MS_PER_DAY;
    // 1970-1-1 was Thursday
    return ((daysSince1970 + Date.THU) % Date.DAYS_IN_WEEK);
  }

  /** Formats a time in H:MM A format */
  // TODO(jmesserly): should get 12 vs 24 hour clock setting from the locale
  static String toHourMinutesString(Time time) {
    int hours = time.hours;
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
    String mm = twoDigits(time.minutes);
    return "${hours}:${mm} ${a}";
  }
}
