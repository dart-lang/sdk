// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test Date constructor with optional arguments.

main() {
  var d = new Date(2012);
  Expect.equals(2012, d.year);
  Expect.equals(1, d.month);
  Expect.equals(1, d.day);
  Expect.equals(0, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(2012, day: 28);
  Expect.equals(2012, d.year);
  Expect.equals(1, d.month);
  Expect.equals(28, d.day);
  Expect.equals(0, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(1970, 3);
  Expect.equals(1970, d.year);
  Expect.equals(3, d.month);
  Expect.equals(1, d.day);
  Expect.equals(0, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(1970, 3, hours: 11);
  Expect.equals(1970, d.year);
  Expect.equals(3, d.month);
  Expect.equals(1, d.day);
  Expect.equals(11, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(0, 12, 24, minutes: 12);
  Expect.equals(0, d.year);
  Expect.equals(12, d.month);
  Expect.equals(24, d.day);
  Expect.equals(0, d.hours);
  Expect.equals(12, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(-1, 2, 2, 3, milliseconds: 4);
  Expect.equals(-1, d.year);
  Expect.equals(2, d.month);
  Expect.equals(2, d.day);
  Expect.equals(3, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(0, d.seconds);
  Expect.equals(4, d.milliseconds);

  d = new Date(-1, 2, 2, 3, seconds: 4);
  Expect.equals(-1, d.year);
  Expect.equals(2, d.month);
  Expect.equals(2, d.day);
  Expect.equals(3, d.hours);
  Expect.equals(0, d.minutes);
  Expect.equals(4, d.seconds);
  Expect.equals(0, d.milliseconds);

  d = new Date(2012, month: 5, day: 15,
               hours: 13, minutes: 21, seconds: 33, milliseconds: 12);
  Expect.equals(2012, d.year);
  Expect.equals(5, d.month);
  Expect.equals(15, d.day);
  Expect.equals(13, d.hours);
  Expect.equals(21, d.minutes);
  Expect.equals(33, d.seconds);
  Expect.equals(12, d.milliseconds);
}
