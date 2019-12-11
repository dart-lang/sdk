// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static set foo(int x) {}

  int foo(int x) => x; //# 01: compile-time error
  static int foo(int x) => x; //# 02: compile-time error

  int foo = 3; //# 03: compile-time error
  final int foo = 4; //# 04: compile-time error
  static int foo = 5; //# 05: compile-time error
  static final int foo = 6; //# 06: ok

  int get foo => 7; //# 07: compile-time error
  static int get foo => 8; //# 08: ok

  set foo(int x) {} //# 09: compile-time error
  static set foo(int x) {} //# 10: compile-time error

  C.foo(int x) {} //# 11: compile-time error
  factory C.foo(int x) => null; //# 12: compile-time error
}

main() {}
