// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for issue 13354.

/*member: bar:[exact=JSUInt31]*/
bar() => 42;

/*member: baz:[subclass=Closure]*/
baz() => bar;

/*member: A.:[exact=A]*/
class A {
  /*member: A.foo:[exact=JSUInt31]*/
  foo() => 42;
}

/*member: B.:[exact=B]*/
class B extends A {
  /*member: B.foo:[subclass=Closure]*/
  foo() => super.foo;
}

/*member: main:[null]*/
main() {
  baz();
  new B(). /*invoke: [exact=B]*/ foo();
}
