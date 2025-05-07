// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}]*/
class A {
  /*member: A.foo:[exact=JSUInt31|powerset={I}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}]*/ a) => 3;
  /*member: A.bar:[exact=MappedListIterable|powerset={N}]*/
  bar(
    /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 10, powerset: {I})*/ x,
  ) => x
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 10, powerset: {I})*/ map(
        /*[subclass=A|powerset={N}]*/ foo,
      );
}

/*member: B.:[exact=B|powerset={N}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}]*/ b) {
    b.abs();
    return 4;
  }
}

/*member: getA:[subclass=A|powerset={N}]*/
getA(
  bool /*Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/ x,
) => x ? A() : B();

/*member: main:[null|powerset={null}]*/
main() {
  getA(false). /*invoke: [subclass=A|powerset={N}]*/ bar(
    List. /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 10, powerset: {I})*/ generate(
      10,
      (i) => i,
    ),
  );
}
