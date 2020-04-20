// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime, extreme values.

bool get supportsMicroseconds =>
    new DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

// Identical to _maxMillisecondsSinceEpoch in date_time.dart
const int _MAX_MILLISECONDS = 8640000000000000;

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

void main() {
  testExtremes();
}
