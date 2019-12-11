// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime, far away dates.

// TODO(37442): Find far-away dates with milliseconds-since-epoch values that
// are 'web' integers.

bool get supportsMicroseconds =>
    new DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

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

void main() {
  testFarAwayDates();
}
