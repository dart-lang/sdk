// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface A default B {
  A(int x, int y);
}

interface X default B {
  X(int x, int y);
}

class XImpl implements X {
  final int x;
  final int y;
  XImpl(this.x, this.y);
}

// new A invokes B constructor because B implements A.
class B implements A {
  final int x;
  final int y;

  B(this.x, this.y);
  // This factory will never be invoked.
  // TODO(ahe): Is this a compile time error?
  factory A(int a, int b) {  return new B(0, 0); }

  factory X(int a, int b) { return new XImpl(a * 10, b * 10); }
}

main() {
  var a = new A(1, 2);
  // Check that constructor B is invoked and not factory A.
  Expect.equals(1, a.x);
  Expect.equals(2, a.y);

  var x = new X(11, 22);
  // Check that factory is invoked.
  Expect.equals(110, x.x);
  Expect.equals(220, x.y);
}
