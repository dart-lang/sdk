// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*element: A.generative:[exact=A]*/
  A.generative();

  factory A.redirect() = B;

  /*element: A.fact:[exact=C]*/
  factory A.fact() => new C();
}

/*element: B.:[exact=B]*/
class B implements A {}

/*element: C.:[exact=C]*/
class C implements A {}

/*element: main:[null]*/
main() {
  createGenerative();
  createRedirecting();
  createFactory();
}

/*element: createGenerative:[exact=A]*/
createGenerative() => new A.generative();

/*element: createRedirecting:[exact=B]*/
createRedirecting() => new A.redirect();

/*element: createFactory:[exact=C]*/
createFactory() => new A.fact();
