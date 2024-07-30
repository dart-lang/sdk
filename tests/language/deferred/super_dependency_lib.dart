// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class C extends A {
  foo() {
    super.foo = 3;
//        ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SUPER_MEMBER
// [cfe] Superclass has no setter named 'foo'.
  }
}
