// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check fails because const class extends from non const class.

class Base {
  Base() {}
}

class Sub extends Base {
  const Sub(a) : a_ = a;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
  // [cfe] A constant constructor can't call a non-constant super constructor.
  final a_;
}

main() {
  Sub(0);
}
