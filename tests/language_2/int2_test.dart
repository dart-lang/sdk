// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to throw NoSuchMethod if an
// int did not fit in the SMI range.

import "package:expect/expect.dart";

main() {
  // dart2js knows that this list is int or null.
  var b = [null, 10000000000000000000000000000000000000];

  // Use b[1] twice to ensure dart2js realizes it's the same value
  // after type propagation.

  // dart2js will inline an ArgumentError check on b[a].
  42 + b[1];
  // dart2js will inline a NoSuchMethodError check.
  var c = b[1] & 1;
  Expect.equals(0, c);
}
