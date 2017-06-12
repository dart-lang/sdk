// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test fromString with 6 digits after the decimal point.

bool get supportsMicroseconds =>
    new DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

main() {
  if (supportsMicroseconds) {
    testMicrosecondPrecision();
  } else {
    testMillisecondPrecision();
  }
}

void testMillisecondPrecision() {
  // We only support milliseconds. If the user supplies more data (the "51"
  // here), we round.
  DateTime dt1 = DateTime.parse("1999-01-02 23:59:59.999519");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(3, dt1.day);
  Expect.equals(0, dt1.hour);
  Expect.equals(0, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("1999-01-02 23:58:59.999519Z");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(23, dt1.hour);
  Expect.equals(59, dt1.minute);
  Expect.equals(0, dt1.second);
  Expect.equals(0, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009411Z");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  String svnDate = "2012-03-30T04:28:13.752341Z";
  dt1 = DateTime.parse(svnDate);
  Expect.equals(2012, dt1.year);
  Expect.equals(3, dt1.month);
  Expect.equals(30, dt1.day);
  Expect.equals(4, dt1.hour);
  Expect.equals(28, dt1.minute);
  Expect.equals(13, dt1.second);
  Expect.equals(752, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
}

void testMicrosecondPrecision() {
  DateTime dt1 = DateTime.parse("1999-01-02 23:59:59.999519");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(23, dt1.hour);
  Expect.equals(59, dt1.minute);
  Expect.equals(59, dt1.second);
  Expect.equals(999, dt1.millisecond);
  Expect.equals(519, dt1.microsecond);
  Expect.equals(false, dt1.isUtc);
  dt1 = DateTime.parse("1999-01-02 23:58:59.999519Z");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(23, dt1.hour);
  Expect.equals(58, dt1.minute);
  Expect.equals(59, dt1.second);
  Expect.equals(999, dt1.millisecond);
  Expect.equals(519, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
  dt1 = DateTime.parse("0009-09-09 09:09:09.009411Z");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hour);
  Expect.equals(9, dt1.minute);
  Expect.equals(9, dt1.second);
  Expect.equals(9, dt1.millisecond);
  Expect.equals(411, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
  String svnDate = "2012-03-30T04:28:13.752341Z";
  dt1 = DateTime.parse(svnDate);
  Expect.equals(2012, dt1.year);
  Expect.equals(3, dt1.month);
  Expect.equals(30, dt1.day);
  Expect.equals(4, dt1.hour);
  Expect.equals(28, dt1.minute);
  Expect.equals(13, dt1.second);
  Expect.equals(752, dt1.millisecond);
  Expect.equals(341, dt1.microsecond);
  Expect.equals(true, dt1.isUtc);
}
