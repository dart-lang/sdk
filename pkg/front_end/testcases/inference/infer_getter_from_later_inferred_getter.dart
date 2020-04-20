// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A implements B {
  get x => f();
}

abstract class B implements C {
  get x;
}

abstract class C {
  int get x;
}

dynamic f() => null;

main() {}
