// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final call = null;
}

class B {
  get call => null;
}

class C {
  set call(x) {}
}

typedef int F(String str);

main() {
  A a = new A();
  B b = new B();
  C c = new C();

  final
      Function
      a2 = a;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'A' can't be assigned to a variable of type 'Function'.

  final
      F
      a3 = a;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'A' can't be assigned to a variable of type 'int Function(String)'.

  final
      Function
      b2 = b;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'B' can't be assigned to a variable of type 'Function'.

  final
      F
      b3 = b;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'B' can't be assigned to a variable of type 'int Function(String)'.

  final
      Function
      c2 = c;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'C' can't be assigned to a variable of type 'Function'.

  final
      F
      c3 = c;
      //   ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'C' can't be assigned to a variable of type 'int Function(String)'.

  Expect.throwsTypeError(() {
    Function a4 = a as dynamic;
  });

  Expect.throwsTypeError(() {
    F a5 = a as dynamic;
  });

  Expect.throwsTypeError(() {
    Function b4 = b as dynamic;
  });

  Expect.throwsTypeError(() {
    F b5 = b as dynamic;
  });

  Expect.throwsTypeError(() {
    Function c4 = c as dynamic;
  });

  Expect.throwsTypeError(() {
    F c5 = c as dynamic;
  });
}
