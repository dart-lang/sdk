// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.intField:[exact=JSUInt31|powerset={I}{O}]*/
  final intField;

  /*member: A.giveUpField1:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  final giveUpField1;

  /*member: A.giveUpField2:Union([exact=A|powerset={N}{O}], [exact=JSString|powerset={I}{O}], powerset: {IN}{O})*/
  final giveUpField2;

  /*member: A.fieldParameter:[exact=JSUInt31|powerset={I}{O}]*/
  final fieldParameter;

  /*member: A.:[exact=A|powerset={N}{O}]*/
  A()
    : intField = 42,
      giveUpField1 = 'foo',
      giveUpField2 = 'foo',
      fieldParameter = 54;

  /*member: A.bar:[exact=A|powerset={N}{O}]*/
  A.bar()
    : intField = 54,
      giveUpField1 = 42,
      giveUpField2 = A(),
      fieldParameter = 87;

  /*member: A.foo:[exact=A|powerset={N}{O}]*/
  A.foo(this. /*[exact=JSUInt31|powerset={I}{O}]*/ fieldParameter)
    : intField = 87,
      giveUpField1 = 42,
      giveUpField2 = 'foo';
}

/*member: main:[null|powerset={null}]*/
main() {
  A();
  A.bar();
  A.foo(42);
}
