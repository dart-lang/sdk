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
  print(a.b);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'b' isn't defined for the type 'A'.
  print(a.c);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'c' isn't defined for the type 'A'.
  print(a.d);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  if (a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'B'.
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'B'.

    if (a is C) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d);
      //      ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'C'.
    }

    print(a.a);
    print(a.b);
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'B'.
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'B'.
  }
  if (a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.

    if (a is B) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d);
      //      ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'C'.
    }
    if (a is D) {
      print(a.a);
      print(a.b);
      print(a.c);
      print(a.d);
      //      ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'C'.
    }

    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }

  print(a.a);
  print(a.b);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'b' isn't defined for the type 'A'.
  print(a.c);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'c' isn't defined for the type 'A'.
  print(a.d);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  if (a is D) {
    print(a.a);
    print(a.b);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'b' isn't defined for the type 'D'.
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'D'.
    print(a.d);
  }

  print(a.a);
  print(a.b);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'b' isn't defined for the type 'A'.
  print(a.c);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'c' isn't defined for the type 'A'.
  print(a.d);
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  var o1 = a is B
      ? '${a.a}'
            '${a.b}'
            '${a.c}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'c' isn't defined for the type 'B'.
            '${a.d}'
      //         ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'B'.
      : '${a.a}'
            '${a.b}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'b' isn't defined for the type 'A'.
            '${a.c}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'c' isn't defined for the type 'A'.
            '${a.d}';
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  var o2 = a is C
      ? '${a.a}'
            '${a.b}'
            '${a.c}'
            '${a.d}'
      //         ^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'C'.
      : '${a.a}'
            '${a.b}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'b' isn't defined for the type 'A'.
            '${a.c}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'c' isn't defined for the type 'A'.
            '${a.d}';
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  var o3 = a is D
      ? '${a.a}'
            '${a.b}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'b' isn't defined for the type 'D'.
            '${a.c}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'c' isn't defined for the type 'D'.
            '${a.d}'
      : '${a.a}'
            '${a.b}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'b' isn't defined for the type 'A'.
            '${a.c}'
            //   ^
            // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
            // [cfe] The getter 'c' isn't defined for the type 'A'.
            '${a.d}';
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'A'.

  if (a is B && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'B'.
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'B'.
  }
  if (a is B && a is C) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }
  if (a is C && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }
  if (a is C && a is D) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }
  if (a is D && a is C) {
    print(a.a);
    print(a.b);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'b' isn't defined for the type 'D'.
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'D'.
    print(a.d);
  }
  if (a is D &&
      a.a == "" &&
      a.b == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'b' isn't defined for the type 'D'.
      &&
      a.c == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the type 'D'.
      &&
      a.d == "") {
    print(a.a);
    print(a.b);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'b' isn't defined for the type 'D'.
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'D'.
    print(a.d);
  }
  if (a.a == "" &&
      a.b == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'b' isn't defined for the type 'A'.
      &&
      a.c == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the type 'A'.
      &&
      a.d == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'A'.
      &&
      a is B &&
      a.a == "" &&
      a.b == "" &&
      a.c == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'c' isn't defined for the type 'B'.
      &&
      a.d == ""
      //^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'd' isn't defined for the type 'B'.
      &&
      a is C &&
      a.a == "" &&
      a.b == "" &&
      a.c == "" &&
      a.d == ""
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'd' isn't defined for the type 'C'.
  ) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }
  if ((a is B)) {
    print(a.a);
    print(a.b);
    print(a.c);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c' isn't defined for the type 'B'.
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'B'.
  }
  if ((a is B && (a) is C) && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);
    print(a.d);
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'd' isn't defined for the type 'C'.
  }
}
