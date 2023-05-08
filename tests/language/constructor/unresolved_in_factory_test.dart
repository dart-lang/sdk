// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an unresolved method call in a factory is a compile error.

class A {
  factory A() {
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.BODY_MIGHT_COMPLETE_NORMALLY
    // [cfe] A non-null value must be returned since the return type 'A' doesn't allow null.
    foo();
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] Method not found: 'foo'.
  }
}

main() {
  new A();
}
