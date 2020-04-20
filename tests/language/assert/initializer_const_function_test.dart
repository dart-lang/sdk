// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static bool staticTrue() => true;
  final int x;

  // Functions as parameters to assert are no longer supported in Dart 2.0, so
  // this is now a static type error.
  const C.bc01(this.x, y)
      : assert(staticTrue)
      //       ^^^^^^^^^^
      // [analyzer] STATIC_TYPE_WARNING.NON_BOOL_EXPRESSION
      // [cfe] A value of type 'bool Function()' can't be assigned to a variable of type 'bool'.
      ;
}

main() {
  new C.bc01(1, 2);
}
