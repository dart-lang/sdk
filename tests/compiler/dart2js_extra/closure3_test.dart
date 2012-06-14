// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var f = fun([a = 3, b = 8]) {
    return a + b;
  };
  Expect.equals(11, f());
  Expect.equals(499, f(3, 496));
  Expect.equals(42, f(20, b: 22));
  Expect.equals(99, f(b: 66, a: 33));
}
