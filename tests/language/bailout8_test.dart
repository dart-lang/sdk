// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var a;
var b;

bar() {
  a = a == null ? 42 : new Object();
  a += b;
}

foo() {
  a = a == null ? new Object() : 42;
  a--;
}

main() {
  for (int i = 0; i < 10; i++) {
    a = null;
    Expect.throws(foo, (e) => e is NoSuchMethodError);
    a = null;
    Expect.throws(bar, (e) => e is ArgumentError);
  }
}
