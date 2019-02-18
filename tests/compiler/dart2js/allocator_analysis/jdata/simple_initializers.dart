// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new Class1();
  new Class2();
}

const bool const1 = true;

class Class1 {
  /*element: Class1.field0:initial=NullConstant*/
  var field0;

  /*element: Class1.field1:initial=NullConstant*/
  var field1 = null;

  /*element: Class1.field2:initial=BoolConstant(true)*/
  var field2 = true;

  /*element: Class1.field3:initial=BoolConstant(false)*/
  var field3 = false;

  /*element: Class1.field4:initial=IntConstant(0)*/
  var field4 = 0;

  /*element: Class1.field5:initial=IntConstant(1)*/
  var field5 = 1;

  /*element: Class1.field6:initial=StringConstant("")*/
  var field6 = '';

  /*element: Class1.field7:initial=StringConstant("foo")*/
  var field7 = 'foo';

  /*element: Class1.field8:*/
  var field8 = 0.5;

  /*element: Class1.field9:*/
  var field9 = const [];

  /*element: Class1.field10:*/
  var field10 = const {};

  /*element: Class1.field11:*/
  var field11 = #foo;

  /*element: Class1.field12:*/
  var field12 = 2 + 3;

  /*element: Class1.field13:*/
  var field13 = const1;
}

class Class2 {
  /*element: Class2.field1:*/
  var field1;

  /*element: Class2.field2:*/
  var field2;

  /*element: Class2.field3:*/
  var field3;

  /*element: Class2.field4:*/
  var field4;

  /*element: Class2.field5:*/
  var field5;

  /*element: Class2.field6:*/
  var field6;

  /*element: Class2.field7:*/
  var field7;

  /*element: Class2.field8:*/
  var field8;

  /*element: Class2.field9:*/
  var field9;

  /*element: Class2.field10:*/
  var field10;

  /*element: Class2.field11:*/
  var field11;

  /*element: Class2.field12:*/
  var field12;

  /*element: Class2.field13:*/
  var field13;

  Class2()
      : field1 = null,
        field2 = true,
        field3 = false,
        field4 = 0,
        field5 = 1,
        field6 = '',
        field7 = 'foo',
        field8 = 0.5,
        field9 = const [],
        field10 = const {},
        field11 = #foo,
        field12 = 2 + 3,
        field13 = const1;
}
