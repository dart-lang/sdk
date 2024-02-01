// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.generative:[exact=A]*/
  A.generative();

  factory A.redirect() = B;

  /*member: A.fact:[exact=C]*/
  factory A.fact() => C();
}

/*member: B.:[exact=B]*/
class B implements A {}

/*member: C.:[exact=C]*/
class C implements A {}

/*member: main:[null]*/
main() {
  createGenerative();
  createRedirecting();
  createFactory();
}

/*member: createGenerative:[exact=A]*/
createGenerative() => A.generative();

/*member: createRedirecting:[exact=B]*/
createRedirecting() => A.redirect();

/*member: createFactory:[exact=C]*/
createFactory() => A.fact();
