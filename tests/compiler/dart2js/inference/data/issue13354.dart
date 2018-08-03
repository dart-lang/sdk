// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13354.

/*element: bar:[exact=JSUInt31]*/
bar() => 42;

/*element: baz:[subclass=Closure]*/
baz() => bar;

/*element: A.:[exact=A]*/
class A {
  /*element: A.foo:[exact=JSUInt31]*/
  foo() => 42;
}

/*element: B.:[exact=B]*/
class B extends A {
  /*element: B.foo:[subclass=Closure]*/
  foo() => super.foo;
}

/*element: main:[null]*/
main() {
  baz();
  new B(). /*invoke: [exact=B]*/ foo();
}
