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
  print(a1.b);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'b' isn't defined for the class 'A'.
  print(a1.c);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'c' isn't defined for the class 'A'.
  print(a1.d);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the class 'A'.

  print(a2.a);
  print(a2.b);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'b' isn't defined for the class 'A'.
  print(a2.c);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'c' isn't defined for the class 'A'.
  print(a2.d);
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the class 'A'.

  if (a1 is B && a2 is C) {
    print(a1.a);
    print(a1.b);
    print(a1.c);
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the class 'B'.
    print(a1.d);
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the class 'B'.

    print(a2.a);
    print(a2.b);
    print(a2.c);
    print(a2.d);
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the class 'C'.

    if (a1 is C && a2 is D) {
      print(a1.a);
      print(a1.b);
      print(a1.c);
      print(a1.d);
      //       ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'C'.

      print(a2.a);
      print(a2.b);
      print(a2.c);
      print(a2.d);
      //       ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'C'.
    }
  }

  var o1 = a1 is B && a2 is C
          ? '${a1.a}'
              '${a1.b}'
      '${a1.c}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the class 'B'.
      '${a1.d}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'B'.
              '${a2.a}'
              '${a2.b}'
              '${a2.c}'
      '${a2.d}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'C'.
          : '${a1.a}'
      '${a1.b}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'b' isn't defined for the class 'A'.
      '${a1.c}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the class 'A'.
      '${a1.d}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'A'.
          '${a2.a}'
      '${a2.b}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'b' isn't defined for the class 'A'.
      '${a2.c}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the class 'A'.
      '${a2.d}'
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the class 'A'.
      ;

  if (a2 is C && a1 is B && a1 is C && a2 is B && a2 is D) {
    print(a1.a);
    print(a1.b);
    print(a1.c);
    print(a1.d);
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the class 'C'.

    print(a2.a);
    print(a2.b);
    print(a2.c);
    print(a2.d);
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the class 'C'.
  }
}
