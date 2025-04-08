// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.foo:[exact=JSUInt31|powerset=0]*/
  foo(/*[null|subclass=Object|powerset=1]*/ a) => 3;
  /*member: A.bar:[exact=MappedListIterable|powerset=0]*/
  bar(
    /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 10, powerset: 0)*/ x,
  ) => x
      . /*invoke: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 10, powerset: 0)*/ map(
        /*[subclass=A|powerset=0]*/ foo,
      );
}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset=0]*/
  foo(/*[null|subclass=Object|powerset=1]*/ b) {
    b.abs();
    return 4;
  }
}

/*member: getA:[subclass=A|powerset=0]*/
getA(bool /*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ x) =>
    x ? A() : B();

/*member: main:[null|powerset=1]*/
main() {
  getA(false). /*invoke: [subclass=A|powerset=0]*/ bar(
    List. /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 10, powerset: 0)*/ generate(
      10,
      (i) => i,
    ),
  );
}
