// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the implicit super call for synthetic constructors are checked.

import "package:expect/expect.dart";

class A {
  final x;
  A([this.x = 499]);
}

class B extends A {}

// ==========

class X {
  final x;
  X([this.x = 42]);
}

class Y extends X {}

class Z extends Y {
  Z() : super();
}

// ==============

class F {
  final x;
  F([this.x = 99]);
}

class G extends F {}

class H extends G {}

main() {
  Expect.equals(499, new B().x);
  Expect.equals(42, new Z().x);
  Expect.equals(99, new H().x);
}
