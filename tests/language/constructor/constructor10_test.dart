// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the implicit super call for synthetic constructors are checked.

class A {
  final x;
  A(this.x);
}

class B extends A {
//    ^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  /*
  B() : super(null);
  */
}

// ==========

class Y extends A {
//    ^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  /*
  Y() : super(null);
  */
}

class Z extends Y {
  Z() : super();
}

// ==============

class G extends A {
//    ^
// [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
// [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
  /*
  G() : super(null);
  */
}

class H extends G {}

main() {
  new B().x;
  new Z().x;
  new H().x;
}
