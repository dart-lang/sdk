// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that when no constructors are forwarded from the base class
// through a mixin, it is always an error; the mixin does not acquire an
// implicit default constructor.

abstract class Mixin {}

class Base {
  Base(
      {x}        /// 01: compile-time error
      {x}        /// 02: compile-time error
      {x}        /// 03: compile-time error
    );
}

class C extends Base with Mixin {
  C();           /// 02: continued
  C() : super(); /// 03: continued
}

main() {
  new C();
}
