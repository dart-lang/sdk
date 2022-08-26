// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class I1 {
  int x = 0;
}

class I2 {
  int y = 0;
}

class I3 implements I1, I2 {
  int x = 0;
  int y = 0;
}

class A {
  final I1 a = throw '';
}

class B {
  final I2 a = throw '';
}

class C1 implements A, B {
  I3 get a => throw '';
}

class C2 implements A, B {
  get a => throw '';
}

main() {}
