// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*element: A.intField:[exact=JSUInt31]*/
  final intField;

  /*element: A.giveUpField1:Union([exact=JSString], [exact=JSUInt31])*/
  final giveUpField1;

  /*element: A.giveUpField2:Union([exact=A], [exact=JSString])*/
  final giveUpField2;

  /*element: A.fieldParameter:[exact=JSUInt31]*/
  final fieldParameter;

  /*element: A.:[exact=A]*/
  A()
      : intField = 42,
        giveUpField1 = 'foo',
        giveUpField2 = 'foo',
        fieldParameter = 54;

  /*element: A.bar:[exact=A]*/
  A.bar()
      : intField = 54,
        giveUpField1 = 42,
        giveUpField2 = new A(),
        fieldParameter = 87;

  /*element: A.foo:[exact=A]*/
  A.foo(this. /*[exact=JSUInt31]*/ fieldParameter)
      : intField = 87,
        giveUpField1 = 42,
        giveUpField2 = 'foo';
}

/*element: main:[null]*/
main() {
  new A();
  new A.bar();
  new A.foo(42);
}
