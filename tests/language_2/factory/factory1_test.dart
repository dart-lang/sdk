// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing factory generic result types.

class A<T> {
  A() {}
  factory A.factory() {
    return new A<String>(); // //# 00: compile-time error
  }
}

class B<T> extends A<T> {
  B() {}
  factory B.factory() {
    return new B<String>(); // //# 01: compile-time error
  }
}

main() {
  new A<String>.factory();
  new A<int>.factory(); // //# 00: dynamic type error
  new B<String>.factory();
  new B<int>.factory(); // //# 01: dynamic type error
}
