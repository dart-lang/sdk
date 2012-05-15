// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test fromString with 6 digits after the decimal point.

main() {
  // We only support milliseconds. If the user supplies more data (the "51"
  // here), we round.
  // If (eventually) we support more than just milliseconds this test could
  // fail. Please update the test in this case.
  Date dt1 = new Date.fromString("1999-01-02 23:59:59.999519");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(3, dt1.day);
  Expect.equals(0, dt1.hours);
  Expect.equals(0, dt1.minutes);
  Expect.equals(0, dt1.seconds);
  Expect.equals(0, dt1.milliseconds);
  Expect.equals(false, dt1.isUtc());
  dt1 = new Date.fromString("1999-01-02 23:58:59.999519Z");
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(23, dt1.hours);
  Expect.equals(59, dt1.minutes);
  Expect.equals(0, dt1.seconds);
  Expect.equals(0, dt1.milliseconds);
  Expect.equals(true, dt1.isUtc());
  dt1 = new Date.fromString("0009-09-09 09:09:09.009411Z");
  Expect.equals(9, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(9, dt1.day);
  Expect.equals(9, dt1.hours);
  Expect.equals(9, dt1.minutes);
  Expect.equals(9, dt1.seconds);
  Expect.equals(9, dt1.milliseconds);
  Expect.equals(true, dt1.isUtc());
  String svnDate = "2012-03-30T04:28:13.752341Z";
  dt1 = new Date.fromString(svnDate);
  Expect.equals(2012, dt1.year);
  Expect.equals(3, dt1.month);
  Expect.equals(30, dt1.day);
  Expect.equals(4, dt1.hours);
  Expect.equals(28, dt1.minutes);
  Expect.equals(13, dt1.seconds);
  Expect.equals(752, dt1.milliseconds);
  Expect.equals(true, dt1.isUtc());
  
}
