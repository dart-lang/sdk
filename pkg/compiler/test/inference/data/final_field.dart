// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.intField:[exact=JSUInt31|powerset=0]*/
  final intField;

  /*member: A.giveUpField1:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  final giveUpField1;

  /*member: A.giveUpField2:Union([exact=A|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
  final giveUpField2;

  /*member: A.fieldParameter:[exact=JSUInt31|powerset=0]*/
  final fieldParameter;

  /*member: A.:[exact=A|powerset=0]*/
  A()
    : intField = 42,
      giveUpField1 = 'foo',
      giveUpField2 = 'foo',
      fieldParameter = 54;

  /*member: A.bar:[exact=A|powerset=0]*/
  A.bar()
    : intField = 54,
      giveUpField1 = 42,
      giveUpField2 = A(),
      fieldParameter = 87;

  /*member: A.foo:[exact=A|powerset=0]*/
  A.foo(this. /*[exact=JSUInt31|powerset=0]*/ fieldParameter)
    : intField = 87,
      giveUpField1 = 42,
      giveUpField2 = 'foo';
}

/*member: main:[null|powerset=1]*/
main() {
  A();
  A.bar();
  A.foo(42);
}
