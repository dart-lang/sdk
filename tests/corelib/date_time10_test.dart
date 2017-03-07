// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test from copy constructor.

main() {
  // a few tests that show the way the from copy works
  DateTime src = DateTime.parse("1999-01-02 23:59:58.123");
  DateTime dt1 = DateTime.from(src,year:2015, month:9, day: 20);
  Expect.equals(2015, dt1.year);
  Expect.equals(9, dt1.month);
  Expect.equals(20, dt1.day);
  Expect.equals(23, dt1.hour);
  Expect.equals(59, dt1.minute);
  Expect.equals(58, dt1.second);
  Expect.equals(123, dt1.millisecond);
  Expect.equals(false, dt1.isUtc);
  //Check time fields
  dt1 = DateTime.from(src,hour:20, minute:10, second: 5, millisecond: 432);
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(20, dt1.hour);
  Expect.equals(10, dt1.minute);
  Expect.equals(5, dt1.second);
  Expect.equals(432, dt1.millisecond);
  Expect.equals(true, dt1.isUtc);
  //switch Utc field as well
  dt1 = DateTime.from(src,hour:20, minute:10, second: 5, millisecond: 432,isUtc:false);
  Expect.equals(1999, dt1.year);
  Expect.equals(1, dt1.month);
  Expect.equals(2, dt1.day);
  Expect.equals(20, dt1.hour);
  Expect.equals(10, dt1.minute);
  Expect.equals(5, dt1.second);
  Expect.equals(432, dt1.millisecond);
  Expect.equals(false, dt1.isUtc);

}
