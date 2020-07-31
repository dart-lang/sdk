// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  int f() => null;
}

g(C c) {
  var /*@ type=int* */ x = /*@ type=C* */ /*@target=C.==*/ c
      ?. /*@target=C.f*/ f();
  /*@ type=C* */ /*@target=C.==*/ c?. /*@target=C.f*/ f();
}

main() {}
