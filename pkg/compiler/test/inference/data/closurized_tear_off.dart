// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[exact=A]*/
class A {
  /*member: A.foo:[exact=JSUInt31]*/
  foo(/*[null|subclass=Object]*/ a) => 3;
  /*member: A.bar:[exact=MappedListIterable]*/
  bar(/*Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 10)*/ x) =>
      x. /*invoke: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 10)*/ map(
          /*[subclass=A]*/ foo);
}

/*member: B.:[exact=B]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31]*/
  foo(/*[null|subclass=Object]*/ b) {
    b.abs();
    return 4;
  }
}

/*member: getA:[subclass=A]*/
getA(bool /*Value([exact=JSBool], value: false)*/ x) => x ? A() : B();

/*member: main:[null]*/
main() {
  getA(false). /*invoke: [subclass=A]*/ bar(List
      . /*update: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 10)*/ generate(
          10, (i) => i));
}
