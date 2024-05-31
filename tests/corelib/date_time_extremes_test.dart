// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime, extreme values.

bool get supportsMicroseconds =>
    DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

// Identical to _maxMillisecondsSinceEpoch in date_time.dart
const int _MAX_MILLISECONDS = 8640000000000000;

void testExtremes() {
  var dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.equals(275760, dt.year);
  Expect.equals(9, dt.month);
  Expect.equals(13, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.equals(-271821, dt.year);
  Expect.equals(4, dt.month);
  Expect.equals(20, dt.day);
  Expect.equals(0, dt.hour);
  Expect.equals(0, dt.minute);
  Expect.equals(0, dt.second);
  Expect.equals(0, dt.millisecond);
  Expect.equals(0, dt.microsecond);
  // Make sure that we can build the extreme dates in local too.
  dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  dt = DateTime(
      dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
  Expect.equals(_MAX_MILLISECONDS, dt.millisecondsSinceEpoch);
  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  dt = DateTime(
      dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
  Expect.equals(-_MAX_MILLISECONDS, dt.millisecondsSinceEpoch);
  Expect.throws(() =>
      DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS + 1, isUtc: true));
  Expect.throws(() =>
      DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS - 1, isUtc: true));
  Expect.throws(
      () => DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS + 1));
  Expect.throws(
      () => DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS - 1));
  dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  Expect.throws(
      () => DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 1));
  dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(
      () => DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 1));
  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  Expect.throws(
      () => DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, -1));
  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(
      () => DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, -1));

  if (!supportsMicroseconds) return;

  /// The nearest value to [base] in the direction [delta]. For native `int`s,
  /// this is just `base + delta`. For web `int`s outside the safe range, the
  /// next value might differ by some power of two.
  int nearest(int base, int delta) {
    for (int factor = 1;; factor *= 2) {
      final next = base + delta * factor;
      print(factor);
      if (next != base) return next;
    }
  }

  dt = DateTime.fromMicrosecondsSinceEpoch(_MAX_MILLISECONDS * 1000);
  dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  Expect.equals(_MAX_MILLISECONDS * 1000, dt.microsecondsSinceEpoch);
  print(-_MAX_MILLISECONDS * 1000);
  dt = DateTime.fromMicrosecondsSinceEpoch(-_MAX_MILLISECONDS * 1000);
  dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  Expect.equals(-_MAX_MILLISECONDS * 1000, dt.microsecondsSinceEpoch);
  Expect.throws(() => DateTime.fromMicrosecondsSinceEpoch(
      nearest(_MAX_MILLISECONDS * 1000, 1),
      isUtc: true));
  Expect.throws(() => DateTime.fromMicrosecondsSinceEpoch(
      nearest(-_MAX_MILLISECONDS * 1000, -1),
      isUtc: true));
  Expect.throws(() => DateTime.fromMicrosecondsSinceEpoch(
      nearest(_MAX_MILLISECONDS * 1000, 1)));
  Expect.throws(() => DateTime.fromMicrosecondsSinceEpoch(
      nearest(-_MAX_MILLISECONDS * 1000, -1)));
  // These should all succeed - stepping into the valid range rather than out:
  DateTime.fromMicrosecondsSinceEpoch(nearest(-_MAX_MILLISECONDS * 1000, 1),
      isUtc: true);
  DateTime.fromMicrosecondsSinceEpoch(nearest(_MAX_MILLISECONDS * 1000, -1),
      isUtc: true);
  DateTime.fromMicrosecondsSinceEpoch(nearest(-_MAX_MILLISECONDS * 1000, 1));
  DateTime.fromMicrosecondsSinceEpoch(nearest(_MAX_MILLISECONDS * 1000, -1));

  dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS);
  Expect.throws(
      () => DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, 1));
  Expect.throws(() => dt.copyWith(microsecond: 1));
  Expect.isTrue(dt.copyWith(microsecond: -1).toString().endsWith('.999999'));

  dt = DateTime.fromMillisecondsSinceEpoch(_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() =>
      DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, 1));
  Expect.throws(() => dt.copyWith(microsecond: 1));
  Expect.isTrue(dt.copyWith(microsecond: -1).toString().endsWith('.999999Z'));

  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS);
  Expect.throws(
      () => DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, -1));
  Expect.throws(() => dt.copyWith(microsecond: -1));
  Expect.isTrue(dt.copyWith(microsecond: 1).toString().endsWith('.000001'));

  dt = DateTime.fromMillisecondsSinceEpoch(-_MAX_MILLISECONDS, isUtc: true);
  Expect.throws(() =>
      DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, 0, 0, -1));
  Expect.throws(() => dt.copyWith(microsecond: -1));
  Expect.isTrue(dt.copyWith(microsecond: 1).toString().endsWith('.000001Z'));

  // Regression test for https://dartbug.com/55438
  dt = DateTime.utc(1969, 12, 31, 23, 59, 59, 999, 999);
  Expect.equals(-1, dt.microsecondsSinceEpoch);
  // The first fix confused millisecondsSinceEpoch and microsecondsSinceEpoch.
  dt = DateTime.utc(1696, 3, 16, 23, 59, 59, 999, 999);
  Expect.equals(-_MAX_MILLISECONDS - 1, dt.microsecondsSinceEpoch);
}

void main() {
  testExtremes();
}
