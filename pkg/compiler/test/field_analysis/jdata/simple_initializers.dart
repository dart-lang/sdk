// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  use1(new Class1());
  use2(new Class2());
}

@pragma('dart2js:noInline')
use(Object o) {
  print(o);
}

@pragma('dart2js:noInline')
use1(Class1 c1) {
  c1.field0a = null;
  c1.field1a = null;
  c1.field2a = null;
  c1.field3a = null;
  c1.field4a = null;
  c1.field5a = null;
  c1.field6a = null;
  c1.field7a = null;
  c1.field8a = null;
  c1.field9a = null;
  c1.field9c = null;
  c1.field10a = null;
  c1.field10c = null;
  c1.field11a = null;
  c1.field12a = null;
  c1.field13a = null;
  use(c1.field0a);
  use(c1.field0b);
  use(c1.field1a);
  use(c1.field1b);
  use(c1.field2a);
  use(c1.field2b);
  use(c1.field3a);
  use(c1.field3b);
  use(c1.field4a);
  use(c1.field4b);
  use(c1.field5a);
  use(c1.field5b);
  use(c1.field6a);
  use(c1.field6b);
  use(c1.field7a);
  use(c1.field7b);
  use(c1.field8a);
  use(c1.field8b);
  use(c1.field9a);
  use(c1.field9b);
  use(c1.field9c);
  use(c1.field9d);
  use(c1.field10a);
  use(c1.field10b);
  use(c1.field10c);
  use(c1.field10d);
  use(c1.field11a);
  use(c1.field11b);
  use(c1.field12a);
  use(c1.field12b);
  use(c1.field13a);
  use(c1.field13b);
}

@pragma('dart2js:noInline')
use2(Class2 c2) {
  c2.field1a = null;
  c2.field2a = null;
  c2.field3a = null;
  c2.field4a = null;
  c2.field5a = null;
  c2.field6a = null;
  c2.field7a = null;
  c2.field8a = null;
  c2.field9a = null;
  c2.field9c = null;
  c2.field10a = null;
  c2.field10c = null;
  c2.field11a = null;
  c2.field12a = null;
  c2.field13a = null;
  use(c2.field1a);
  use(c2.field1b);
  use(c2.field2a);
  use(c2.field2b);
  use(c2.field3a);
  use(c2.field3b);
  use(c2.field4a);
  use(c2.field4b);
  use(c2.field5a);
  use(c2.field5b);
  use(c2.field6a);
  use(c2.field6b);
  use(c2.field7a);
  use(c2.field7b);
  use(c2.field8a);
  use(c2.field8b);
  use(c2.field9a);
  use(c2.field9b);
  use(c2.field9c);
  use(c2.field9d);
  use(c2.field10a);
  use(c2.field10b);
  use(c2.field10c);
  use(c2.field10d);
  use(c2.field11a);
  use(c2.field11b);
  use(c2.field12a);
  use(c2.field12b);
  use(c2.field13a);
  use(c2.field13b);
}

const bool const1 = true;

class Class1 {
  /*member: Class1.field0a:allocator,initial=NullConstant*/
  var field0a;

  /*member: Class1.field0b:constant=NullConstant*/
  var field0b;

  /*member: Class1.field1a:allocator,initial=NullConstant*/
  var field1a = null;

  /*member: Class1.field1b:constant=NullConstant*/
  var field1b = null;

  /*member: Class1.field2a:allocator,initial=BoolConstant(true)*/
  var field2a = true;

  /*member: Class1.field2b:constant=BoolConstant(true)*/
  var field2b = true;

  /*member: Class1.field3a:allocator,initial=BoolConstant(false)*/
  var field3a = false;

  /*member: Class1.field3b:constant=BoolConstant(false)*/
  var field3b = false;

  /*member: Class1.field4a:allocator,initial=IntConstant(0)*/
  var field4a = 0;

  /*member: Class1.field4b:constant=IntConstant(0)*/
  var field4b = 0;

  /*member: Class1.field5a:allocator,initial=IntConstant(1)*/
  var field5a = 1;

  /*member: Class1.field5b:constant=IntConstant(1)*/
  var field5b = 1;

  /*member: Class1.field6a:allocator,initial=StringConstant("")*/
  var field6a = '';

  /*member: Class1.field6b:constant=StringConstant("")*/
  var field6b = '';

  /*member: Class1.field7a:allocator,initial=StringConstant("foo")*/
  var field7a = 'foo';

  /*member: Class1.field7b:constant=StringConstant("foo")*/
  var field7b = 'foo';

  /*member: Class1.field8a:initial=DoubleConstant(0.5)*/
  var field8a = 0.5;

  /*member: Class1.field8b:constant=DoubleConstant(0.5)*/
  var field8b = 0.5;

  /*member: Class1.field9a:initial=ListConstant([])*/
  var field9a = const [];

  /*member: Class1.field9b:constant=ListConstant([])*/
  var field9b = const [];

  /*spec.member: Class1.field9c:initial=ListConstant(<int*>[IntConstant(0), IntConstant(1)])*/
  var field9c = const [0, 1];

  /*spec.member: Class1.field9d:constant=ListConstant(<int*>[IntConstant(0), IntConstant(1), IntConstant(2)])*/
  var field9d = const [0, 1, 2];

  /*member: Class1.field10a:initial=MapConstant({})*/
  var field10a = const {};

  /*member: Class1.field10b:constant=MapConstant({})*/
  var field10b = const {};

  /*spec.member: Class1.field10c:initial=MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), IntConstant(2): IntConstant(3)})*/
  var field10c = const {0: 1, 2: 3};

  /*spec.member: Class1.field10d:constant=MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), IntConstant(2): IntConstant(3), IntConstant(4): IntConstant(5)})*/
  var field10d = const {0: 1, 2: 3, 4: 5};

  /*member: Class1.field11a:initial=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11a = #foo;

  /*member: Class1.field11b:constant=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11b = #foo;

  /*member: Class1.field12a:allocator,initial=IntConstant(5)*/
  var field12a = 2 + 3;

  /*member: Class1.field12b:constant=IntConstant(5)*/
  var field12b = 2 + 3;

  /*member: Class1.field13a:allocator,initial=BoolConstant(true)*/
  var field13a = const1;

  /*member: Class1.field13b:constant=BoolConstant(true)*/
  var field13b = const1;
}

class Class2 {
  /*member: Class2.field1a:allocator,initial=NullConstant*/
  var field1a;

  /*member: Class2.field1b:constant=NullConstant*/
  var field1b;

  /*member: Class2.field2a:allocator,initial=BoolConstant(true)*/
  var field2a;

  /*member: Class2.field2b:constant=BoolConstant(true)*/
  var field2b;

  /*member: Class2.field3a:allocator,initial=BoolConstant(false)*/
  var field3a;

  /*member: Class2.field3b:constant=BoolConstant(false)*/
  var field3b;

  /*member: Class2.field4a:allocator,initial=IntConstant(0)*/
  var field4a;

  /*member: Class2.field4b:constant=IntConstant(0)*/
  var field4b;

  /*member: Class2.field5a:allocator,initial=IntConstant(1)*/
  var field5a;

  /*member: Class2.field5b:constant=IntConstant(1)*/
  var field5b;

  /*member: Class2.field6a:allocator,initial=StringConstant("")*/
  var field6a;

  /*member: Class2.field6b:constant=StringConstant("")*/
  var field6b;

  /*member: Class2.field7a:allocator,initial=StringConstant("foo")*/
  var field7a;

  /*member: Class2.field7b:constant=StringConstant("foo")*/
  var field7b;

  /*member: Class2.field8a:initial=DoubleConstant(0.5)*/
  var field8a;

  /*member: Class2.field8b:constant=DoubleConstant(0.5)*/
  var field8b;

  /*member: Class2.field9a:initial=ListConstant([])*/
  var field9a;

  /*member: Class2.field9b:constant=ListConstant([])*/
  var field9b;

  /*spec.member: Class2.field9c:initial=ListConstant(<int*>[IntConstant(0), IntConstant(1)])*/
  var field9c;

  /*spec.member: Class2.field9d:constant=ListConstant(<int*>[IntConstant(0), IntConstant(1), IntConstant(2)])*/
  var field9d;

  /*member: Class2.field10a:initial=MapConstant({})*/
  var field10a;

  /*member: Class2.field10b:constant=MapConstant({})*/
  var field10b;

  /*spec.member: Class2.field10c:initial=MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), IntConstant(2): IntConstant(3)})*/
  var field10c;

  /*spec.member: Class2.field10d:constant=MapConstant(<int*, int*>{IntConstant(0): IntConstant(1), IntConstant(2): IntConstant(3), IntConstant(4): IntConstant(5)})*/
  var field10d;

  /*member: Class2.field11a:initial=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11a;

  /*member: Class2.field11b:constant=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11b;

  /*member: Class2.field12a:allocator,initial=IntConstant(5)*/
  var field12a;

  /*member: Class2.field12b:constant=IntConstant(5)*/
  var field12b;

  /*member: Class2.field13a:allocator,initial=BoolConstant(true)*/
  var field13a;

  /*member: Class2.field13b:constant=BoolConstant(true)*/
  var field13b;

  Class2()
      : field1a = null,
        field1b = null,
        field2a = true,
        field2b = true,
        field3a = false,
        field3b = false,
        field4a = 0,
        field4b = 0,
        field5a = 1,
        field5b = 1,
        field6a = '',
        field6b = '',
        field7a = 'foo',
        field7b = 'foo',
        field8a = 0.5,
        field8b = 0.5,
        field9a = const [],
        field9b = const [],
        field9c = const [0, 1],
        field9d = const [0, 1, 2],
        field10a = const {},
        field10b = const {},
        field10c = const {0: 1, 2: 3},
        field10d = const {0: 1, 2: 3, 4: 5},
        field11a = #foo,
        field11b = #foo,
        field12a = 2 + 3,
        field12b = 2 + 3,
        field13a = const1,
        field13b = const1;
}
