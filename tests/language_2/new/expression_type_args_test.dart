// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests showing errors using type-arguments in new expressions:
class A<T> {
  // Can't instantiate type parameter (within static or instance method).
  m1() => new T();
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'T'.
  static m2() => new T();
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'T'.
  //                 ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC

  // OK when used within instance method, but not in static method.
  m3() => new A<T>();
  static m4() => new A<T>();
  //                   ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_PARAMETER_REFERENCED_BY_STATIC
  // [cfe] Type variables can't be used in static members.
}

main() {
  A a = new A();
  a.m1();
  A.m2();
  a.m3();
  A.m4();
}
