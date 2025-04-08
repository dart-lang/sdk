// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.generative:[exact=A|powerset=0]*/
  A.generative();

  factory A.redirect() = B;

  /*member: A.fact:[exact=C|powerset=0]*/
  factory A.fact() => C();
}

/*member: B.:[exact=B|powerset=0]*/
class B implements A {}

/*member: C.:[exact=C|powerset=0]*/
class C implements A {}

/*member: main:[null|powerset=1]*/
main() {
  createGenerative();
  createRedirecting();
  createFactory();
}

/*member: createGenerative:[exact=A|powerset=0]*/
createGenerative() => A.generative();

/*member: createRedirecting:[exact=B|powerset=0]*/
createRedirecting() => A.redirect();

/*member: createFactory:[exact=C|powerset=0]*/
createFactory() => A.fact();
