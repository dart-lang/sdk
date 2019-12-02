// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Make sure the years in the range of single digits are handled correctly with
// month roll-over. (This tests an edge condition when delegating to
// JavaScript's Date constructor.)

void check(String expected, DateTime actual) {
  Expect.equals(expected, actual.toString());
}

testUtc() {
  check("0099-01-01 00:00:00.000Z", new DateTime.utc(99, 1));
  check("0100-01-01 00:00:00.000Z", new DateTime.utc(99, 1 + 12));
  check("0000-01-01 00:00:00.000Z", new DateTime.utc(0, 1));
  check("-0001-01-01 00:00:00.000Z", new DateTime.utc(0, 1 - 12));

  check("0099-03-02 00:00:00.000Z", new DateTime.utc(99, 2, 30));
  check("0100-03-02 00:00:00.000Z", new DateTime.utc(99, 2 + 12, 30));

  check("0004-03-01 00:00:00.000Z", new DateTime.utc(3, 2 + 12, 30));
  check("0004-03-01 00:00:00.000Z", new DateTime.utc(4, 2, 30));
  check("0004-03-01 00:00:00.000Z", new DateTime.utc(5, 2 - 12, 30));

  check("0005-03-02 00:00:00.000Z", new DateTime.utc(4, 2 + 12, 30));
  check("0005-03-02 00:00:00.000Z", new DateTime.utc(5, 2, 30));
  check("0005-03-02 00:00:00.000Z", new DateTime.utc(6, 2 - 12, 30));
}

testLocal() {
  check("0099-01-01 00:00:00.000", new DateTime(99, 1));
  check("0100-01-01 00:00:00.000", new DateTime(99, 1 + 12));
  check("0000-01-01 00:00:00.000", new DateTime(0, 1));
  check("-0001-01-01 00:00:00.000", new DateTime(0, 1 - 12));

  check("0099-03-02 00:00:00.000", new DateTime(99, 2, 30));
  check("0100-03-02 00:00:00.000", new DateTime(99, 2 + 12, 30));

  check("0004-03-01 00:00:00.000", new DateTime(3, 2 + 12, 30));
  check("0004-03-01 00:00:00.000", new DateTime(4, 2, 30));
  check("0004-03-01 00:00:00.000", new DateTime(5, 2 - 12, 30));

  check("0005-03-02 00:00:00.000", new DateTime(4, 2 + 12, 30));
  check("0005-03-02 00:00:00.000", new DateTime(5, 2, 30));
  check("0005-03-02 00:00:00.000", new DateTime(6, 2 - 12, 30));
}

main() {
  testUtc();
  testLocal();
}
