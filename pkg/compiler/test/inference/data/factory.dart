// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.generative:[exact=A|powerset={N}{O}{N}]*/
  A.generative();

  factory A.redirect() = B;

  /*member: A.fact:[exact=C|powerset={N}{O}{N}]*/
  factory A.fact() => C();
}

/*member: B.:[exact=B|powerset={N}{O}{N}]*/
class B implements A {}

/*member: C.:[exact=C|powerset={N}{O}{N}]*/
class C implements A {}

/*member: main:[null|powerset={null}]*/
main() {
  createGenerative();
  createRedirecting();
  createFactory();
}

/*member: createGenerative:[exact=A|powerset={N}{O}{N}]*/
createGenerative() => A.generative();

/*member: createRedirecting:[exact=B|powerset={N}{O}{N}]*/
createRedirecting() => A.redirect();

/*member: createFactory:[exact=C|powerset={N}{O}{N}]*/
createFactory() => A.fact();
