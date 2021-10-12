// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=constructor-tearoffs

// Test the support for errors about type parameters as potentially
// constant expressions or potentially constant type expressions.

class A<X> {
  final Object x1, x2, x3, x4, x5, x6, x7, x8, x9;

  const A()
      : x1 = const [X],
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x2 = const <X>[],
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x3 = const {X},
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x4 = const <X>{},
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x5 = const {X: null},
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x6 = const <X, String?>{},
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x7 = const B<X>(),
        //^
        // [analyzer] unspecified
        // [cfe] unspecified
        x8 = const C(X);
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class B<X> {
  const B();
}

class C {
  const C(Object o);
}

void main() {
  const A<int>();
}
