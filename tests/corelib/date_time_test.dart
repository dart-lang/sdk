// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for Date.

class DateTest {
  // Tests if the time moves eventually forward.
  static void testNow() {
    var t1 = new Date.now();
    bool timeMovedForward = false;
    for (int i = 0; i < 1000000; i++) {
      var t2 = new Date.now();
      if (t1.millisecondsSinceEpoch < t2.millisecondsSinceEpoch) {
        timeMovedForward = true;
        break;
      }
    }
    Expect.equals(true, timeMovedForward);
    Expect.isFalse(t1.isUtc);
  }

  static void testValue() {
    var dt1 = new Date.now();
    var millisecondsSinceEpoch = dt1.millisecondsSinceEpoch;
    var dt2 = new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    Expect.equals(millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
  }

  static void testFarAwayDates() {
    Date dt =
        new Date.fromMillisecondsSinceEpoch(1000000000000001, isUtc: true);
    Expect.equals(33658, dt.year);
    Expect.equals(9, dt.month);
    Expect.equals(27, dt.day);
    Expect.equals(1, dt.hour);
    Expect.equals(46, dt.minute);
    Expect.equals(40, dt.second);
    Expect.equals(1, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-1000000000000001, isUtc: true);
    Expect.equals(-29719, dt.year);
    Expect.equals(4, dt.month);
    Expect.equals(5, dt.day);
    Expect.equals(22, dt.hour);
    Expect.equals(13, dt.minute);
    Expect.equals(19, dt.second);
    Expect.equals(999, dt.millisecond);
    // Same with local zone.
    dt = new Date.fromMillisecondsSinceEpoch(1000000000000001);
    Expect.equals(33658, dt.year);
    Expect.equals(9, dt.month);
    Expect.equals(true, dt.day == 27 || dt.day == 26);
    // Not much we can test for local hour.
    Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
    // Timezones can have offsets down to 15 minute.
    Expect.equals(true, dt.minute % 15 == 46 % 15);
    Expect.equals(40, dt.second);
    Expect.equals(1, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-1000000000000001);
    Expect.equals(-29719, dt.year);
    Expect.equals(4, dt.month);
    Expect.equals(true, 5 == dt.day || 6 == dt.day);
    // Not much we can test for local hour.
    Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
    // Timezones can have offsets down to 15 minute.
    Expect.equals(true, dt.minute % 15 == 13);
    Expect.equals(19, dt.second);
    Expect.equals(999, dt.millisecond);
  }

  static void testEquivalentYears() {
    // All hardcoded values come from V8. This means that the values are not
    // necessarily correct (see limitations of Date object in
    // EcmaScript 15.9.1 and in particular 15.9.1.8/9).
    Date dt = new Date.fromMillisecondsSinceEpoch(-31485600000, isUtc: true);
    Expect.equals(1969, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-63108000000, isUtc: true);
    Expect.equals(1968, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-94644000000, isUtc: true);
    Expect.equals(1967, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-126180000000, isUtc: true);
    Expect.equals(1966, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-157716000000, isUtc: true);
    Expect.equals(1965, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-2177402400000, isUtc: true);
    Expect.equals(1901, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-5333076000000, isUtc: true);
    Expect.equals(1801, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-8520285600000, isUtc: true);
    Expect.equals(1700, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-14831719200000, isUtc: true);
    Expect.equals(1500, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-59011408800000, isUtc: true);
    Expect.equals(100, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(14, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-62011408800000, isUtc: true);
    Expect.equals(4, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(8, dt.day);
    Expect.equals(8, dt.hour);
    Expect.equals(40, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-64011408800000, isUtc: true);
    Expect.equals(-59, dt.year);
    Expect.equals(7, dt.month);
    Expect.equals(24, dt.day);
    Expect.equals(5, dt.hour);
    Expect.equals(6, dt.minute);
    Expect.equals(40, dt.second);
    Expect.equals(0, dt.millisecond);
    final int SECONDS_YEAR_2035 = 2051222400;
    dt = new Date.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 + 1,
                                             isUtc: true);
    Expect.equals(2035, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(0, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(1, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 - 1,
                                             isUtc: true);
    Expect.equals(2034, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(31, dt.day);
    Expect.equals(23, dt.hour);
    Expect.equals(59, dt.minute);
    Expect.equals(59, dt.second);
    Expect.equals(999, dt.millisecond);
    dt = new Date.utc(2035, 1, 1, 0, 0, 0, 1);
    Expect.equals(SECONDS_YEAR_2035 * 1000 + 1, dt.millisecondsSinceEpoch);
    dt = new Date.utc(2034, 12, 31, 23, 59, 59, 999);
    Expect.equals(SECONDS_YEAR_2035 * 1000 - 1, dt.millisecondsSinceEpoch);
    dt = new Date.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 + 1);
    Expect.equals(true, (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
                        (2034 == dt.year && 12 == dt.month && 31 == dt.day));
    Expect.equals(0, dt.second);
    Expect.equals(1, dt.millisecond);
    Date dt2 = new Date(
        dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
        dt.millisecond);
    Expect.equals(dt.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
    dt = new Date.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 - 1);
    Expect.equals(true, (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
                        (2034 == dt.year && 12 == dt.month && 31 == dt.day));
    Expect.equals(59, dt.second);
    Expect.equals(999, dt.millisecond);
    dt2 = new Date(
        dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
        dt.millisecond);
    Expect.equals(dt.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
    dt = new Date.fromMillisecondsSinceEpoch(2100000000 * 1000, isUtc: true);
    Expect.equals(2036, dt.year);
    Expect.equals(7, dt.month);
    Expect.equals(18, dt.day);
    Expect.equals(13, dt.hour);
    Expect.equals(20, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    // Internally this will use the maximum value for the native calls.
    dt = new Date(2036, 7, 18, 13, 20);
    Expect.equals(2036, dt.year);
    Expect.equals(7, dt.month);
    Expect.equals(18, dt.day);
    Expect.equals(13, dt.hour);
    Expect.equals(20, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    Expect.equals("2036-07-18 13:20:00.000", dt.toString());
  }

  static void testExtremes() {
    var dt =
        new Date.fromMillisecondsSinceEpoch(8640000000000000, isUtc: true);
    Expect.equals(275760, dt.year);
    Expect.equals(9, dt.month);
    Expect.equals(13, dt.day);
    Expect.equals(0, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    dt = new Date.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true);
    Expect.equals(-271821, dt.year);
    Expect.equals(4, dt.month);
    Expect.equals(20, dt.day);
    Expect.equals(0, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(0, dt.millisecond);
    // Make sure that we can build the extreme dates in local too.
    dt = new Date.fromMillisecondsSinceEpoch(8640000000000000);
    dt = new Date(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    Expect.equals(8640000000000000, dt.millisecondsSinceEpoch);
    dt = new Date.fromMillisecondsSinceEpoch(-8640000000000000);
    dt = new Date(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    Expect.equals(-8640000000000000, dt.millisecondsSinceEpoch);
    Expect.throws(() => new Date.fromMillisecondsSinceEpoch(8640000000000001,
                                                            isUtc: true));
    Expect.throws(() => new Date.fromMillisecondsSinceEpoch(-8640000000000001,
                                                            isUtc: true));
    Expect.throws(() => new Date.fromMillisecondsSinceEpoch(8640000000000001));
    Expect.throws(() => new Date.fromMillisecondsSinceEpoch(-8640000000000001));
    dt = new Date.fromMillisecondsSinceEpoch(8640000000000000);
    Expect.throws(() => new Date(dt.year, dt.month, dt.day,
                                 dt.hour, dt.minute, 0, 1));
    dt = new Date.fromMillisecondsSinceEpoch(8640000000000000, isUtc: true);
    Expect.throws(() => new Date.utc(dt.year, dt.month, dt.day,
                                     dt.hour, dt.minute, 0, 1));
    dt = new Date.fromMillisecondsSinceEpoch(-8640000000000000);
    Expect.throws(() => new Date(dt.year, dt.month, dt.day,
                                 dt.hour, dt.minute, 0, -1));
    dt = new Date.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true);
    Expect.throws(() => new Date.utc(dt.year, dt.month, dt.day,
                                     dt.hour, dt.minute, 0, -1));
  }

  static void testUTCGetters() {
    var dt = new Date.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
    Expect.equals(2011, dt.year);
    Expect.equals(5, dt.month);
    Expect.equals(11, dt.day);
    Expect.equals(18, dt.hour);
    Expect.equals(58, dt.minute);
    Expect.equals(35, dt.second);
    Expect.equals(0, dt.millisecond);
    Expect.equals(true, dt.isUtc);
    Expect.equals(1305140315000, dt.millisecondsSinceEpoch);
    dt = new Date.fromMillisecondsSinceEpoch(-9999999, isUtc: true);
    Expect.equals(1969, dt.year);
    Expect.equals(12, dt.month);
    Expect.equals(31, dt.day);
    Expect.equals(21, dt.hour);
    Expect.equals(13, dt.minute);
    Expect.equals(20, dt.second);
    Expect.equals(1, dt.millisecond);
  }

  static void testLocalGetters() {
    var dt1 = new Date.fromMillisecondsSinceEpoch(1305140315000);
    var dt2 = new Date.utc(dt1.year, dt1.month, dt1.day,
                           dt1.hour, dt1.minute, dt1.second, dt1.millisecond);
    Duration zoneOffset = dt1.difference(dt2);
    Expect.equals(true, zoneOffset.inDays == 0);
    Expect.equals(true, zoneOffset.inHours.abs() <= 12);
    Expect.equals(dt1.year, dt2.year);
    Expect.equals(dt1.month, dt2.month);
    Expect.equals(true, (dt1.day - dt2.day).abs() <= 1);
    Expect.equals(true, dt1.hour < 24);
    // There are timezones with 0.5 or 0.25 hour offsets.
    Expect.equals(true,
                  (dt1.minute == dt2.minute) ||
                  ((dt1.minute - dt2.minute).abs() == 30) ||
                  ((dt1.minute - dt2.minute).abs() == 15));
    Expect.equals(dt1.second, dt2.second);
    Expect.equals(dt1.millisecond, dt2.millisecond);
  }

  static void testConstructors() {
    var dt0 = new Date.utc(2011, 5, 11, 18, 58, 35, 0);
    Expect.equals(1305140315000, dt0.millisecondsSinceEpoch);
    var dt1 = new Date.fromMillisecondsSinceEpoch(1305140315000);
    Expect.equals(dt1.millisecondsSinceEpoch, dt0.millisecondsSinceEpoch);
    Expect.equals(true, dt1 == dt0);
    var dt3 = new Date(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
                       dt1.second, dt1.millisecond);
    Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
    Expect.equals(true, dt1 == dt3);
    dt3 = new Date(
        dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
        dt1.second, dt1.millisecond);
    Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
    Expect.equals(true, dt1 == dt3);
    var dt2 = dt1.toLocal();
    dt3 = new Date(2011, 5, dt1.day, dt1.hour, dt1.minute, 35, 0);
    Expect.equals(dt2.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
    Expect.equals(true, dt2 == dt3);
    dt1 = new Date.fromMillisecondsSinceEpoch(-9999999, isUtc: true);
    dt3 = new Date.utc(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
                       dt1.second, dt1.millisecond);
    Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
    dt3 = new Date.utc(99, 1, 2, 10, 11, 12, 0);
    Expect.equals(99, dt3.year);
    Expect.equals(1, dt3.month);
    Expect.equals(2, dt3.day);
    Expect.equals(10, dt3.hour);
    Expect.equals(11, dt3.minute);
    Expect.equals(12, dt3.second);
    Expect.equals(0, dt3.millisecond);
    Expect.equals(true, dt3.isUtc);
    var dt4 = new Date(99, 1, 2);
    Expect.equals(99, dt4.year);
    Expect.equals(1, dt4.month);
    Expect.equals(2, dt4.day);
    Expect.equals(0, dt4.hour);
    Expect.equals(0, dt4.minute);
    Expect.equals(0, dt4.second);
    Expect.equals(0, dt4.millisecond);
    Expect.isFalse(dt4.isUtc);
    var dt5 = new Date.utc(99, 1, 2);
    Expect.equals(99, dt5.year);
    Expect.equals(1, dt5.month);
    Expect.equals(2, dt5.day);
    Expect.equals(0, dt5.hour);
    Expect.equals(0, dt5.minute);
    Expect.equals(0, dt5.second);
    Expect.equals(0, dt5.millisecond);
    Expect.isTrue(dt5.isUtc);
    var dt6 = new Date(2012, 2, 27, 13, 27, 0);
    Expect.equals(2012, dt6.year);
    Expect.equals(2, dt6.month);
    Expect.equals(27, dt6.day);
    Expect.equals(13, dt6.hour);
    Expect.equals(27, dt6.minute);
    Expect.equals(0, dt6.second);
    Expect.equals(0, dt6.millisecond);
    Expect.isFalse(dt6.isUtc);
    var dt7 = new Date.utc(2012, 2, 27, 13, 27, 0);
    Expect.equals(2012, dt7.year);
    Expect.equals(2, dt7.month);
    Expect.equals(27, dt7.day);
    Expect.equals(13, dt7.hour);
    Expect.equals(27, dt7.minute);
    Expect.equals(0, dt7.second);
    Expect.equals(0, dt7.millisecond);
    Expect.isTrue(dt7.isUtc);
  }

  static void testChangeTimeZone() {
    var dt1 = new Date.fromMillisecondsSinceEpoch(1305140315000);
    var dt2 = dt1.toUtc();
    Expect.equals(dt1.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
    var dt3 = new Date.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
    Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
    Expect.equals(dt2.year, dt3.year);
    Expect.equals(dt2.month, dt3.month);
    Expect.equals(dt2.day, dt3.day);
    Expect.equals(dt2.hour, dt3.hour);
    Expect.equals(dt2.minute, dt3.minute);
    Expect.equals(dt2.second, dt3.second);
    Expect.equals(dt2.millisecond, dt3.millisecond);
    var dt4 = dt3.toLocal();
    Expect.equals(dt1.year, dt4.year);
    Expect.equals(dt1.month, dt4.month);
    Expect.equals(dt1.day, dt4.day);
    Expect.equals(dt1.hour, dt4.hour);
    Expect.equals(dt1.minute, dt4.minute);
    Expect.equals(dt1.second, dt4.second);
    Expect.equals(dt1.millisecond, dt4.millisecond);
  }

  static void testSubAdd() {
    var dt1 = new Date.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
    var dt2 = dt1.add(new Duration(milliseconds:
        3 * Duration.MILLISECONDS_PER_SECOND + 5));
    Expect.equals(dt1.year, dt2.year);
    Expect.equals(dt1.month, dt2.month);
    Expect.equals(dt1.day, dt2.day);
    Expect.equals(dt1.hour, dt2.hour);
    Expect.equals(dt1.minute, dt2.minute);
    Expect.equals(dt1.second + 3, dt2.second);
    Expect.equals(dt1.millisecond + 5, dt2.millisecond);
    var dt3 = dt2.subtract(new Duration(milliseconds:
        3 * Duration.MILLISECONDS_PER_SECOND + 5));
    Expect.equals(true, dt1 == dt3);
    Expect.equals(false, dt1 == dt2);
  }

  static void testUnderflowAndOverflow() {
    final dtBase = new Date(2012, 6, 20, 12, 30, 30, 500);

    // Millisecond
    print("  >>> Millisecond+");
    var dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
                      dtBase.minute, dtBase.second, 1000);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second + 1, dt.second);
    Expect.equals(0, dt.millisecond);

    print("  >>> Millisecond-");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
                  dtBase.minute, dtBase.second, -1000);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second - 1, dt.second);
    Expect.equals(0, dt.millisecond);

    // Second
    print("  >>> Second+");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
                  dtBase.minute, 60, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute + 1, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    print("  >>> Second-");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
                  dtBase.minute, -60, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute - 1, dt.minute);
    Expect.equals(0, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    // Minute
    print("  >>> Minute+");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour, 60,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour + 1, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    print("  >>> Minute-");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, dtBase.hour, -60,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour - 1, dt.hour);
    Expect.equals(0, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    // Hour
    print("  >>> Hour+");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, 24, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day + 1, dt.day);
    Expect.equals(0, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    print("  >>> Hour-");
    dt = new Date(dtBase.year, dtBase.month, dtBase.day, -24, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month, dt.month);
    Expect.equals(dtBase.day - 1, dt.day);
    Expect.equals(0, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    // Day
    print("  >>> Day+");
    dt = new Date(dtBase.year, dtBase.month, 31, dtBase.hour, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month + 1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    print("  >>> Day-");
    dt = new Date(dtBase.year, dtBase.month, -30, dtBase.hour, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year, dt.year);
    Expect.equals(dtBase.month - 1, dt.month);
    Expect.equals(1, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    // Month
    print("  >>> Month+");
    dt = new Date(dtBase.year, 13, dtBase.day, dtBase.hour, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year + 1, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    print("  >>> Month-");
    dt = new Date(dtBase.year, -11, dtBase.day, dtBase.hour, dtBase.minute,
                  dtBase.second, dtBase.millisecond);
    Expect.equals(dtBase.year - 1, dt.year);
    Expect.equals(1, dt.month);
    Expect.equals(dtBase.day, dt.day);
    Expect.equals(dtBase.hour, dt.hour);
    Expect.equals(dtBase.minute, dt.minute);
    Expect.equals(dtBase.second, dt.second);
    Expect.equals(dtBase.millisecond, dt.millisecond);

    // Flowing all the way up the chain.
    print("  >>> Flow+");
    var dtBase1 = new Date(2012, 12, 31, 23, 59, 59, 999);
    var dtTick = new Date(dtBase1.year, dtBase1.month, dtBase1.day,
                          dtBase1.hour, dtBase1.minute, dtBase1.second,
                          dtBase1.millisecond + 1);
    Expect.equals(dtBase1.year + 1, dtTick.year);
    Expect.equals(1, dtTick.month);
    Expect.equals(1, dtTick.day);
    Expect.equals(0, dtTick.hour);
    Expect.equals(0, dtTick.minute);
    Expect.equals(0, dtTick.second);
    Expect.equals(0, dtTick.millisecond);

    print("  >>> Flow-");
    dtBase1 = new Date(2012, 1, 1, 0, 0, 0, 0);
    dtTick = new Date(dtBase1.year, dtBase1.month, dtBase1.day, dtBase1.hour,
                      dtBase1.minute, dtBase1.second, dtBase1.millisecond - 1);
    Expect.equals(dtBase1.year - 1, dtTick.year);
    Expect.equals(12, dtTick.month);
    Expect.equals(31, dtTick.day);
    Expect.equals(23, dtTick.hour);
    Expect.equals(59, dtTick.minute);
    Expect.equals(59, dtTick.second);
    Expect.equals(999, dtTick.millisecond);

    print("  >>> extra underflow");
    dtTick = new Date(dtBase1.year, dtBase1.month, dtBase1.day, -17520,
                      dtBase1.minute, dtBase1.second, dtBase1.millisecond);
    Expect.equals(dtBase1.year - 2, dtTick.year);
    Expect.equals(dtBase1.month, dtTick.month);
    Expect.equals(dtBase1.day, dtTick.day);
    Expect.equals(dtBase1.hour, dtTick.hour);
    Expect.equals(dtBase1.minute, dtTick.minute);
    Expect.equals(dtBase1.second, dtTick.second);
    Expect.equals(dtBase1.millisecond, dtTick.millisecond);
  }

  static void testDateStrings() {
    // TODO(floitsch): Clean up the Date API that deals with strings.
    var dt1 = new Date.fromString("2011-05-11 18:58:35Z");
    Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
    Expect.isTrue(dt1.isUtc);
    dt1 = new Date.fromString("20110511 18:58:35z");
    Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
    Expect.isTrue(dt1.isUtc);
    dt1 = new Date.fromString("+20110511 18:58:35z");
    Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
    Expect.isTrue(dt1.isUtc);
    var str = dt1.toString();
    var dt2 = new Date.fromString(str);
    Expect.equals(true, dt1 == dt2);
    var dt3 = dt1.toUtc();
    str = dt3.toString();
    Expect.equals("2011-05-11 18:58:35.000Z", str);
    var dt4 = new Date.fromString("-1234-01-01 00:00:00Z");
    Expect.equals(-1234, dt4.year);
    Expect.equals(1, dt4.month);
    Expect.equals(1, dt4.day);
    Expect.equals(0, dt4.hour);
    Expect.equals(0, dt4.minute);
    Expect.equals(0, dt4.second);
    Expect.equals(0, dt4.millisecond);
    Expect.isTrue(dt4.isUtc);
    var dt5 = new Date.fromString("0099-01-02");
    Expect.equals(99, dt5.year);
    Expect.equals(1, dt5.month);
    Expect.equals(2, dt5.day);
    Expect.equals(0, dt5.hour);
    Expect.equals(0, dt5.minute);
    Expect.equals(0, dt5.second);
    Expect.equals(0, dt5.millisecond);
    Expect.isFalse(dt5.isUtc);
    var dt6 = new Date.fromString("2012-01-01 00:00:10.012");
    Expect.equals(12, dt6.millisecond);
    dt6 = new Date.fromString("2012-01-01 00:00:10.003");
    Expect.equals(3, dt6.millisecond);
    dt6 = new Date.fromString("2012-01-01 00:00:10.5");
    Expect.equals(500, dt6.millisecond);
    dt6 = new Date.fromString("2012-01-01 00:00:10.003Z");
    Expect.equals(3, dt6.millisecond);
    dt6 = new Date.fromString("2012-01-01 00:00:10.5z");
    Expect.equals(500, dt6.millisecond);
    var dt7 = new Date.fromString("2011-05-11T18:58:35Z");
    Expect.equals(1305140315000, dt7.millisecondsSinceEpoch);
    var dt8 = new Date.fromString("-1234-01-01T00:00:00Z");
    Expect.equals(-1234, dt8.year);
    Expect.equals(1, dt8.month);
    Expect.equals(1, dt8.day);
    Expect.equals(0, dt8.hour);
    Expect.equals(0, dt8.minute);
    Expect.equals(0, dt8.second);
    Expect.equals(0, dt8.millisecond);
    Expect.isTrue(dt8.isUtc);
    var dt9 = new Date.fromString("-1234-01-01T00:00:00");
    Expect.equals(-1234, dt9.year);
    Expect.equals(1, dt9.month);
    Expect.equals(1, dt9.day);
    Expect.equals(0, dt9.hour);
    Expect.equals(0, dt9.minute);
    Expect.equals(0, dt9.second);
    Expect.equals(0, dt9.millisecond);
    Expect.isFalse(dt9.isUtc);
    var dt10 = new Date.fromString("-12340101");
    Expect.equals(-1234, dt10.year);
    Expect.equals(1, dt10.month);
    Expect.equals(1, dt10.day);
    Expect.equals(0, dt10.hour);
    Expect.equals(0, dt10.minute);
    Expect.equals(0, dt10.second);
    Expect.equals(0, dt10.millisecond);
    Expect.isFalse(dt10.isUtc);
    dt1 = new Date.fromString("2012-02-27 13:27:00");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(13, dt1.hour);
    Expect.equals(27, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(false, dt1.isUtc);
    dt1 = new Date.fromString("2012-02-27 13:27:00.423z");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(13, dt1.hour);
    Expect.equals(27, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(423, dt1.millisecond);
    Expect.equals(true, dt1.isUtc);
    dt1 = new Date.fromString("20120227 13:27:00");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(13, dt1.hour);
    Expect.equals(27, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(false, dt1.isUtc);
    dt1 = new Date.fromString("20120227T132700");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(13, dt1.hour);
    Expect.equals(27, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(false, dt1.isUtc);
    dt1 = new Date.fromString("20120227");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(0, dt1.hour);
    Expect.equals(0, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(false, dt1.isUtc);
    dt1 = new Date.fromString("2012-02-27T14Z");
    Expect.equals(2012, dt1.year);
    Expect.equals(2, dt1.month);
    Expect.equals(27, dt1.day);
    Expect.equals(14, dt1.hour);
    Expect.equals(0, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(true, dt1.isUtc);
    dt1 = new Date.fromString("-123450101 00:00:00 Z");
    Expect.equals(-12345, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(1, dt1.day);
    Expect.equals(0, dt1.hour);
    Expect.equals(0, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(true, dt1.isUtc);
    // We only support millisecond. If the user supplies more data (the "51"
    // here), we round.
    // If (eventually) we support more than just millisecond this test could
    // fail. Please update the test in this case.
    dt1 = new Date.fromString("1999-01-02 23:59:59.99951");
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(3, dt1.day);
    Expect.equals(0, dt1.hour);
    Expect.equals(0, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(false, dt1.isUtc);
    dt1 = new Date.fromString("1999-01-02 23:58:59.99951Z");
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(2, dt1.day);
    Expect.equals(23, dt1.hour);
    Expect.equals(59, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(true, dt1.isUtc);
    dt1 = new Date.fromString("0009-09-09 09:09:09.009Z");
    Expect.equals(9, dt1.year);
    Expect.equals(9, dt1.month);
    Expect.equals(9, dt1.day);
    Expect.equals(9, dt1.hour);
    Expect.equals(9, dt1.minute);
    Expect.equals(9, dt1.second);
    Expect.equals(9, dt1.millisecond);
    Expect.equals(true, dt1.isUtc);
  }

  static void testWeekday() {
    // 2011-10-06 is Summertime.
    var d = new Date(2011, 10, 6, 0, 45, 37, 0);
    Expect.equals(Date.THU, d.weekday);
    d = new Date.utc(2011, 10, 6, 0, 45, 37, 0);
    Expect.equals(Date.THU, d.weekday);
    d = new Date(2011, 10, 5, 23, 45, 37, 0);
    Expect.equals(Date.WED, d.weekday);
    d = new Date.utc(2011, 10, 5, 23, 45, 37, 0);
    Expect.equals(Date.WED, d.weekday);
    // 1970-01-01 is Wintertime.
    d = new Date(1970, 1, 1, 0, 0, 0, 1);
    Expect.equals(Date.THU, d.weekday);
    d = new Date.utc(1970, 1, 1, 0, 0, 0, 1);
    Expect.equals(Date.THU, d.weekday);
    d = new Date.utc(1969, 12, 31, 23, 59, 59, 999);
    Expect.equals(Date.WED, d.weekday);
    d = new Date(1969, 12, 31, 23, 59, 59, 999);
    Expect.equals(Date.WED, d.weekday);
    d = new Date(2011, 10, 4, 23, 45, 37, 0);
    Expect.equals(Date.TUE, d.weekday);
    d = new Date(2011, 10, 3, 23, 45, 37, 0);
    Expect.equals(Date.MON, d.weekday);
    d = new Date(2011, 10, 2, 23, 45, 37, 0);
    Expect.equals(Date.SUN, d.weekday);
    d = new Date(2011, 10, 1, 23, 45, 37, 0);
    Expect.equals(Date.SAT, d.weekday);
    d = new Date(2011, 9, 30, 23, 45, 37, 0);
    Expect.equals(Date.FRI, d.weekday);
  }

  static void testMain() {
    testNow();
    testValue();
    testConstructors();
    testUTCGetters();
    testLocalGetters();
    testChangeTimeZone();
    testSubAdd();
    testUnderflowAndOverflow();
    testDateStrings();
    testEquivalentYears();
    testExtremes();
    testFarAwayDates();
    testWeekday();
  }
}

main() {
  DateTest.testMain();
}
