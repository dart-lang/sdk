// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: _field4:params=0*/
_field4() => 4;

class Class1 {
  /*element: Class1.field1:elided*/
  var field1 = 0;

  /*element: Class1.field2:emitted*/
  @pragma('dart2js:noElision')
  var field2 = 1;

  /*element: Class1.field3:elided,get=simple*/
  var field3 = 2;

  /*element: Class1.field4:elided*/
  var field4 = _field4;
}

/*element: method1:params=1*/
@pragma('dart2js:noInline')
method1(Class1 c) {
  return c.field1;
}

/*element: method2:access=[field2],params=1*/
@pragma('dart2js:noInline')
method2(Class1 c) {
  return c.field2;
}

class Class2 {
  /*element: Class2.field3:elided,get=simple*/
  final field3 = 3;
}

/*element: method3:calls=[get$field3(0)],params=1*/
@pragma('dart2js:noInline')
method3(c) {
  return c.field3;
}

class Class3 extends Class1 {
  /*element: Class3.method4:params=0*/
  @pragma('dart2js:noInline')
  method4() {
    return super.field1;
  }
}

class Class4 extends Class1 {
  /*element: Class4.method5:calls=[_field4(0)],params=0*/
  @pragma('dart2js:noInline')
  method5() {
    return super.field4();
  }
}

/*element: method6:access=[toString],params=1*/
@pragma('dart2js:noInline')
method6(Class1 c) {
  return c.field1;
}

/*element: method7:access=[toString],calls=[_field4(0)],params=1*/
@pragma('dart2js:noInline')
method7(Class1 c) {
  return c.field4();
}

/*element: main:calls=*,params=0*/
main() {
  Expect.equals(0, method1(new Class1()));
  Expect.equals(1, method2(new Class1()));
  Expect.equals(2, method3(new Class1()));
  Expect.equals(3, method3(new Class2()));
  Expect.equals(0, new Class3().method4());
  Expect.equals(4, new Class4().method5());
  Expect.equals(0, method6(new Class1()));
  Expect.throws(/*calls=[method6(1)],params=0*/ () => method6(null));
  Expect.equals(4, method7(new Class1()));
  Expect.throws(/*calls=[method7(1)],params=0*/ () => method7(null));
}
