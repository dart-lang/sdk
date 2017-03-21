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
  A a = new E();
  print(a.a);
  print(a.b); /// 01: static type warning
  print(a.c); /// 02: static type warning
  print(a.d); /// 03: static type warning

  if (a is B) {
    print(a.a);
    print(a.b);
    print(a.c); /// 04: static type warning
    print(a.d); /// 05: static type warning

    if (a is C) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); /// 06: static type warning
    }

    print(a.a);
    print(a.b);
    print(a.c); /// 07: static type warning
    print(a.d); /// 08: static type warning
  }
  if (a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); /// 09: static type warning

    if (a is B) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); /// 10: static type warning
    }
    if (a is D) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d); /// 11: static type warning
    }

    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); /// 12: static type warning
  }

  print(a.a);
  print(a.b); /// 13: static type warning
  print(a.c); /// 14: static type warning
  print(a.d); /// 15: static type warning

  if (a is D) {
    print(a.a);
    print(a.b); /// 16: static type warning
    print(a.c); /// 17: static type warning
    print(a.d);
  }

  print(a.a);
  print(a.b); /// 18: static type warning
  print(a.c); /// 19: static type warning
  print(a.d); /// 20: static type warning

  var o1 = a is B  ?
      '${a.a}'
      '${a.b}'
      '${a.c}' /// 21: static type warning
      '${a.d}' /// 22: static type warning
      :
      '${a.a}'
      '${a.b}' /// 23: static type warning
      '${a.c}' /// 24: static type warning
      '${a.d}' /// 25: static type warning
      ;

  var o2 = a is C  ?
      '${a.a}'
      '${a.b}'
      '${a.c}'
      '${a.d}' /// 26: static type warning
      :
      '${a.a}'
      '${a.b}' /// 27: static type warning
      '${a.c}' /// 28: static type warning
      '${a.d}' /// 29: static type warning
      ;

  var o3 = a is D  ?
      '${a.a}'
      '${a.b}' /// 30: static type warning
      '${a.c}' /// 31: static type warning
      '${a.d}'
      :
      '${a.a}'
      '${a.b}' /// 32: static type warning
      '${a.c}' /// 33: static type warning
      '${a.d}' /// 34: static type warning
      ;

  if (a is B && a is B) {
    print(a.a);
    print(a.b);
    print(a.c); /// 35: static type warning
    print(a.d); /// 36: static type warning
  }
  if (a is B && a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); /// 37: static type warning
  }
  if (a is C && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); /// 38: static type warning
  }
  if (a is C && a is D) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d); /// 39: static type warning
  }
  if (a is D && a is C) {
    print(a.a);
    print(a.b); /// 40: static type warning
    print(a.c); /// 41: static type warning
    print(a.d);
  }
}
