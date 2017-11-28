// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of parameters.

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

void test(A a) {
  print(a.a);
  print(a.b); //# 01: compile-time error
  print(a.c); //# 02: compile-time error
  print(a.d); //# 03: compile-time error

  if (a is B) {
    print(a.a);
    print(a.b);
    print(a.c); //# 04: compile-time error
    print(a.d); //# 05: compile-time error

    if (a is C) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); //# 06: compile-time error
    }

    print(a.a);
    print(a.b);
    print(a.c); //# 07: compile-time error
    print(a.d); //# 08: compile-time error
  }
  if (a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 09: compile-time error

    if (a is B) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); //# 10: compile-time error
    }
    if (a is D) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); //# 11: compile-time error
    }

    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 12: compile-time error
  }

  print(a.a);
  print(a.b); //# 13: compile-time error
  print(a.c); //# 14: compile-time error
  print(a.d); //# 15: compile-time error

  if (a is D) {
    print(a.a);
    print(a.b); //# 16: compile-time error
    print(a.c); //# 17: compile-time error
    print(a.d);
  }

  print(a.a);
  print(a.b); //# 18: compile-time error
  print(a.c); //# 19: compile-time error
  print(a.d); //# 20: compile-time error

  var o1 = a is B
          ? '${a.a}'
              '${a.b}'
      '${a.c}' //# 21: compile-time error
      '${a.d}' //# 22: compile-time error
          : '${a.a}'
      '${a.b}' //# 23: compile-time error
      '${a.c}' //# 24: compile-time error
      '${a.d}' //# 25: compile-time error
      ;

  var o2 = a is C
          ? '${a.a}'
              '${a.b}'
              '${a.c}'
      '${a.d}' //# 26: compile-time error
          : '${a.a}'
      '${a.b}' //# 27: compile-time error
      '${a.c}' //# 28: compile-time error
      '${a.d}' //# 29: compile-time error
      ;

  var o3 = a is D
          ? '${a.a}'
      '${a.b}' //# 30: compile-time error
      '${a.c}' //# 31: compile-time error
              '${a.d}'
          : '${a.a}'
      '${a.b}' //# 32: compile-time error
      '${a.c}' //# 33: compile-time error
      '${a.d}' //# 34: compile-time error
      ;

  if (a is B && a is B) {
    print(a.a);
    print(a.b);
    print(a.c); //# 35: compile-time error
    print(a.d); //# 36: compile-time error
  }
  if (a is B && a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 37: compile-time error
  }
  if (a is C && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 38: compile-time error
  }
  if (a is C && a is D) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 39: compile-time error
  }
  if (a is D && a is C) {
    print(a.a);
    print(a.b); //# 40: compile-time error
    print(a.c); //# 41: compile-time error
    print(a.d);
  }
  if (a is D &&
      a.a == ""
      && a.b == "" // //# 42: compile-time error
      && a.c == "" // //# 43: compile-time error
      &&
      a.d == "") {
    print(a.a);
    print(a.b); //# 44: compile-time error
    print(a.c); //# 45: compile-time error
    print(a.d);
  }
  if (a.a == ""
      && a.b == "" //# 46: compile-time error
      && a.c == "" //# 47: compile-time error
      && a.d == "" //# 48: compile-time error
          &&
          a is B &&
          a.a == "" &&
          a.b == ""
      && a.c == "" //# 49: compile-time error
      && a.d == "" //# 50: compile-time error
          &&
          a is C &&
          a.a == "" &&
          a.b == "" &&
          a.c == ""
      && a.d == "" //# 51: compile-time error
      ) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 52: compile-time error
  }
  if ((a is B)) {
    print(a.a);
    print(a.b);
    print(a.c); //# 54: compile-time error
    print(a.d); //# 55: compile-time error
  }
  if ((a is B && (a) is C) && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); //# 56: compile-time error
  }
}
