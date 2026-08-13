// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.intField:[exact=JSUInt31|powerset={I}{O}{N}]*/
  final intField;

  /*member: A.giveUpField1:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  final giveUpField1;

  /*member: A.giveUpField2:Union([exact=A|powerset={N}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {IN}{O}{IN})*/
  final giveUpField2;

  /*member: A.fieldParameter:[exact=JSUInt31|powerset={I}{O}{N}]*/
  final fieldParameter;

  /*member: A.:[exact=A|powerset={N}{O}{N}]*/
  A()
    : intField = 42,
      giveUpField1 = 'foo',
      giveUpField2 = 'foo',
      fieldParameter = 54;

  /*member: A.bar:[exact=A|powerset={N}{O}{N}]*/
  A.bar()
    : intField = 54,
      giveUpField1 = 42,
      giveUpField2 = A(),
      fieldParameter = 87;

  /*member: A.foo:[exact=A|powerset={N}{O}{N}]*/
  A.foo(this. /*[exact=JSUInt31|powerset={I}{O}{N}]*/ fieldParameter)
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
