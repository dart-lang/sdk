// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test DateTime constructor with optional arguments.

main() {
  var d = new DateTime(2012);
  Expect.equals(2012, d.year);
  Expect.equals(1, d.month);
  Expect.equals(1, d.day);
  Expect.equals(0, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(2012, 1, 28);
  Expect.equals(2012, d.year);
  Expect.equals(1, d.month);
  Expect.equals(28, d.day);
  Expect.equals(0, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(1970, 3);
  Expect.equals(1970, d.year);
  Expect.equals(3, d.month);
  Expect.equals(1, d.day);
  Expect.equals(0, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(1970, 3, 1, 11);
  Expect.equals(1970, d.year);
  Expect.equals(3, d.month);
  Expect.equals(1, d.day);
  Expect.equals(11, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(0, 12, 24, 0, 12);
  Expect.equals(0, d.year);
  Expect.equals(12, d.month);
  Expect.equals(24, d.day);
  Expect.equals(0, d.hour);
  Expect.equals(12, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(-1, 2, 2, 3, 0, 0, 4);
  Expect.equals(-1, d.year);
  Expect.equals(2, d.month);
  Expect.equals(2, d.day);
  Expect.equals(3, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(0, d.second);
  Expect.equals(4, d.millisecond);

  d = new DateTime(-1, 2, 2, 3, 0, 4);
  Expect.equals(-1, d.year);
  Expect.equals(2, d.month);
  Expect.equals(2, d.day);
  Expect.equals(3, d.hour);
  Expect.equals(0, d.minute);
  Expect.equals(4, d.second);
  Expect.equals(0, d.millisecond);

  d = new DateTime(2012, 5, 15, 13, 21, 33, 12);
  Expect.equals(2012, d.year);
  Expect.equals(5, d.month);
  Expect.equals(15, d.day);
  Expect.equals(13, d.hour);
  Expect.equals(21, d.minute);
  Expect.equals(33, d.second);
  Expect.equals(12, d.millisecond);
}
