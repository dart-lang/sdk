// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  /*member: A.foo:[exact=JSUInt31|powerset={I}{O}{N}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) => 3;
  /*member: A.bar:[exact=MappedListIterable|powerset={N}{O}{N}]*/
  bar(
    /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSPositiveInt|powerset={I}{O}{N}], length: 10, powerset: {I}{G}{M})*/ x,
  ) => x
      . /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSPositiveInt|powerset={I}{O}{N}], length: 10, powerset: {I}{G}{M})*/ map(
        /*[subclass=A|powerset={N}{O}{N}]*/ foo,
      );
}

/*member: B.:[exact=B|powerset={N}{O}{N}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}{O}{N}]*/
  foo(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ b) {
    b.abs();
    return 4;
  }
}

/*member: getA:[subclass=A|powerset={N}{O}{N}]*/
getA(
  bool /*Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
  x,
) => x ? A() : B();

/*member: main:[null|powerset={null}]*/
main() {
  getA(false). /*invoke: [subclass=A|powerset={N}{O}{N}]*/ bar(
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=JSPositiveInt|powerset={I}{O}{N}], length: 10, powerset: {I}{G}{M})*/ generate(
      10,
      (i) => i,
    ),
  );
}
