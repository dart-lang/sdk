// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  /*element: Class1.field0a:initial=NullConstant*/
  var field0a;

  /*element: Class1.field0b:constant=NullConstant*/
  var field0b;

  /*element: Class1.field1a:initial=NullConstant*/
  var field1a = null;

  /*element: Class1.field1b:constant=NullConstant*/
  var field1b = null;

  /*element: Class1.field2a:initial=BoolConstant(true)*/
  var field2a = true;

  /*element: Class1.field2b:constant=BoolConstant(true)*/
  var field2b = true;

  /*element: Class1.field3a:initial=BoolConstant(false)*/
  var field3a = false;

  /*element: Class1.field3b:constant=BoolConstant(false)*/
  var field3b = false;

  /*element: Class1.field4a:initial=IntConstant(0)*/
  var field4a = 0;

  /*element: Class1.field4b:constant=IntConstant(0)*/
  var field4b = 0;

  /*element: Class1.field5a:initial=IntConstant(1)*/
  var field5a = 1;

  /*element: Class1.field5b:constant=IntConstant(1)*/
  var field5b = 1;

  /*element: Class1.field6a:initial=StringConstant("")*/
  var field6a = '';

  /*element: Class1.field6b:constant=StringConstant("")*/
  var field6b = '';

  /*element: Class1.field7a:initial=StringConstant("foo")*/
  var field7a = 'foo';

  /*element: Class1.field7b:constant=StringConstant("foo")*/
  var field7b = 'foo';

  /*element: Class1.field8a:*/
  var field8a = 0.5;

  /*element: Class1.field8b:constant=DoubleConstant(0.5)*/
  var field8b = 0.5;

  /*element: Class1.field9a:*/
  var field9a = const [];

  /*element: Class1.field9b:constant=ListConstant([])*/
  var field9b = const [];

  /*element: Class1.field9c:*/
  var field9c = const [0, 1];

  /*element: Class1.field9d:constant=ListConstant(<int>[IntConstant(0), IntConstant(1), IntConstant(2)])*/
  var field9d = const [0, 1, 2];

  /*element: Class1.field10a:*/
  var field10a = const {};

  /*element: Class1.field10b:constant=MapConstant({})*/
  var field10b = const {};

  /*element: Class1.field10c:*/
  var field10c = const {0: 1, 2: 3};

  /*element: Class1.field10d:constant=MapConstant(<int, int>{IntConstant(0): IntConstant(1), IntConstant(2): IntConstant(3), IntConstant(4): IntConstant(5)})*/
  var field10d = const {0: 1, 2: 3, 4: 5};

  /*element: Class1.field11a:*/
  var field11a = #foo;

  /*element: Class1.field11b:constant=ConstructedConstant(Symbol(_name=StringConstant("foo")))*/
  var field11b = #foo;

  /*element: Class1.field12a:initial=IntConstant(5)*/
  var field12a = 2 + 3;

  /*element: Class1.field12b:constant=IntConstant(5)*/
  var field12b = 2 + 3;

  /*element: Class1.field13a:initial=BoolConstant(true)*/
  var field13a = const1;

  /*element: Class1.field13b:constant=BoolConstant(true)*/
  var field13b = const1;
}

class Class2 {
  /*element: Class2.field1a:*/
  var field1a;

  /*element: Class2.field1b:*/
  var field1b;

  /*element: Class2.field2a:*/
  var field2a;

  /*element: Class2.field2b:*/
  var field2b;

  /*element: Class2.field3a:*/
  var field3a;

  /*element: Class2.field3b:*/
  var field3b;

  /*element: Class2.field4a:*/
  var field4a;

  /*element: Class2.field4b:*/
  var field4b;

  /*element: Class2.field5a:*/
  var field5a;

  /*element: Class2.field5b:*/
  var field5b;

  /*element: Class2.field6a:*/
  var field6a;

  /*element: Class2.field6b:*/
  var field6b;

  /*element: Class2.field7a:*/
  var field7a;

  /*element: Class2.field7b:*/
  var field7b;

  /*element: Class2.field8a:*/
  var field8a;

  /*element: Class2.field8b:*/
  var field8b;

  /*element: Class2.field9a:*/
  var field9a;

  /*element: Class2.field9b:*/
  var field9b;

  /*element: Class2.field9c:*/
  var field9c;

  /*element: Class2.field9d:*/
  var field9d;

  /*element: Class2.field10a:*/
  var field10a;

  /*element: Class2.field10b:*/
  var field10b;

  /*element: Class2.field10c:*/
  var field10c;

  /*element: Class2.field10d:*/
  var field10d;

  /*element: Class2.field11a:*/
  var field11a;

  /*element: Class2.field11b:*/
  var field11b;

  /*element: Class2.field12a:*/
  var field12a;

  /*element: Class2.field12b:*/
  var field12b;

  /*element: Class2.field13a:*/
  var field13a;

  /*element: Class2.field13b:*/
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
