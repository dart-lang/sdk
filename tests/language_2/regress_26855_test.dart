// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f0(this.x) {}
//      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
// [cfe] Field formal parameters can only be used in a constructor.

void f1(int g(this.x)) {}
//            ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
// [cfe] Field formal parameters can only be used in a constructor.

void f2(int g(int this.x)) {}
//            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
//                ^
// [cfe] Field formal parameters can only be used in a constructor.

class C {
  C();
  var x;
  void f3(int g(this.x)) {}
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
  // [cfe] Field formal parameters can only be used in a constructor.
  C.f4(int g(this.x));
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
  // [cfe] Field formal parameters can only be used in a constructor.
}

main() {
  f0(null);
  f1(null);
  f2(null);
  C c = new C();
  c.f3(null);
  new C.f4(null);
}
