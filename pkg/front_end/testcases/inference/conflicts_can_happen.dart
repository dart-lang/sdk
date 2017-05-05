// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class I1 {
  int x;
}

class I2 extends I1 {
  int y;
}

class A {
  final I1 a = null;
}

class B {
  final I2 a = null;
}

class C1 implements A, B {
  /*error:INVALID_METHOD_OVERRIDE*/ get a => null;
}

// Still ambiguous
class C2 implements B, A {
  /*error:INVALID_METHOD_OVERRIDE*/ get a => null;
}

main() {}
