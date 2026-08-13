// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that in dart2js, the constant system matches the runtime
// handling of numbers.

import "package:expect/expect.dart";

main() {
  var x = 10000000000000000;
  var y = [x][0];
  var a = x.runtimeType;
  var b = y.runtimeType;

  Expect.equals(x, y);
  Expect.isTrue(x is int);
  Expect.isTrue(y is int);
  Expect.equals(x.runtimeType, int);
  Expect.equals(y.runtimeType, int);
}
