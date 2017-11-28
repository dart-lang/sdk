// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the static checks for type annotations on initializing formals.

class C {
  num a;
  C.sameType(num this.a);
  C.subType(int this.a);
  C.superType(dynamic this.a); //# 01: compile-time error
  C.unrelatedType(String this.a); //# 02: compile-time error
}

main() {
  new C.sameType(3.14);
  new C.subType(42);
  new C.superType([]); //# 01: continued
  new C.unrelatedType('String'); //# 02: continued
}
