// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

dynamic f() => null;

abstract class A {
  static int get x => 0;
}

// Even though B extends A, A.x and B.x are unrelated because they're static.
// So B.x doesn't inherit A.x's type.

class B extends A {
  static var /*@topType=dynamic*/ x = f();
}

// Similar with C.x.  It is not even eligible for inference since it's static
// and has no initializer.

class C extends A {
  static var x;
}

main() {}
