// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests showing errors using type-arguments in new expressions:
class A<T> {
  // Can't intantiate type parameter (within static or instance method).
  m1() => new T();
  static m2() => new T();

  // OK when used within instance method, but not in static method.
  m3() => new A<T>();
  static m4() => new A<T>();
}

main() {
  A a = new A();
  a.m1(); /// 00: compile-time error
  A.m2(); /// 01: compile-time error
  a.m3();
  A.m4(); /// 02: compile-time error
}
