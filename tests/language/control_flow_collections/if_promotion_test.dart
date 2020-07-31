// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var a = "a";
}

class B extends A {
  var b = "b";
}

class C extends B {
  var c = "c";
}

void main() {
  A a = A();
  print(a.a);
  print(a.b); //# 01: compile-time error

  var list = [
    a.a,
    a.b, //# 02: compile-time error
    a.c, //# 03: compile-time error

    if (a is B) [
      a.a,
      a.b,
      a.c, //# 04: compile-time error

      if (a is C) [
        a.a,
        a.b,
        a.c,
      ] else [
        a.a,
        a.b,
        a.c, //# 05: compile-time error
      ],

      a.a,
      a.b,
      a.c, //# 06: compile-time error
    ] else [
      a.a,
      a.b, //# 07: compile-time error
      a.c, //# 08: compile-time error
    ],

    a.a,
    a.b, //# 09: compile-time error
    a.c, //# 10: compile-time error
  ];
}
