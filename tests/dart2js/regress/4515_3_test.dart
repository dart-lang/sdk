// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  a(x) => x + 1;
}

f(p) => p("A");

main() {
  A a = new A();
  a.a(1);
  var v = null;
  try {
    v = f(a.a);
  } catch (e) {}

  Expect.equals(null, v);
}
