// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {}

class B extends A {}

class C extends B {}

abstract class D {
  A foo();
}

abstract class E {
  B foo();
}

abstract class F {
  Object foo();
}

// class G inherits E::foo, since its type is a subtype of the others.  Since
// the kernel's algorithm for resolving inheritance uses the first member found,
// the front end will insert a forwarding stub in class G to ensure that the
// correct type is inherited.
abstract class G extends Object implements D, E, F {}

class H extends G {
  C foo() => new C();
}

G bar() => new H();
// bar().foo resolves to G::foo, which is inherited from E::foo, so its return
// type is B.  Note that the target is annotated as G::foo, since that is the
// forwarding stub.
var /*@topType=B*/ x = bar(). /*@target=G::foo*/ foo();

main() {}
