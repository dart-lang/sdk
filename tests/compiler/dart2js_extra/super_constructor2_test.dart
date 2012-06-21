// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int x;
  A() : x = 27;
}

class B extends A {
  B();
}

class C extends A {}

main() {
  A a = new B();
  Expect.equals(27, a.x);
  a = new C();
  Expect.equals(27, a.x);
}
