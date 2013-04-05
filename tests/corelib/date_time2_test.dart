// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime's hashCode.

main() {
  var d = DateTime.parse("2000-01-01T00:00:00Z");
  var d2 = DateTime.parse("2000-01-01T00:00:01Z");
  // There is no guarantee that the hashcode for these two dates is different,
  // but in the worst case we will have to fix this test.
  // The important test here is, that DateTime .
  Expect.isFalse(d.hashCode == d2.hashCode);
}
