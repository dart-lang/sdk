// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A implements B {
  void set x(value) {}
}

abstract class B implements C {
  void set x(value);
}

abstract class C {
  void set x(int value);
}

main() {}
