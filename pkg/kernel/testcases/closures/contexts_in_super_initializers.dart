// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to detect that no unnecessary contexts are
// created when a constructor parameter is used in its super initializer.  No
// contexts should be created either in the initializer list or in the
// constructor body.

class X {}

class Y {}

class A {
  X x;
  Y y;
  A(this.x, this.y);
}

class B extends A {
  B(X x, Y y) : super(x, y) {}
}

main() {
  B b = new B(new X(), new Y());
}
