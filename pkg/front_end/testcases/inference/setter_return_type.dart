// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

class C {
  dynamic set x(int value) {}
}

abstract class I {
  void set x(int value) {}
}

class D extends C implements I {
  set /*@topType=void*/ x(/*@topType=int*/ value) {}
}

main() {}
