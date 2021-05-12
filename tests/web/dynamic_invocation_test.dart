// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C1 {
  int call(int a, int b) => a + b;
}

class C2 {
  int call(int a, int b, int c) => a + b + c;
}

class D {
  dynamic f1 = new C1();
  dynamic f2 = new C2();
}

@pragma('dart2js:noInline')
id(o) => o;

main() {
  dynamic d1 = id(new D());
  Expect.equals(d1.f1(1, 2), 3); //# 01: ok
  Expect.equals(d1.f2(1, 2, 3), 6); //# 02: ok
  D d2 = id(new D());
  Expect.equals(d2.f1(2, 3), 5); //# 03: ok
  Expect.equals(d2.f2(2, 3, 4), 9); //# 04: ok
}
