// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  /*member: A.foo:[exact=JSUInt31|powerset={I}{O}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ a) => 3;
  /*member: A.bar:[exact=MappedListIterable|powerset={N}{O}]*/
  bar(
    /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 10, powerset: {I}{G})*/ x,
  ) => x
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 10, powerset: {I}{G})*/ map(
        /*[subclass=A|powerset={N}{O}]*/ foo,
      );
}

/*member: B.:[exact=B|powerset={N}{O}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}{O}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ b) {
    b.abs();
    return 4;
  }
}

/*member: getA:[subclass=A|powerset={N}{O}]*/
getA(
  bool /*Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
  x,
) => x ? A() : B();

/*member: main:[null|powerset={null}]*/
main() {
  getA(false). /*invoke: [subclass=A|powerset={N}{O}]*/ bar(
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 10, powerset: {I}{G})*/ generate(
      10,
      (i) => i,
    ),
  );
}
