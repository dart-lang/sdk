// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

// @dart = 2.9

// There is no interface conflict here, but there is a loop in the class
// hierarchy leading to a finite set of implemented types; this loop
// shouldn't cause non-termination.
class A<T> implements B<T> {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'A' is a supertype of itself.

class B<T> implements A<T> {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_INTERFACE_INHERITANCE
// [cfe] 'B' is a supertype of itself.

main() {
  new A();
  new B();
}
