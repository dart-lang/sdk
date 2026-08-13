// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the static checks for type annotations on initializing formals.

class C {
  num a;
  C.sameType(num this.a);
  C.subType(int this.a);
  C.superType(dynamic this.a);
  //          ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE
  //                       ^
  // [cfe] The type of parameter 'a', 'dynamic' is not a subtype of the corresponding field's type, 'num'.
  C.unrelatedType(String this.a);
  //              ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE
  //                          ^
  // [cfe] The type of parameter 'a', 'String' is not a subtype of the corresponding field's type, 'num'.
}

main() {
  new C.sameType(3.14);
  new C.subType(42);
  new C.superType([]);
  new C.unrelatedType('String');
}
