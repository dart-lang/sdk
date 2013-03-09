// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

check(DateTime expected, String str) {
  DateTime actual = DateTime.parse(str);
  Expect.equals(expected, actual);  // Only checks if they are at the same time.
  Expect.equals(expected.isUtc, actual.isUtc);
}
main() {
  check(new DateTime(2012, 02, 27, 13, 27), "2012-02-27 13:27:00");
  check(new DateTime.utc(2012, 02, 27, 13, 27, 0, 123),
        "2012-02-27 13:27:00.123456z");
  check(new DateTime(2012, 02, 27, 13, 27), "20120227 13:27:00");
  check(new DateTime(2012, 02, 27, 13, 27), "20120227T132700");
  check(new DateTime(2012, 02, 27), "20120227");
  check(new DateTime(2012, 02, 27), "+20120227");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14Z");
  check(new DateTime.utc(-12345, 1, 1), "-123450101 00:00:00 Z");
}
