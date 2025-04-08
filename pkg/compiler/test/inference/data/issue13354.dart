// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 13354.

/*member: bar:[exact=JSUInt31|powerset=0]*/
bar() => 42;

/*member: baz:[subclass=Closure|powerset=0]*/
baz() => bar;

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.foo:[exact=JSUInt31|powerset=0]*/
  foo() => 42;
}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {
  /*member: B.foo:[subclass=Closure|powerset=0]*/
  foo() => super.foo;
}

/*member: main:[null|powerset=1]*/
main() {
  baz();
  B(). /*invoke: [exact=B|powerset=0]*/ foo();
}
