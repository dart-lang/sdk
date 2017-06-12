// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime.

bool get supportsMicroseconds =>
    new DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

// Identical to _MAX_MILLISECONDS_SINCE_EPOCH in date_time.dart
const int _MAX_MILLISECONDS = 8640000000000000;

// Tests if the time moves eventually forward.
void testNow() {
  var t1 = new DateTime.now();
  bool timeMovedForward = false;
  const int N = 1000000;
  outer:
  while (true) {
    for (int i = N; i > 0; i--) {
      var t2 = new DateTime.now();
      if (t1.millisecondsSinceEpoch < t2.millisecondsSinceEpoch) {
        break outer;
      }
    }
    print("testNow: No Date.now() progress in $N loops. Time: $t1");
  }
  Expect.isFalse(t1.isUtc);
}

void testMillisecondsSinceEpoch() {
  var dt1 = new DateTime.now();
  var millisecondsSinceEpoch = dt1.millisecondsSinceEpoch;
  var dt2 = new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  Expect.equals(millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
}

void testMicrosecondsSinceEpoch() {
  var dt1 = new DateTime.fromMillisecondsSinceEpoch(1);
  var microsecondsSinceEpoch = dt1.microsecondsSinceEpoch;
  var dt2 = new DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
  Expect.equals(microsecondsSinceEpoch, dt2.microsecondsSinceEpoch);

  dt1 = new DateTime.now();
  microsecondsSinceEpoch = dt1.microsecondsSinceEpoch;
  dt2 = new DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
  Expect.equals(microsecondsSinceEpoch, dt2.microsecondsSinceEpoch);
}

void testFarAwayDates() {
  DateTime dt =
      new DateTime.fromMillisecondsSinceEpoch(1000000000000001, isUtc: true);
  Expect.equals(33658, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(27, dt.day);
  Expect.equals(1, dt.hour);
  Expect.equals(46, dt.minute);
  Expect.equals(40, dt.second);
  Expect.equals(1, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-1000000000000001, isUtc: true);
  Expect.equals(-29719, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(5, dt.day);
  Expect.equals(22, dt.hour);
  Expect.equals(13, dt.minute);
  Expect.equals(19, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  // Same with local zone.
  dt = new DateTime.fromMillisecondsSinceEpoch(1000000000000001);
  Expect.equals(33658, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(true, dt.day == 27 || dt.day == 26);
  // Not much we can test for local hour.
  Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
  // Timezones can have offsets down to 15 minute.
  Expect.equals(true, dt.minute % 15 == 46 % 15);
  Expect.equals(40, dt.second);
  Expect.equals(1, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-1000000000000001);
  Expect.equals(-29719, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(true, 5 == dt.day || 6 == dt.day);
  // Not much we can test for local hour.
  Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
  // Timezones can have offsets down to 15 minute.
  Expect.equals(true, dt.minute % 15 == 13);
  Expect.equals(19, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  if (!supportsMicroseconds) return;
  dt =
      new DateTime.fromMicrosecondsSinceEpoch(1000000000000000001, isUtc: true);
  Expect.equals(33658, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(27, dt.day);
  Expect.equals(1, dt.hour);
  Expect.equals(46, dt.minute);
  Expect.equals(40, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(1, dt.microsecond);
  dt = new DateTime.fromMicrosecondsSinceEpoch(-1000000000000000001,
      isUtc: true);
  Expect.equals(-29719, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(5, dt.day);
  Expect.equals(22, dt.hour);
  Expect.equals(13, dt.minute);
  Expect.equals(19, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(999, dt.microsecond);
  // Same with local zone.
  dt = new DateTime.fromMicrosecondsSinceEpoch(1000000000000000001);
  Expect.equals(33658, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(true, dt.day == 27 || dt.day == 26);
  // Not much we can test for local hour.
  Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
  // Timezones can have offsets down to 15 minute.
  Expect.equals(true, dt.minute % 15 == 46 % 15);
  Expect.equals(40, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(1, dt.microsecond);
  dt = new DateTime.fromMicrosecondsSinceEpoch(-1000000000000000001);
  Expect.equals(-29719, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(true, 5 == dt.day || 6 == dt.day);
  // Not much we can test for local hour.
  Expect.equals(true, dt.hour >= 0 && dt.hour < 24);
  // Timezones can have offsets down to 15 minute.
  Expect.equals(true, dt.minute % 15 == 13);
  Expect.equals(19, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(999, dt.microsecond);
}

void testEquivalentYears() {
  // All hardcoded values come from V8. This means that the values are not
  // necessarily correct (see limitations of DateTime object in
  // EcmaScript 15.9.1 and in particular 15.9.1.8/9).
  DateTime dt =
      new DateTime.fromMillisecondsSinceEpoch(-31485600000, isUtc: true);
  Expect.equals(1969, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-63108000000, isUtc: true);
  Expect.equals(1968, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-94644000000, isUtc: true);
  Expect.equals(1967, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-126180000000, isUtc: true);
  Expect.equals(1966, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-157716000000, isUtc: true);
  Expect.equals(1965, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-2177402400000, isUtc: true);
  Expect.equals(1901, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-5333076000000, isUtc: true);
  Expect.equals(1801, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-8520285600000, isUtc: true);
  Expect.equals(1700, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-14831719200000, isUtc: true);
  Expect.equals(1500, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-59011408800000, isUtc: true);
  Expect.equals(100, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(14, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-62011408800000, isUtc: true);
  Expect.equals(4, dt.year);
  Expect.equals(12, dt.month);
  Expect.equals(8, dt.day);
  Expect.equals(8, dt.hour);
  Expect.equals(40, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-64011408800000, isUtc: true);
  Expect.equals(-59, dt.year);
  Expect.equals(7, dt.month);
  Expect.equals(24, dt.day);
  Expect.equals(5, dt.hour);
  Expect.equals(6, dt.minute);
  Expect.equals(40, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  final int SECONDS_YEAR_2035 = 2051222400;
  dt = new DateTime.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 + 1,
      isUtc: true);
  Expect.equals(2035, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(1, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 - 1,
      isUtc: true);
  Expect.equals(2034, dt.year);
  Expect.equals(12, dt.month);
  Expect.equals(31, dt.day);
  Expect.equals(23, dt.hour);
  Expect.equals(59, dt.minute);
  Expect.equals(59, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  dt = new DateTime.utc(2035, 1, 1, 0, 0, 0, 1);
  Expect.equals(SECONDS_YEAR_2035 * 1000 + 1, dt.millisecondsSinceEpoch);
  dt = new DateTime.utc(2034, 12, 31, 23, 59, 59, 999);
  Expect.equals(SECONDS_YEAR_2035 * 1000 - 1, dt.millisecondsSinceEpoch);
  dt = new DateTime.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 + 1);
  Expect.equals(
      true,
      (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
          (2034 == dt.year && 12 == dt.month && 31 == dt.day));
  Expect.equals(0, dt.second);
  Expect.equals(1, dt.millisecond);
  DateTime dt2 = new DateTime(
      dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
  Expect.equals(dt.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
  dt = new DateTime.fromMillisecondsSinceEpoch(SECONDS_YEAR_2035 * 1000 - 1);
  Expect.equals(
      true,
      (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
          (2034 == dt.year && 12 == dt.month && 31 == dt.day));
  Expect.equals(59, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  dt2 = new DateTime(
      dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
  Expect.equals(dt.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
  dt = new DateTime.fromMillisecondsSinceEpoch(2100000000 * 1000, isUtc: true);
  Expect.equals(2036, dt.year);
  Expect.equals(7, dt.month);
  Expect.equals(18, dt.day);
  Expect.equals(13, dt.hour);
  Expect.equals(20, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  // Internally this will use the maximum value for the native calls.
  dt = new DateTime(2036, 7, 18, 13, 20);
  Expect.equals(2036, dt.year);
  Expect.equals(7, dt.month);
  Expect.equals(18, dt.day);
  Expect.equals(13, dt.hour);
  Expect.equals(20, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  Expect.equals("2036-07-18 13:20:00.000", dt.toString());

  if (!supportsMicroseconds) return;

  dt = new DateTime.utc(2035, 1, 1, 0, 0, 0, 0, 1);
  Expect.equals(SECONDS_YEAR_2035 * 1000000 + 1, dt.microsecondsSinceEpoch);
  dt = new DateTime.utc(2034, 12, 31, 23, 59, 59, 999, 999);
  Expect.equals(SECONDS_YEAR_2035 * 1000000 - 1, dt.microsecondsSinceEpoch);
  dt = new DateTime.fromMicrosecondsSinceEpoch(SECONDS_YEAR_2035 * 1000000 + 1);
  Expect.equals(
      true,
      (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
          (2034 == dt.year && 12 == dt.month && 31 == dt.day));
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(1, dt.microsecond);
  dt2 = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
      dt.millisecond, dt.microsecond);
  Expect.equals(dt.microsecondsSinceEpoch, dt2.microsecondsSinceEpoch);
  dt = new DateTime.fromMicrosecondsSinceEpoch(SECONDS_YEAR_2035 * 1000000 - 1);
  Expect.equals(
      true,
      (2035 == dt.year && 1 == dt.month && 1 == dt.day) ||
          (2034 == dt.year && 12 == dt.month && 31 == dt.day));
  Expect.equals(59, dt.second);
  Expect.equals(999, dt.millisecond);
  Expect.equals(999, dt.microsecond);

  dt2 = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
      dt.millisecond, dt.microsecond);
  Expect.equals(dt.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
  dt = new DateTime.fromMicrosecondsSinceEpoch(2100000000 * 1000000,
      isUtc: true);
  Expect.equals(2036, dt.year);
  Expect.equals(7, dt.month);
  Expect.equals(18, dt.day);
  Expect.equals(13, dt.hour);
  Expect.equals(20, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
}

void testExtremes() {
  var dt =
      new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.equals(275760, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(13, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.equals(-271821, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(20, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  // Make sure that we can build the extreme dates in local too.
  dt = new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  dt = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  Expect.equals(_MAX_MILLISECONDS, dt.millisecondsSinceEpoch);
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  dt = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  Expect.equals(-_MAX_MILLISECONDS, dt.millisecondsSinceEpoch);
  Expect.throws(() => new DateTime.fromMillisecondsSinceEpoch(
      _MAX_MILLISECONDS + 1,
      isUtc: true));
  Expect.throws(() => new DateTime.fromMillisecondsSinceEpoch(
      -_MAX_MILLISECONDS - 1,
      isUtc: true));
  Expect.throws(
      () => new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS + 1));
  Expect.throws(
      () => new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS - 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  Expect.throws(
      () => new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() =>
      new DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  Expect.throws(
      () => new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, -1));
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() =>
      new DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, -1));

  if (!supportsMicroseconds) return;

  dt = new DateTime.fromMicrosecondsSinceEpoch(_MAX_MILLISECONDS * 1000);
  dt = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  Expect.equals(_MAX_MILLISECONDS * 1000, dt.microsecondsSinceEpoch);
  dt = new DateTime.fromMicrosecondsSinceEpoch(-_MAX_MILLISECONDS * 1000);
  dt = new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  Expect.equals(-_MAX_MILLISECONDS * 1000, dt.microsecondsSinceEpoch);
  Expect.throws(() => new DateTime.fromMicrosecondsSinceEpoch(
      _MAX_MILLISECONDS * 1000 + 1,
      isUtc: true));
  Expect.throws(() => new DateTime.fromMicrosecondsSinceEpoch(
      -_MAX_MILLISECONDS * 1000 - 1,
      isUtc: true));
  Expect.throws(() =>
      new DateTime.fromMicrosecondsSinceEpoch(_MAX_MILLISECONDS * 1000 + 1));
  Expect.throws(() =>
      new DateTime.fromMicrosecondsSinceEpoch(-_MAX_MILLISECONDS * 1000 - 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  Expect.throws(() =>
      new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() =>
      new DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, 1));
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  Expect.throws(() =>
      new DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, -1));
  dt = new DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() => new DateTime.utc(
      dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, -1));
}

void testUTCGetters() {
  var dt = new DateTime.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
  Expect.equals(2011, dt.year);
  Expect.equals(5, dt.month);
  Expect.equals(11, dt.day);
  Expect.equals(18, dt.hour);
  Expect.equals(58, dt.minute);
  Expect.equals(35, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  Expect.equals(true, dt.isUtc);
  Expect.equals(1305140315000, dt.millisecondsSinceEpoch);
  dt = new DateTime.fromMillisecondsSinceEpoch(-9999999, isUtc: true);
  Expect.equals(1969, dt.year);
  Expect.equals(12, dt.month);
  Expect.equals(31, dt.day);
  Expect.equals(21, dt.hour);
  Expect.equals(13, dt.minute);
  Expect.equals(20, dt.second);
  Expect.equals(1, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  if (!supportsMicroseconds) return;

  dt = new DateTime.fromMicrosecondsSinceEpoch(-9999999999, isUtc: true);
  Expect.equals(1969, dt.year);
  Expect.equals(12, dt.month);
  Expect.equals(31, dt.day);
  Expect.equals(21, dt.hour);
  Expect.equals(13, dt.minute);
  Expect.equals(20, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(1, dt.microsecond);
}

void testLocalGetters() {
  var dt1 = new DateTime.fromMillisecondsSinceEpoch(1305140315000);
  var dt2 = new DateTime.utc(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
      dt1.second, dt1.millisecond, dt1.microsecond);
  Duration zoneOffset = dt1.difference(dt2);
  Expect.equals(true, zoneOffset.inDays == 0);
  Expect.equals(true, zoneOffset.inHours.abs() <= 12);
  Expect.equals(dt1.year, dt2.year);
  Expect.equals(dt1.month, dt2.month);
  Expect.equals(true, (dt1.day - dt2.day).abs() <= 1);
  Expect.equals(true, dt1.hour < 24);
  // There are timezones with 0.5 or 0.25 hour offsets.
  Expect.equals(
      true,
      (dt1.minute == dt2.minute) ||
          ((dt1.minute - dt2.minute).abs() == 30) ||
          ((dt1.minute - dt2.minute).abs() == 15));
  Expect.equals(dt1.second, dt2.second);
  Expect.equals(dt1.millisecond, dt2.millisecond);
  Expect.equals(dt1.microsecond, dt2.microsecond);
}

void testConstructors() {
  var dt0 = new DateTime.utc(2011, 5, 11, 18, 58, 35, 0, 0);
  var dt0b = new DateTime.utc(2011, 5, 11, 18, 58, 35, 0, 0).toLocal();
  Expect.equals(1305140315000, dt0.millisecondsSinceEpoch);
  var dt1 = new DateTime.fromMillisecondsSinceEpoch(1305140315000);
  Expect.equals(dt1.millisecondsSinceEpoch, dt0.millisecondsSinceEpoch);
  Expect.equals(dt1.microsecondsSinceEpoch, dt0.microsecondsSinceEpoch);
  Expect.equals(false, dt1 == dt0);
  Expect.equals(true, dt1 == dt0b);
  var dt3 = new DateTime(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
      dt1.second, dt1.millisecond, dt1.microsecond);
  Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
  Expect.equals(dt1.microsecondsSinceEpoch, dt3.microsecondsSinceEpoch);
  Expect.equals(false, dt3 == dt0);
  Expect.equals(true, dt1 == dt3);
  dt3 = new DateTime(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
      dt1.second, dt1.millisecond, dt1.microsecond);
  Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
  Expect.equals(dt1.microsecondsSinceEpoch, dt3.microsecondsSinceEpoch);
  Expect.equals(true, dt1 == dt3);
  var dt2 = dt1.toLocal();
  dt3 = new DateTime(2011, 5, dt1.day, dt1.hour, dt1.minute, 35, 0, 0);
  Expect.equals(dt2.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
  Expect.equals(dt2.microsecondsSinceEpoch, dt3.microsecondsSinceEpoch);
  Expect.equals(true, dt2 == dt3);
  dt1 = new DateTime.fromMillisecondsSinceEpoch(-9999999, isUtc: true);
  dt3 = new DateTime.utc(dt1.year, dt1.month, dt1.day, dt1.hour, dt1.minute,
      dt1.second, dt1.millisecond);
  Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
  Expect.equals(dt1.microsecondsSinceEpoch, dt3.microsecondsSinceEpoch);
  dt3 = new DateTime.utc(99, 1, 2, 10, 11, 12, 0);
  Expect.equals(99, dt3.year);
  Expect.equals(1, dt3.month);
  Expect.equals(2, dt3.day);
  Expect.equals(10, dt3.hour);
  Expect.equals(11, dt3.minute);
  Expect.equals(12, dt3.second);
  Expect.equals(0, dt3.millisecond);
  Expect.equals(0, dt3.microsecond);
  Expect.equals(true, dt3.isUtc);
  var dt4 = new DateTime(99, 1, 2);
  Expect.equals(99, dt4.year);
  Expect.equals(1, dt4.month);
  Expect.equals(2, dt4.day);
  Expect.equals(0, dt4.hour);
  Expect.equals(0, dt4.minute);
  Expect.equals(0, dt4.second);
  Expect.equals(0, dt4.millisecond);
  Expect.equals(0, dt4.microsecond);
  Expect.isFalse(dt4.isUtc);
  var dt5 = new DateTime.utc(99, 1, 2);
  Expect.equals(99, dt5.year);
  Expect.equals(1, dt5.month);
  Expect.equals(2, dt5.day);
  Expect.equals(0, dt5.hour);
  Expect.equals(0, dt5.minute);
  Expect.equals(0, dt5.second);
  Expect.equals(0, dt5.millisecond);
  Expect.equals(0, dt5.microsecond);
  Expect.isTrue(dt5.isUtc);
  var dt6 = new DateTime(2012, 2, 27, 13, 27, 0);
  Expect.equals(2012, dt6.year);
  Expect.equals(2, dt6.month);
  Expect.equals(27, dt6.day);
  Expect.equals(13, dt6.hour);
  Expect.equals(27, dt6.minute);
  Expect.equals(0, dt6.second);
  Expect.equals(0, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  Expect.isFalse(dt6.isUtc);
  var dt7 = new DateTime.utc(2012, 2, 27, 13, 27, 0);
  Expect.equals(2012, dt7.year);
  Expect.equals(2, dt7.month);
  Expect.equals(27, dt7.day);
  Expect.equals(13, dt7.hour);
  Expect.equals(27, dt7.minute);
  Expect.equals(0, dt7.second);
  Expect.equals(0, dt7.millisecond);
  Expect.equals(0, dt7.microsecond);
  Expect.isTrue(dt7.isUtc);
}

void testChangeTimeZone() {
  var dt1 = new DateTime.fromMillisecondsSinceEpoch(1305140315000);
  var dt2 = dt1.toUtc();
  Expect.equals(dt1.millisecondsSinceEpoch, dt2.millisecondsSinceEpoch);
  var dt3 = new DateTime.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
  Expect.equals(dt1.millisecondsSinceEpoch, dt3.millisecondsSinceEpoch);
  Expect.equals(dt2.year, dt3.year);
  Expect.equals(dt2.month, dt3.month);
  Expect.equals(dt2.day, dt3.day);
  Expect.equals(dt2.hour, dt3.hour);
  Expect.equals(dt2.minute, dt3.minute);
  Expect.equals(dt2.second, dt3.second);
  Expect.equals(dt2.millisecond, dt3.millisecond);
  Expect.equals(dt2.microsecond, dt3.microsecond);
  var dt4 = dt3.toLocal();
  Expect.equals(dt1.year, dt4.year);
  Expect.equals(dt1.month, dt4.month);
  Expect.equals(dt1.day, dt4.day);
  Expect.equals(dt1.hour, dt4.hour);
  Expect.equals(dt1.minute, dt4.minute);
  Expect.equals(dt1.second, dt4.second);
  Expect.equals(dt1.millisecond, dt4.millisecond);
  Expect.equals(dt1.microsecond, dt4.microsecond);
}

void testSubAdd() {
  var dt1 = new DateTime.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
  var dt2 = dt1.add(
      new Duration(milliseconds: 3 * Duration.MILLISECONDS_PER_SECOND + 5));
  Expect.equals(dt1.year, dt2.year);
  Expect.equals(dt1.month, dt2.month);
  Expect.equals(dt1.day, dt2.day);
  Expect.equals(dt1.hour, dt2.hour);
  Expect.equals(dt1.minute, dt2.minute);
  Expect.equals(dt1.second + 3, dt2.second);
  Expect.equals(dt1.millisecond + 5, dt2.millisecond);
  Expect.equals(dt1.microsecond, dt2.microsecond);
  var dt3 = dt2.subtract(
      new Duration(milliseconds: 3 * Duration.MILLISECONDS_PER_SECOND + 5));
  Expect.equals(true, dt1 == dt3);
  Expect.equals(false, dt1 == dt2);

  if (!supportsMicroseconds) return;

  dt1 = new DateTime.fromMillisecondsSinceEpoch(1305140315000, isUtc: true);
  dt2 = dt1.add(
      new Duration(microseconds: 3 * Duration.MICROSECONDS_PER_SECOND + 5));
  Expect.equals(dt1.year, dt2.year);
  Expect.equals(dt1.month, dt2.month);
  Expect.equals(dt1.day, dt2.day);
  Expect.equals(dt1.hour, dt2.hour);
  Expect.equals(dt1.minute, dt2.minute);
  Expect.equals(dt1.second + 3, dt2.second);
  Expect.equals(dt1.millisecond, dt2.millisecond);
  Expect.equals(dt1.microsecond + 5, dt2.microsecond);
  dt3 = dt2.subtract(
      new Duration(microseconds: 3 * Duration.MICROSECONDS_PER_SECOND + 5));
  Expect.equals(true, dt1 == dt3);
  Expect.equals(false, dt1 == dt2);
}

void testUnderflowAndOverflow() {
  int microsecond = supportsMicroseconds ? 499 : 0;
  final dtBase = new DateTime(2012, 6, 20, 12, 30, 30, 500, microsecond);

  // Millisecond
  print("  >>> Millisecond+");
  var dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, dtBase.second, 1000, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second + 1, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Millisecond-");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, dtBase.second, -1000, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second - 1, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Second
  print("  >>> Second+");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, 60, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute + 1, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Second-");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, -60, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute - 1, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Minute
  print("  >>> Minute+");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour, 60,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour + 1, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Minute-");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour, -60,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour - 1, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Hour
  print("  >>> Hour+");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, 24, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day + 1, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Hour-");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, -24, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day - 1, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Day
  print("  >>> Day+");
  dt = new DateTime(dtBase.year, dtBase.month, 31, dtBase.hour, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month + 1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Day-");
  dt = new DateTime(dtBase.year, dtBase.month, -30, dtBase.hour, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month - 1, dt.month);
  Expect.equals(1, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Month
  print("  >>> Month+");
  dt = new DateTime(dtBase.year, 13, dtBase.day, dtBase.hour, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year + 1, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  print("  >>> Month-");
  dt = new DateTime(dtBase.year, -11, dtBase.day, dtBase.hour, dtBase.minute,
      dtBase.second, dtBase.millisecond, dtBase.microsecond);
  Expect.equals(dtBase.year - 1, dt.year);
  Expect.equals(1, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond, dt.millisecond);
  Expect.equals(dtBase.microsecond, dt.microsecond);

  // Flowing all the way up the chain.
  print("  >>> Flow+");
  var dtBase1 = new DateTime(2012, 12, 31, 23, 59, 59, 999, 000);
  var dtTick = new DateTime(
      dtBase1.year,
      dtBase1.month,
      dtBase1.day,
      dtBase1.hour,
      dtBase1.minute,
      dtBase1.second,
      dtBase1.millisecond + 1,
      dtBase1.microsecond);
  Expect.equals(dtBase1.year + 1, dtTick.year);
  Expect.equals(1, dtTick.month);
  Expect.equals(1, dtTick.day);
  Expect.equals(0, dtTick.hour);
  Expect.equals(0, dtTick.minute);
  Expect.equals(0, dtTick.second);
  Expect.equals(0, dtTick.millisecond);
  Expect.equals(0, dtTick.microsecond);

  print("  >>> Flow-");
  dtBase1 = new DateTime(2012, 1, 1, 0, 0, 0, 0);
  dtTick = new DateTime(
      dtBase1.year,
      dtBase1.month,
      dtBase1.day,
      dtBase1.hour,
      dtBase1.minute,
      dtBase1.second,
      dtBase1.millisecond - 1,
      dtBase1.microsecond);
  Expect.equals(dtBase1.year - 1, dtTick.year);
  Expect.equals(12, dtTick.month);
  Expect.equals(31, dtTick.day);
  Expect.equals(23, dtTick.hour);
  Expect.equals(59, dtTick.minute);
  Expect.equals(59, dtTick.second);
  Expect.equals(999, dtTick.millisecond);
  Expect.equals(0, dtTick.microsecond);

  print("  >>> extra underflow");
  dtTick = new DateTime(dtBase1.year, dtBase1.month, dtBase1.day, -17520,
      dtBase1.minute, dtBase1.second, dtBase1.millisecond, dtBase1.microsecond);
  Expect.equals(dtBase1.year - 2, dtTick.year);
  Expect.equals(dtBase1.month, dtTick.month);
  Expect.equals(dtBase1.day, dtTick.day);
  Expect.equals(dtBase1.hour, dtTick.hour);
  Expect.equals(dtBase1.minute, dtTick.minute);
  Expect.equals(dtBase1.second, dtTick.second);
  Expect.equals(dtBase1.millisecond, dtTick.millisecond);
  Expect.equals(dtBase1.microsecond, dtTick.microsecond);

  if (!supportsMicroseconds) return;

  // Microsecond
  print("  >>> Microsecond+");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, dtBase.second, dtBase.millisecond, 1000);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond + 1, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  print("  >>> Microsecond-");
  dt = new DateTime(dtBase.year, dtBase.month, dtBase.day, dtBase.hour,
      dtBase.minute, dtBase.second, dtBase.millisecond, -1000);
  Expect.equals(dtBase.year, dt.year);
  Expect.equals(dtBase.month, dt.month);
  Expect.equals(dtBase.day, dt.day);
  Expect.equals(dtBase.hour, dt.hour);
  Expect.equals(dtBase.minute, dt.minute);
  Expect.equals(dtBase.second, dt.second);
  Expect.equals(dtBase.millisecond - 1, dt.millisecond);
  Expect.equals(0, dt.microsecond);

  // Flowing all the way up the chain.
  print("  >>> Flow+ 2");
  dtBase1 = new DateTime(2012, 12, 31, 23, 59, 59, 999, 999);
  dtTick = new DateTime(
      dtBase1.year,
      dtBase1.month,
      dtBase1.day,
      dtBase1.hour,
      dtBase1.minute,
      dtBase1.second,
      dtBase1.millisecond,
      dtBase1.microsecond + 1);
  Expect.equals(dtBase1.year + 1, dtTick.year);
  Expect.equals(1, dtTick.month);
  Expect.equals(1, dtTick.day);
  Expect.equals(0, dtTick.hour);
  Expect.equals(0, dtTick.minute);
  Expect.equals(0, dtTick.second);
  Expect.equals(0, dtTick.millisecond);
  Expect.equals(0, dtTick.microsecond);

  print("  >>> Flow- 2");
  dtBase1 = new DateTime(2012, 1, 1, 0, 0, 0, 0, 0);
  dtTick = new DateTime(
      dtBase1.year,
      dtBase1.month,
      dtBase1.day,
      dtBase1.hour,
      dtBase1.minute,
      dtBase1.second,
      dtBase1.millisecond,
      dtBase1.microsecond - 1);
  Expect.equals(dtBase1.year - 1, dtTick.year);
  Expect.equals(12, dtTick.month);
  Expect.equals(31, dtTick.day);
  Expect.equals(23, dtTick.hour);
  Expect.equals(59, dtTick.minute);
  Expect.equals(59, dtTick.second);
  Expect.equals(999, dtTick.millisecond);
  Expect.equals(999, dtTick.microsecond);
}

void testDateStrings() {
  // TODO(floitsch): Clean up the DateTime API that deals with strings.
  var dt1 = DateTime.parse("2011-05-11 18:58:35Z");
  Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
  Expect.isTrue(dt1.isUtc);
  dt1 = DateTime.parse("20110511 18:58:35z");
  Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
  Expect.isTrue(dt1.isUtc);
  dt1 = DateTime.parse("+20110511 18:58:35z");
  Expect.equals(1305140315000, dt1.millisecondsSinceEpoch);
  Expect.isTrue(dt1.isUtc);
  var str = dt1.toString();
  var dt2 = DateTime.parse(str);
  Expect.equals(true, dt1 == dt2);
  var dt3 = dt1.toUtc();
  str = dt3.toString();
  Expect.equals("2011-05-11 18:58:35.000Z", str);
  var dt4 = DateTime.parse("-1234-01-01 00:00:00Z");
  Expect.equals(-1234, dt4.year);
  Expect.equals(1, dt4.month);
  Expect.equals(1, dt4.day);
  Expect.equals(0, dt4.hour);
  Expect.equals(0, dt4.minute);
  Expect.equals(0, dt4.second);
  Expect.equals(0, dt4.millisecond);
  Expect.equals(0, dt4.microsecond);
  Expect.isTrue(dt4.isUtc);
  var dt5 = DateTime.parse("0099-01-02");
  Expect.equals(99, dt5.year);
  Expect.equals(1, dt5.month);
  Expect.equals(2, dt5.day);
  Expect.equals(0, dt5.hour);
  Expect.equals(0, dt5.minute);
  Expect.equals(0, dt5.second);
  Expect.equals(0, dt5.millisecond);
  Expect.equals(0, dt5.microsecond);
  Expect.isFalse(dt5.isUtc);
  var dt6 = DateTime.parse("2012-01-01 00:00:10.012");
  Expect.equals(12, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  dt6 = DateTime.parse("2012-01-01 00:00:10.003");
  Expect.equals(3, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  dt6 = DateTime.parse("2012-01-01 00:00:10.5");
  Expect.equals(500, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  dt6 = DateTime.parse("2012-01-01 00:00:10.003Z");
  Expect.equals(3, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  dt6 = DateTime.parse("2012-01-01 00:00:10.5z");
  Expect.equals(500, dt6.millisecond);
  Expect.equals(0, dt6.microsecond);
  var dt7 = DateTime.parse("2011-05-11T18:58:35Z");
  Expect.equals(1305140315000, dt7.millisecondsSinceEpoch);
  var dt8 = DateTime.parse("-1234-01-01T00:00:00Z");
  Expect.equals(-1234, dt8.year);
  Expect.equals(1, dt8.month);
  Expect.equals(1, dt8.day);
  Expect.equals(0, dt8.hour);
  Expect.equals(0, dt8.minute);
  Expect.equals(0, dt8.second);
  Expect.equals(0, dt8.millisecond);
  Expect.equals(0, dt8.microsecond);
  Expect.isTrue(dt8.isUtc);
  var dt9 = DateTime.parse("-1234-01-01T00:00:00");
  Expect.equals(-1234, dt9.year);
  Expect.equals(1, dt9.month);
  Expect.equals(1, dt9.day);
  Expect.equals(0, dt9.hour);
  Expect.equals(0, dt9.minute);
  Expect.equals(0, dt9.second);
  Expect.equals(0, dt9.millisecond);
  Expect.equals(0, dt9.microsecond);
  Expect.isFalse(dt9.isUtc);
  var dt10 = DateTime.parse("-12340101");
  Expect.equals(-1234, dt10.year);
  Expect.equals(1, dt10.month);
  Expect.equals(1, dt10.day);
  Expect.equals(0, dt10.hour);
  Expect.equals(0, dt10.minute);
  Expect.equals(0, dt10.second);
  Expect.equals(0, dt10.millisecond);
  Expect.equals(0, dt10.microsecond);
  Expect.isFalse(dt10.isUtc);
  dt1 = DateTime.parse("2012-02-27 13:27:00");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(13, dt1.hour);
  Expect.equals(27, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("2012-02-27 13:27:00.423z");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(13, dt1.hour);
  Expect.equals(27, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(423, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("20120227 13:27:00");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(13, dt1.hour);
  Expect.equals(27, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("20120227T132700");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(13, dt1.hour);
  Expect.equals(27, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("20120227");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(0, dt1.hour);
  Expect.equals(0, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("2012-02-27T14Z");
  Expect.equals(2012, dt1.year);
  Expect.equals(2, dt1.month);
  Expect.equals(27, dt1.day);
  Expect.equals(14, dt1.hour);
  Expect.equals(0, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("-123450101 00:00:00 Z");
  Expect.equals(-12345, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(1, dt1.day);
  Expect.equals(0, dt1.hour);
  Expect.equals(0, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(0, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("1999-01-02 23:59:59.99951");
  if (supportsMicroseconds) {
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(2, dt1.day);
    Expect.equals(23, dt1.hour);
    Expect.equals(59, dt1.minute);
    Expect.equals(59, dt1.second);
    Expect.equals(999, dt1.millisecond);
    Expect.equals(510, dt1.microsecond);
  } else {
    // We only support millisecond. If the user supplies more data (the "51"
    // here), we round.
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(3, dt1.day);
    Expect.equals(0, dt1.hour);
    Expect.equals(0, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(0, dt1.microsecond);
  }
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("1999-01-02 23:58:59.99951Z");
  if (supportsMicroseconds) {
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(2, dt1.day);
    Expect.equals(23, dt1.hour);
    Expect.equals(58, dt1.minute);
    Expect.equals(59, dt1.second);
    Expect.equals(999, dt1.millisecond);
    Expect.equals(510, dt1.microsecond);
  } else {
    Expect.equals(1999, dt1.year);
    Expect.equals(1, dt1.month);
    Expect.equals(2, dt1.day);
    Expect.equals(23, dt1.hour);
    Expect.equals(59, dt1.minute);
    Expect.equals(0, dt1.second);
    Expect.equals(0, dt1.millisecond);
    Expect.equals(0, dt1.microsecond);
  }
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009Z");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-00");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-0000");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-02");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(11, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009+0200");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(7, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009+1200");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(8, dt1.day);
  Expect.equals(21, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-1200");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(21, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-0230");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(11, dt1.hour);
  Expect.equals(39, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009-2134");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(10, dt1.day);
  Expect.equals(6, dt1.hour);
  Expect.equals(43, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);

  Expect.throws(() => DateTime.parse("bad"), (e) => e is FormatException);
  var bad_year =
      1970 + (_MAX_MILLISECONDS ~/ (1000 * 60 * 60 * 24 * 365.2425)) + 1;
  Expect.throws(() => DateTime.parse(bad_year.toString() + "-01-01"),
      (e) => e is FormatException);
  // The last valid time; should not throw.
  dt1 = DateTime.parse("275760-09-13T00:00:00.000Z");
  Expect.throws(() => DateTime.parse("275760-09-14T00:00:00.000Z"),
      (e) => e is FormatException);
  Expect.throws(() => DateTime.parse("275760-09-13T00:00:00.001Z"),
      (e) => e is FormatException);
  if (supportsMicroseconds) {
    Expect.throws(() => DateTime.parse("275760-09-13T00:00:00.000001Z"),
        (e) => e is FormatException);
  } else {
    dt1 = DateTime.parse("275760-09-13T00:00:00.000001Z");
  }

  // first valid time; should not throw.
  dt1 = DateTime.parse("-271821-04-20T00:00:00.000Z");
  Expect.throws(() => DateTime.parse("-271821-04-19T23:59:59.999Z"),
      (e) => e is FormatException);

  if (supportsMicroseconds) {
    Expect.throws(() => DateTime.parse("-271821-04-19T23:59:59.999999Z"),
        (e) => e is FormatException);
  }
}

void testWeekday() {
  // 2011-10-06 is Summertime.
  var d = new DateTime(2011, 10, 6, 0, 45, 37, 0);
  Expect.equals(DateTime.THURSDAY, d.weekday);
  d = new DateTime.utc(2011, 10, 6, 0, 45, 37, 0);
  Expect.equals(DateTime.THURSDAY, d.weekday);
  d = new DateTime(2011, 10, 5, 23, 45, 37, 0);
  Expect.equals(DateTime.WEDNESDAY, d.weekday);
  d = new DateTime.utc(2011, 10, 5, 23, 45, 37, 0);
  Expect.equals(DateTime.WEDNESDAY, d.weekday);
  // 1970-01-01 is Wintertime.
  d = new DateTime(1970, 1, 1, 0, 0, 0, 1);
  Expect.equals(DateTime.THURSDAY, d.weekday);
  d = new DateTime.utc(1970, 1, 1, 0, 0, 0, 1);
  Expect.equals(DateTime.THURSDAY, d.weekday);
  d = new DateTime.utc(1969, 12, 31, 23, 59, 59, 999);
  Expect.equals(DateTime.WEDNESDAY, d.weekday);
  d = new DateTime(1969, 12, 31, 23, 59, 59, 999);
  Expect.equals(DateTime.WEDNESDAY, d.weekday);
  d = new DateTime(2011, 10, 4, 23, 45, 37, 0);
  Expect.equals(DateTime.TUESDAY, d.weekday);
  d = new DateTime(2011, 10, 3, 23, 45, 37, 0);
  Expect.equals(DateTime.MONDAY, d.weekday);
  d = new DateTime(2011, 10, 2, 23, 45, 37, 0);
  Expect.equals(DateTime.SUNDAY, d.weekday);
  d = new DateTime(2011, 10, 1, 23, 45, 37, 0);
  Expect.equals(DateTime.SATURDAY, d.weekday);
  d = new DateTime(2011, 9, 30, 23, 45, 37, 0);
  Expect.equals(DateTime.FRIDAY, d.weekday);
}

void testToStrings() {
  void test(date, time) {
    {
      // UTC time.
      String source1 = "$date ${time}Z";
      String source2 = "${date}T${time}Z";
      var utcTime1 = DateTime.parse(source1);
      var utcTime2 = DateTime.parse(source2);
      Expect.isTrue(utcTime1.isUtc);
      Expect.equals(utcTime1, utcTime2);
      Expect.equals(source1, utcTime1.toString());
      Expect.equals(source2, utcTime1.toIso8601String());
    }
    {
      // Local time
      String source1 = "$date $time";
      String source2 = "${date}T$time";
      var utcTime1 = DateTime.parse(source1);
      var utcTime2 = DateTime.parse(source2);
      Expect.isFalse(utcTime1.isUtc);
      Expect.equals(utcTime1, utcTime2);
      Expect.equals(source1, utcTime1.toString());
      Expect.equals(source2, utcTime1.toIso8601String());
    }
  }

  test("2000-01-01", "12:00:00.000");
  test("-2000-01-01", "12:00:00.000");
  test("1970-01-01", "00:00:00.000");
  test("1969-12-31", "23:59:59.999");
  test("1969-09-09", "00:09:09.009");

  if (supportsMicroseconds) {
    test("2000-01-01", "12:00:00.000001");
    test("-2000-01-01", "12:00:00.000001");
    test("1970-01-01", "00:00:00.000001");
    test("1969-12-31", "23:59:59.999999");
    test("1969-09-09", "00:09:09.009999");
  }
}

void testIsoString() {
  var d = new DateTime(9999, 1, 1, 23, 59, 59, 999);
  Expect.equals("9999-01-01T23:59:59.999", d.toIso8601String());
  d = new DateTime(-9999, 1, 1, 23, 59, 59, 999);
  Expect.equals("-9999-01-01T23:59:59.999", d.toIso8601String());
  d = new DateTime.utc(9999, 1, 1, 23, 59, 59, 999);
  Expect.equals("9999-01-01T23:59:59.999Z", d.toIso8601String());
  d = new DateTime.utc(-9999, 1, 1, 23, 59, 59, 999);
  Expect.equals("-9999-01-01T23:59:59.999Z", d.toIso8601String());

  d = new DateTime(10000, 1, 1, 23, 59, 59, 999);
  Expect.equals("+010000-01-01T23:59:59.999", d.toIso8601String());
  d = new DateTime(-10000, 1, 1, 23, 59, 59, 999);
  Expect.equals("-010000-01-01T23:59:59.999", d.toIso8601String());
  d = new DateTime.utc(10000, 1, 1, 23, 59, 59, 999);
  Expect.equals("+010000-01-01T23:59:59.999Z", d.toIso8601String());
  d = new DateTime.utc(-10000, 1, 1, 23, 59, 59, 999);
  Expect.equals("-010000-01-01T23:59:59.999Z", d.toIso8601String());

  if (!supportsMicroseconds) return;

  d = new DateTime(9999, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("9999-01-01T23:59:59.999999", d.toIso8601String());
  d = new DateTime(-9999, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("-9999-01-01T23:59:59.999999", d.toIso8601String());
  d = new DateTime.utc(9999, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("9999-01-01T23:59:59.999999Z", d.toIso8601String());
  d = new DateTime.utc(-9999, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("-9999-01-01T23:59:59.999999Z", d.toIso8601String());

  d = new DateTime(10000, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("+010000-01-01T23:59:59.999999", d.toIso8601String());
  d = new DateTime(-10000, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("-010000-01-01T23:59:59.999999", d.toIso8601String());
  d = new DateTime.utc(10000, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("+010000-01-01T23:59:59.999999Z", d.toIso8601String());
  d = new DateTime.utc(-10000, 1, 1, 23, 59, 59, 999, 999);
  Expect.equals("-010000-01-01T23:59:59.999999Z", d.toIso8601String());

  d = new DateTime(9999, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("9999-01-01T23:49:59.989979", d.toIso8601String());
  d = new DateTime(-9999, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("-9999-01-01T23:49:59.989979", d.toIso8601String());
  d = new DateTime.utc(9999, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("9999-01-01T23:49:59.989979Z", d.toIso8601String());
  d = new DateTime.utc(-9999, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("-9999-01-01T23:49:59.989979Z", d.toIso8601String());

  d = new DateTime(10000, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("+010000-01-01T23:49:59.989979", d.toIso8601String());
  d = new DateTime(-10000, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("-010000-01-01T23:49:59.989979", d.toIso8601String());
  d = new DateTime.utc(10000, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("+010000-01-01T23:49:59.989979Z", d.toIso8601String());
  d = new DateTime.utc(-10000, 1, 1, 23, 49, 59, 989, 979);
  Expect.equals("-010000-01-01T23:49:59.989979Z", d.toIso8601String());
}

void main() {
  testNow();
  testMillisecondsSinceEpoch();
  testMicrosecondsSinceEpoch();
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
  testToStrings();
  testIsoString();
}
