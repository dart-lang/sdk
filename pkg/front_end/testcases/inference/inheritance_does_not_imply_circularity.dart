// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// I1::x depends on y, which depends on C::x.  Although C::x overrides I1::x, it
// does not depend on it, since its type is already specified.  So there is no
// circularity.

class I1 {
  final /*@topType=int*/ x = y;
}

abstract class I2 {
  num get x;
}

class C extends Object implements I1, I2 {
  int get x => 0;
}

var /*@topType=int*/ y = new C(). /*@target=C::x*/ x;

main() {}
