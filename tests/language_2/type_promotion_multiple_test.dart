// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of locals.

class A {
  var a = "a";
}

class B extends A {
  var b = "b";
}

class C extends B {
  var c = "c";
}

class D extends A {
  var d = "d";
}

class E implements C, D {
  var a = "";
  var b = "";
  var c = "";
  var d = "";
}

void main() {
  test(new E());
}

void test(A a1) {
  A a2 = new E();
  print(a1.a);
  print(a1.b); //# 01: compile-time error
  print(a1.c); //# 02: compile-time error
  print(a1.d); //# 03: compile-time error

  print(a2.a);
  print(a2.b); //# 04: compile-time error
  print(a2.c); //# 05: compile-time error
  print(a2.d); //# 06: compile-time error

  if (a1 is B && a2 is C) {
    print(a1.a);
    print(a1.b);
    print(a1.c); //# 07: compile-time error
    print(a1.d); //# 08: compile-time error

    print(a2.a);
    print(a2.b);
    print(a2.c);
    print(a2.d); //# 09: compile-time error

    if (a1 is C && a2 is D) {
      print(a1.a);
      print(a1.b);
      print(a1.c);
      print(a1.d); //# 10: compile-time error

      print(a2.a);
      print(a2.b);
      print(a2.c);
      print(a2.d); //# 11: compile-time error
    }
  }

  var o1 = a1 is B && a2 is C
          ? '${a1.a}'
              '${a1.b}'
      '${a1.c}' //# 12: compile-time error
      '${a1.d}' //# 13: compile-time error
              '${a2.a}'
              '${a2.b}'
              '${a2.c}'
      '${a2.d}' //# 14: compile-time error
          : '${a1.a}'
      '${a1.b}' //# 15: compile-time error
      '${a1.c}' //# 16: compile-time error
      '${a1.d}' //# 17: compile-time error
          '${a2.a}'
      '${a2.b}' //# 18: compile-time error
      '${a2.c}' //# 19: compile-time error
      '${a2.d}' //# 20: compile-time error
      ;

  if (a2 is C && a1 is B && a1 is C && a2 is B && a2 is D) {
    print(a1.a);
    print(a1.b);
    print(a1.c);
    print(a1.d); //# 21: compile-time error

    print(a2.a);
    print(a2.b);
    print(a2.c);
    print(a2.d); //# 22: compile-time error
  }
}
