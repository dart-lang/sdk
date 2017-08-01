// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

check(DateTime expected, String str) {
  DateTime actual = DateTime.parse(str);
  Expect.equals(expected, actual); // Only checks if they are at the same time.
  Expect.equals(expected.isUtc, actual.isUtc);
}

bool get supportsMicroseconds =>
    new DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;

main() {
  check(new DateTime(2012, 02, 27, 13, 27), "2012-02-27 13:27:00");
  if (supportsMicroseconds) {
    check(new DateTime.utc(2012, 02, 27, 13, 27, 0, 123, 456),
        "2012-02-27 13:27:00.123456z");
  } else {
    check(new DateTime.utc(2012, 02, 27, 13, 27, 0, 123, 456),
        "2012-02-27 13:27:00.123z");
  }
  check(new DateTime(2012, 02, 27, 13, 27), "20120227 13:27:00");
  check(new DateTime(2012, 02, 27, 13, 27), "20120227T132700");
  check(new DateTime(2012, 02, 27), "20120227");
  check(new DateTime(2012, 02, 27), "+20120227");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14Z");
  check(new DateTime.utc(-12345, 1, 1), "-123450101 00:00:00 Z");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14+00");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14+0000");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14+00:00");
  check(new DateTime.utc(2012, 02, 27, 14), "2012-02-27T14 +00:00");

  check(new DateTime.utc(2015, 02, 14, 13, 0, 0, 0), "2015-02-15T00:00+11");
  check(new DateTime.utc(2015, 02, 14, 13, 0, 0, 0), "2015-02-15T00:00:00+11");
  check(
      new DateTime.utc(2015, 02, 14, 13, 0, 0, 0), "2015-02-15T00:00:00+11:00");

  if (supportsMicroseconds) {
    check(new DateTime.utc(2015, 02, 15, 0, 0, 0, 500, 500),
        "2015-02-15T00:00:00.500500Z");
    check(new DateTime.utc(2015, 02, 15, 0, 0, 0, 511, 500),
        "2015-02-15T00:00:00.511500Z");
  } else {
    check(new DateTime.utc(2015, 02, 15, 0, 0, 0, 501),
        "2015-02-15T00:00:00.501Z");
    check(new DateTime.utc(2015, 02, 15, 0, 0, 0, 512),
        "2015-02-15T00:00:00.512Z");
  }
}
