// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {
  int get x;
}

abstract class B {
  int get x;
}

abstract class C {
  num get x;
}

abstract class D {
  double get x;
}

// Superclasses have a consistent type for `x` so inferrence succeeds.
class E extends A implements B {
  var /*@topType=int*/ x;
}

// Superclasses don't have a consistent type for `x` so inference fails, even if
// the types are related.
class F extends A implements C {
  var /*@topType=dynamic*/ x;
}

class G extends A implements D {
  var /*@topType=dynamic*/ x;
}

class H extends C implements D {
  var /*@topType=dynamic*/ x;
}

main() {}
