// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var f = ({a: 3, b: 8}) {
    return a + b;
  };
  Expect.equals(11, f());
  Expect.equals(499, f(a: 3, b: 496));
  Expect.equals(42, f(a: 20, b: 22));
  Expect.equals(99, f(b: 66, a: 33));
}
