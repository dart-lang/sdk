// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for DateTime.

class DateTimeTest {
  // Tests if the time moves eventually forward.
  static void testNow() {
    var t1 = new DateTime.now();
    bool timeMovedForward = false;
    for (int i = 0; i < 1000000; i++) {
      var t2 = new DateTime.now();
      if (t1.value < t2.value) {
        timeMovedForward = true;
        break;
      }
    }
    Expect.equals(true, timeMovedForward);
  }

  static void testValue() {
    var dt1 = new DateTime.now();
    var value = dt1.value;
    var dt2 = new DateTime.fromEpoch(value, new TimeZone.local());
    Expect.equals(value, dt2.value);
  }

  static void testFarAwayDates() {
    DateTime dt =
        new DateTime.fromEpoch(1000000000000001, const TimeZone.utc());
    Expect.equals(33658, dt.year);
    Expect.equals(9, dt.month);
    Expect.equals(27, dt.day);
    Expect.equals(1, dt.hours);
    Expect.equals(46, dt.minutes);
    Expect.equals(40, dt.seconds);
    Expect.equals(1, dt.milliseconds);
    Date d = dt.date;
    Expect.equals(33658, d.year);
    Expect.equals(9, d.month);
    Expect.equals(27, d.day);
    Time t = dt.time;
    Expect.equals(1, t.hours);
    Expect.equals(46, t.minutes);
    Expect.equals(40, t.seconds);
    Expect.equals(1, t.milliseconds);
    dt = new DateTime.fromEpoch(-1000000000000001, const TimeZone.utc());
    Expect.equals(-29719, dt.year);
    Expect.equals(4, dt.month);
    Expect.equals(5, dt.day);
    Expect.equals(22, dt.hours);
    Expect.equals(13, dt.minutes);
    Expect.equals(19, dt.seconds);
    Expect.equals(999, dt.milliseconds);
    d = dt.date;
    Expect.equals(-29719, d.year);
    Expect.equals(4, d.month);
    Expect.equals(5, d.day);
    t = dt.time;
    Expect.equals(22, t.hours);
    Expect.equals(13, t.minutes);
    Expect.equals(19, t.seconds);
    Expect.equals(999, t.milliseconds);
    // Same with local zone.
    dt = new DateTime.fromEpoch(1000000000000001, new TimeZone.local());
    Expect.equals(33658, dt.year);
    Expect.equals(9, dt.month);
    Expect.equals(true, dt.day == 27 || dt.day == 26);
    // Not much we can test for local hours.
    Expect.equals(true, dt.hours >= 0 && dt.hours < 24);
    // Timezones can have offsets down to 15 minutes.
    Expect.equals(true, dt.minutes % 15 == 46 % 15);
    Expect.equals(40, dt.seconds);
    Expect.equals(1, dt.milliseconds);
    dt = new DateTime.fromEpoch(-1000000000000001, new TimeZone.local());
    Expect.equals(-29719, dt.year);
    Expect.equals(4, dt.month);
    Expect.equals(true, 5 == dt.day || 6 == dt.day);
    // Not much we can test for local hours.
    Expect.equals(true, dt.hours >= 0 && dt.hours < 24);
    // Timezones can have offsets down to 15 minutes.
    Expect.equals(true, dt.minutes % 15 == 13);
    Expect.equals(19, dt.seconds);
    Expect.equals(999, dt.milliseconds);
  }

  static void testEquivalentYears() {
    // All hardcoded values come from V8. This means that the values are not
    // necessarily correct (see limitations of Date object in
    // EcmaScript 15.9.1 and in particular 15.9.1.8/9).
    DateTime dt = new DateTime.fromEpoch(-31485600000, const TimeZone.utc());
    Expect.equals(1969, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-63108000000, const TimeZone.utc());
    Expect.equals(1968, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-94644000000, const TimeZone.utc());
    Expect.equals(1967, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-126180000000, const TimeZone.utc());
    Expect.equals(1966, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-157716000000, const TimeZone.utc());
    Expect.equals(1965, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-2177402400000, const TimeZone.utc());
    Expect.equals(1901, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-5333076000000, const TimeZone.utc());
    Expect.equals(1801, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-8520285600000, const TimeZone.utc());
    Expect.equals(1700, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-14831719200000, const TimeZone.utc());
    Expect.equals(1500, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-59011408800000, const TimeZone.utc());
    Expect.equals(100, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-62011408800000, const TimeZone.utc());
    Expect.equals(4, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(8, dt.day);
    Expect.equals(8, dt.hours);
    Expect.equals(40, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    dt = new DateTime.fromEpoch(-64011408800000, const TimeZone.utc());
    Expect.equals(-59, dt.year);
    Expect.equals(7, dt.month);
    Expect.equals(24, dt.day);
    Expect.equals(5, dt.hours);
    Expect.equals(6, dt.minutes);
    Expect.equals(40, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    final int SECONDS_YEAR_2035 = 2051222400;
    dt = new DateTime.fromEpoch(SECONDS_YEAR_2035 * 1000 + 1,
                                const TimeZone.utc());
    Expect.equals(2035, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(0, dt.hours);
    Expect.equals(0, dt.minutes);
    Expect.equals(0, dt.seconds);
    Expect.equals(1, dt.milliseconds);
    dt = new DateTime.fromEpoch(SECONDS_YEAR_2035 * 1000 - 1,
                                const TimeZone.utc());
    Expect.equals(2034, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(31, dt.day);
    Expect.equals(23, dt.hours);
    Expect.equals(59, dt.minutes);
    Expect.equals(59, dt.seconds);
    Expect.equals(999, dt.milliseconds);
    dt = new DateTime.withTimeZone(2035, 1, 1, 0, 0, 0, 1,
                                   const TimeZone.utc());
    Expect.equals(SECONDS_YEAR_2035 * 1000 + 1, dt.value);
    dt = new DateTime.withTimeZone(2034, 12, 31, 23, 59, 59, 999,
                                   const TimeZone.utc());
    Expect.equals(SECONDS_YEAR_2035 * 1000 - 1, dt.value);
    dt = new DateTime.fromEpoch(SECONDS_YEAR_2035 * 1000 + 1,
                                new TimeZone.local());
    Expect.equals(true, (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
                        (2034 == dt.year && 12 == dt.month && 31 == dt.day));
    Expect.equals(0, dt.seconds);
    Expect.equals(1, dt.milliseconds);
    DateTime dt2 = new DateTime.fromDateAndTime(dt.date, dt.time,
                                                new TimeZone.local());
    Expect.equals(dt.value, dt2.value);
    dt = new DateTime.fromEpoch(SECONDS_YEAR_2035 * 1000 - 1,
                                new TimeZone.local());
    Expect.equals(true, (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
                        (2034 == dt.year && 12 == dt.month && 31 == dt.day));
    Expect.equals(59, dt.seconds);
    Expect.equals(999, dt.milliseconds);
    dt2 = new DateTime.fromDateAndTime(dt.date, dt.time, new TimeZone.local());
    Expect.equals(dt.value, dt2.value);
  }

  static void testUTCGetters() {
    var dt = new DateTime.fromEpoch(1305140315000, const TimeZone.utc());
    Expect.equals(2011, dt.year);
    Expect.equals(5, dt.month);
    Expect.equals(11, dt.day);
    Expect.equals(18, dt.hours);
    Expect.equals(58, dt.minutes);
    Expect.equals(35, dt.seconds);
    Expect.equals(0, dt.milliseconds);
    Expect.equals(true, const TimeZone.utc() == dt.timeZone);
    Expect.equals(1305140315000, dt.value);
    Date d = dt.date;
    Expect.equals(2011, d.year);
    Expect.equals(5, d.month);
    Expect.equals(11, d.day);
    Time t = dt.time;
    Expect.equals(0, t.days);
    Expect.equals(18, t.hours);
    Expect.equals(58, t.minutes);
    Expect.equals(35, t.seconds);
    Expect.equals(0, t.milliseconds);
    dt = new DateTime.fromEpoch(-9999999, const TimeZone.utc());
    Expect.equals(1969, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(31, dt.day);
    Expect.equals(21, dt.hours);
    Expect.equals(13, dt.minutes);
    Expect.equals(20, dt.seconds);
    Expect.equals(1, dt.milliseconds);
    d = dt.date;
    Expect.equals(1969, d.year);
    Expect.equals(12, d.month);
    Expect.equals(31, d.day);
    t = dt.time;
    Expect.equals(21, t.hours);
    Expect.equals(13, t.minutes);
    Expect.equals(20, t.seconds);
    Expect.equals(1, t.milliseconds);
  }

  static void testLocalGetters() {
    var dt1 = new DateTime.fromEpoch(1305140315000, new TimeZone.local());
    var dt2 =
        new DateTime.withTimeZone(dt1.year, dt1.month, dt1.day,
                                  dt1.hours, dt1.minutes, dt1.seconds,
                                  dt1.milliseconds,
                                  const TimeZone.utc());
    Time zoneOffset = dt1.difference(dt2);
    Expect.equals(true, zoneOffset.days == 0);
    Expect.equals(true, zoneOffset.hours.abs() <= 12);
    Expect.equals(dt1.year, dt2.year);
    Expect.equals(dt1.month, dt2.month);
    Expect.equals(true, (dt1.day - dt2.day).abs() <= 1);
    Expect.equals(true, dt1.hours < 24);
    // There are timezones with 0.5 or 0.25 hour offsets.
    Expect.equals(true,
                  (dt1.minutes == dt2.minutes) ||
                  ((dt1.minutes - dt2.minutes).abs() == 30) ||
                  ((dt1.minutes - dt2.minutes).abs() == 15));
    Expect.equals(dt1.seconds, dt2.seconds);
    Expect.equals(dt1.milliseconds, dt2.milliseconds);
  }

  static void testConstructors() {
    var dt1 = new DateTime.fromEpoch(1305140315000, new TimeZone.local());
    Date d = dt1.date;
    Time t = dt1.time;
    var dt3 = new DateTime.fromDateAndTime(d, t, null);
    Expect.equals(dt1.value, dt3.value);
    Expect.equals(true, dt1 == dt3);
    dt3 = new DateTime.fromDateAndTime(d, t, new TimeZone.local());
    Expect.equals(dt1.value, dt3.value);
    Expect.equals(true, dt1 == dt3);
    dt3 = new DateTime.withTimeZone(2011, 5, 11, 18, 58, 35, 0,
                                    const TimeZone.utc());
    Expect.equals(dt1.value, dt3.value);
    Expect.equals(false, dt1 == dt3);
    var dt2 = dt1.changeTimeZone(new TimeZone.local());
    dt3 = new DateTime.withTimeZone(2011, 5, dt1.day,
                                    dt1.hours, dt1.minutes, 35, 0,
                                    new TimeZone.local());
    Expect.equals(dt2.value, dt3.value);
    Expect.equals(true, dt2 == dt3);
    dt1 = new DateTime.fromEpoch(-9999999, const TimeZone.utc());
    d = dt1.date;
    t = dt1.time;
    dt3 = new DateTime.fromDateAndTime(d, t, const TimeZone.utc());
    Expect.equals(dt1.value, dt3.value);
  }

  static void testChangeTimeZone() {
    var dt1 = new DateTime.fromEpoch(1305140315000, new TimeZone.local());
    var dt2 = dt1.changeTimeZone(const TimeZone.utc());
    Expect.equals(dt1.value, dt2.value);
    var dt3 = new DateTime.fromEpoch(1305140315000, const TimeZone.utc());
    Expect.equals(dt1.value, dt3.value);
    Expect.equals(true, dt2.date == dt3.date);
    Expect.equals(true, dt2.time == dt3.time);
    var dt4 = dt3.changeTimeZone(new TimeZone.local());
    Expect.equals(true, dt1.date == dt4.date);
    Expect.equals(true, dt1.time == dt4.time);
  }

  static void testSubAdd() {
    var dt1 = new DateTime.fromEpoch(1305140315000, const TimeZone.utc());
    var dt2 = dt1.add(const Time.duration(3 * Time.MS_PER_SECOND + 5));
    Expect.equals(true, dt1.date == dt2.date);
    Expect.equals(dt1.hours, dt2.hours);
    Expect.equals(dt1.minutes, dt2.minutes);
    Expect.equals(dt1.seconds + 3, dt2.seconds);
    Expect.equals(dt1.milliseconds + 5, dt2.milliseconds);
    var dt3 = dt2.subtract(const Time.duration(3 * Time.MS_PER_SECOND + 5));
    Expect.equals(true, dt1 == dt3);
    Expect.equals(false, dt1 == dt2);
  }

  static void testDateStrings() {
    // TODO(floitsch): Clean up the DateTime API that deals with strings.
    var dt1 = new DateTime.fromString("2011-05-11 18:58:35Z");
    Expect.equals(1305140315000, dt1.value);
    var str = dt1.toString();
    var dt2 = new DateTime.fromString(str);
    Expect.equals(true, dt1 == dt2);
    var dt3 = dt1.changeTimeZone(const TimeZone.utc());
    str = dt3.toString();
    Expect.equals("2011-05-11 18:58:35.000Z", str);
  }

  static void testMain() {
    testNow();
    testValue();
    testUTCGetters();
    testLocalGetters();
    testConstructors();
    testChangeTimeZone();
    testSubAdd();
    testDateStrings();
    testEquivalentYears();
    testFarAwayDates();
  }
}

main() {
  DateTimeTest.testMain();
}
