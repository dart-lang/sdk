// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test that an unresolved method call in a factory is a compile error.

class A {
  factory A() {
    foo();
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] Method not found: 'foo'.
  }
}

main() {
  new A();
}
