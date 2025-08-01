// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that attempts to promote the type of `this` inside an
// extension method have no effect.

void f(dynamic d) {}

class C {
  int? cProp;
}

extension on C? {
  void testCQuestion() {
    if (this != null) {
      f(this.cProp);
      //     ^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe] Property 'cProp' cannot be accessed on 'C?' because it is potentially null.
      f(cProp);
      //^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe] Property 'cProp' cannot be accessed on 'C?' because it is potentially null.
    }
  }
}

class D extends C {
  int? dProp;
}

extension on C {
  void testC() {
    if (this is D) {
      f(this.dProp);
      //     ^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
      // [cfe] The getter 'dProp' isn't defined for the type 'C'.
      f(dProp);
      //^^^^^
      // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
      // [cfe] The getter 'dProp' isn't defined for the type 'C'.
    }
  }
}

main() {
  C().testCQuestion();
  C().testC();
  D().testCQuestion();
  D().testC();
  (null as C?).testCQuestion();
}
