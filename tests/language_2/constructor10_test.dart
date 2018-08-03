// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the implicit super call for synthetic constructors are checked.

class A {
  final x;
  A(this.x);
}

class B extends A {
  /* // //# 00: compile-time error
  B() : super(null);
  */ // //# 00: continued
}

// ==========

class Y extends A {
  /* // //# 01: compile-time error
  Y() : super(null);
  */ // //# 01: continued
}

class Z extends Y {
  Z() : super();
}

// ==============

class G extends A {
  /* // //# 02: compile-time error
  G() : super(null);
  */ // //# 02: continued
}

class H extends G {}

main() {
  new B().x;
  new Z().x;
  new H().x;
}
