// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*member: _field4:params=0*/
_field4() => 4;

class Class1 {
  /*member: Class1.field1:elided*/
  var field1 = 0;

  /*member: Class1.field2:emitted*/
  @pragma('dart2js:noElision')
  var field2 = 1;

  /*member: Class1.field3:elided,get=simple*/
  var field3 = 2;

  /*member: Class1.field4:elided*/
  var field4 = _field4;
}

/*member: method1:params=1*/
@pragma('dart2js:noInline')
method1(Class1 c) {
  return c.field1;
}

/*member: method2:access=[field2],params=1*/
@pragma('dart2js:noInline')
method2(Class1 c) {
  return c.field2;
}

class Class2 {
  /*member: Class2.field3:elided,get=simple*/
  final field3 = 3;
}

/*member: method3:calls=[get$field3(0)],params=1*/
@pragma('dart2js:noInline')
method3(c) {
  return c.field3;
}

class Class3 extends Class1 {
  /*member: Class3.method4:params=0*/
  @pragma('dart2js:noInline')
  method4() {
    return super.field1;
  }
}

class Class4 extends Class1 {
  /*member: Class4.method5:calls=[_field4(0)],params=0*/
  @pragma('dart2js:noInline')
  method5() {
    return super.field4();
  }
}

/*member: method6:access=[toString],params=1*/
@pragma('dart2js:noInline')
method6(Class1 c) {
  return c.field1;
}

/*member: method7:access=[toString],calls=[_field4(0)],params=1*/
@pragma('dart2js:noInline')
method7(Class1 c) {
  return c.field4();
}

var field8;

/*member: method8:!access,params=0*/
@pragma('dart2js:noInline')
method8() => field8;

var field9 = 10;

/*member: method9:!access,params=0*/
@pragma('dart2js:noInline')
method9() => field9;

/*member: field10:emitted,lazy*/
var field10 = method9() + 10;

/*member: method10:calls=[$get$field10(0)],params=0*/
@pragma('dart2js:noInline')
method10() => field10;

/*member: main:calls=*,params=0*/
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
  Expect.equals(null, method8());
  Expect.equals(10, method9());
  Expect.equals(20, method10());
}
