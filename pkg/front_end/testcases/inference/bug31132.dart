// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class B {}

class C extends B {
  var /*@topType=dynamic*/ z;
}

void test(B x) {
  var /*@type=C*/ y = x is C ? /*@promotedType=C*/ x : new C();
  print(y. /*@target=C::z*/ z);
}

main() {}
