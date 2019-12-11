// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Make sure the year 0 is correctly printed.

testUtc() {
  var d = new DateTime.utc(0, 1, 1);
  Expect.equals("0000-01-01 00:00:00.000Z", d.toString());
}

testLocal() {
  var d = new DateTime(0, 1, 1);
  Expect.equals("0000-01-01 00:00:00.000", d.toString());
}

main() {
  testUtc();
  testLocal();
}
