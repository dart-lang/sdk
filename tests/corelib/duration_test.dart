// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Duration d;
  d = new Duration(days: 1);
  Expect.equals(86400000, d.inMilliseconds);
  Expect.equals(86400, d.inSeconds);
  Expect.equals(1440, d.inMinutes);
  Expect.equals(24, d.inHours);
  Expect.equals(1, d.inDays);
  d = const Duration(hours: 1);
  Expect.equals(3600000, d.inMilliseconds);
  Expect.equals(3600, d.inSeconds);
  Expect.equals(60, d.inMinutes);
  Expect.equals(1, d.inHours);
  Expect.equals(0, d.inDays);
  d = new Duration(minutes: 1);
  Expect.equals(60000, d.inMilliseconds);
  Expect.equals(60, d.inSeconds);
  Expect.equals(1, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);
  d = const Duration(seconds: 1);
  Expect.equals(1000, d.inMilliseconds);
  Expect.equals(1, d.inSeconds);
  Expect.equals(0, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);
  d = new Duration(milliseconds: 1);
  Expect.equals(1, d.inMilliseconds);
  Expect.equals(0, d.inSeconds);
  Expect.equals(0, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);

  d = const Duration(seconds: 1, milliseconds: 999);
  Expect.equals(1999, d.inMilliseconds);
  Expect.equals(1, d.inSeconds);
  d = new Duration(minutes: 1, seconds: 59);
  Expect.equals(119, d.inSeconds);
  Expect.equals(1, d.inMinutes);
  d = const Duration(hours: 1, minutes: 59);
  Expect.equals(119, d.inMinutes);
  Expect.equals(1, d.inHours);
  d = new Duration(days: 1, hours:23);
  Expect.equals(47, d.inHours);
  Expect.equals(1, d.inDays);
  d = const Duration(
      days: 0, hours: 23, minutes: 59, seconds: 59, milliseconds: 999);
  Expect.equals(0, d.inDays);

  d = new Duration(days: -1);
  Expect.equals(-86400000, d.inMilliseconds);
  Expect.equals(-86400, d.inSeconds);
  Expect.equals(-1440, d.inMinutes);
  Expect.equals(-24, d.inHours);
  Expect.equals(-1, d.inDays);
  d = const Duration(hours: -1);
  Expect.equals(-3600000, d.inMilliseconds);
  Expect.equals(-3600, d.inSeconds);
  Expect.equals(-60, d.inMinutes);
  Expect.equals(-1, d.inHours);
  Expect.equals(0, d.inDays);
  d = new Duration(minutes: -1);
  Expect.equals(-60000, d.inMilliseconds);
  Expect.equals(-60, d.inSeconds);
  Expect.equals(-1, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);
  d = const Duration(seconds: -1);
  Expect.equals(-1000, d.inMilliseconds);
  Expect.equals(-1, d.inSeconds);
  Expect.equals(0, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);
  d = new Duration(milliseconds: -1);
  Expect.equals(-1, d.inMilliseconds);
  Expect.equals(0, d.inSeconds);
  Expect.equals(0, d.inMinutes);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inDays);

  d = const Duration(days: 1, hours: -24);
  Expect.equals(0, d.inMilliseconds);
  d = new Duration(hours: 1, minutes: -60);
  Expect.equals(0, d.inMilliseconds);
  d = const Duration(minutes: 1, seconds: -60);
  Expect.equals(0, d.inMilliseconds);
  d = new Duration(seconds: 1, milliseconds: -1000);
  Expect.equals(0, d.inMilliseconds);

  d = const Duration(hours: 25);
  Expect.equals(1, d.inDays);
  Expect.equals(25, d.inHours);
  Expect.equals(1500, d.inMinutes);
  Expect.equals(90000, d.inSeconds);
  Expect.equals(90000000, d.inMilliseconds);
  d = new Duration(minutes: 61);
  Expect.equals(0, d.inDays);
  Expect.equals(1, d.inHours);
  Expect.equals(61, d.inMinutes);
  Expect.equals(3660, d.inSeconds);
  Expect.equals(3660000, d.inMilliseconds);
  d = const Duration(seconds: 61);
  Expect.equals(0, d.inDays);
  Expect.equals(0, d.inHours);
  Expect.equals(1, d.inMinutes);
  Expect.equals(61, d.inSeconds);
  Expect.equals(61000, d.inMilliseconds);
  d = new Duration(milliseconds: 1001);
  Expect.equals(0, d.inDays);
  Expect.equals(0, d.inHours);
  Expect.equals(0, d.inMinutes);
  Expect.equals(1, d.inSeconds);
  Expect.equals(1001, d.inMilliseconds);

  var d1 = const Duration(milliseconds: 1000);
  var d2 = const Duration(seconds: 1);
  Expect.identical(d1, d2);

  d1 = new Duration(hours: 1);
  d2 = new Duration(hours: -1);
  d = d1 + d2;
  Expect.equals(0, d.inMilliseconds);
  d = d1 - d2;
  Expect.equals(3600000 * 2, d.inMilliseconds);

  d2 = new Duration(hours: 1);
  d = d1 + d2;
  Expect.equals(3600000 * 2, d.inMilliseconds);
  d = d1 - d2;
  Expect.equals(0, d.inMilliseconds);

  d = d1 * 2;
  Expect.equals(3600000 * 2, d.inMilliseconds);
  d = d1 * -1;
  Expect.equals(-3600000, d.inMilliseconds);
  d = d1 * 0;
  Expect.equals(0, d.inMilliseconds);

  d = d1 ~/ 2;
  Expect.equals(1800000, d.inMilliseconds);
  d = d1 ~/ 3600001;
  Expect.equals(0, d.inMilliseconds);
  d = d1 ~/ -3600001;
  Expect.equals(0, d.inMilliseconds);
  d = d1 ~/ 3599999;
  Expect.equals(1, d.inMilliseconds);
  d = d1 ~/ -3599999;
  Expect.equals(-1, d.inMilliseconds);
  d = d1 ~/ -1;
  Expect.equals(-3600000, d.inMilliseconds);
  d = d1 * 0;
  Expect.equals(0, d.inMilliseconds);
  Expect.throws(() => d1 ~/ 0,
                (e) => e is IntegerDivisionByZeroException);

  d = new Duration(milliseconds: 0);
  Expect.isTrue(d < new Duration(milliseconds: 1));
  Expect.isTrue(d <= new Duration(milliseconds: 1));
  Expect.isTrue(d <= d);
  Expect.isTrue(d > new Duration(milliseconds: -1));
  Expect.isTrue(d >= new Duration(milliseconds: -1));
  Expect.isTrue(d >= d);
}
