// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  new Class1();
  new Class2();
}

const bool const1 = true;

class Class1 {
  /*member: Class1.field0:initial=NullConstant*/
  var field0;

  /*member: Class1.field1:initial=NullConstant*/
  var field1 = null;

  /*member: Class1.field2:initial=BoolConstant(true)*/
  var field2 = true;

  /*member: Class1.field3:initial=BoolConstant(false)*/
  var field3 = false;

  /*member: Class1.field4:initial=IntConstant(0)*/
  var field4 = 0;

  /*member: Class1.field5:initial=IntConstant(1)*/
  var field5 = 1;

  /*member: Class1.field6:initial=StringConstant("")*/
  var field6 = '';

  /*member: Class1.field7:initial=StringConstant("foo")*/
  var field7 = 'foo';

  /*member: Class1.field8:initial=DoubleConstant(0.5)*/
  var field8 = 0.5;

  /*member: Class1.field9:initial=ListConstant([])*/
  var field9 = const [];

  /*member: Class1.field10:initial=MapConstant({})*/
  var field10 = const {};

  /*member: Class1.field11:initial=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11 = #foo;

  /*member: Class1.field12:initial=IntConstant(5)*/
  var field12 = 2 + 3;

  /*member: Class1.field13:initial=BoolConstant(true)*/
  var field13 = const1;

  /*member: Class1.field14:initial=BoolConstant(false)*/
  var field14 = const1 is int;
}

class Class2 {
  /*member: Class2.field1:Class2.=NullConstant,initial=NullConstant*/
  var field1;

  /*member: Class2.field2:Class2.=BoolConstant(true),initial=NullConstant*/
  var field2;

  /*member: Class2.field3:Class2.=BoolConstant(false),initial=NullConstant*/
  var field3;

  /*member: Class2.field4:Class2.=IntConstant(0),initial=NullConstant*/
  var field4;

  /*member: Class2.field5:Class2.=IntConstant(1),initial=NullConstant*/
  var field5;

  /*member: Class2.field6:Class2.=StringConstant(""),initial=NullConstant*/
  var field6;

  /*member: Class2.field7:Class2.=StringConstant("foo"),initial=NullConstant*/
  var field7;

  /*member: Class2.field8:Class2.=DoubleConstant(0.5),initial=NullConstant*/
  var field8;

  /*member: Class2.field9:Class2.=ListConstant([]),initial=NullConstant*/
  var field9;

  /*member: Class2.field10:Class2.=MapConstant({}),initial=NullConstant*/
  var field10;

  /*member: Class2.field11:Class2.=ConstructedConstant(Symbol(_name=StringConstant("foo"))),initial=NullConstant*/
  var field11;

  /*member: Class2.field12:Class2.=IntConstant(5),initial=NullConstant*/
  var field12;

  /*member: Class2.field13:Class2.=BoolConstant(true),initial=NullConstant*/
  var field13;

  /*member: Class2.field14:Class2.=BoolConstant(false),initial=NullConstant*/
  var field14;

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
        field13 = const1,
        field14 = const1 is int;
}
