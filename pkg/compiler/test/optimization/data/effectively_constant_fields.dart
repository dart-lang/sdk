// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class1 {
  var field1 = 0;

  @pragma('dart2js:noElision')
  var field2 = 0;

  var field3 = 0;
}

/*member: method1:
 ConstantFieldGet=[name=Class1.field1&value=IntConstant(0)],
 FieldGet=[]
*/
@pragma('dart2js:noInline')
method1(Class1 c) {
  return c.field1;
}

/*member: method2:FieldGet=[name=Class1.field2]*/
@pragma('dart2js:noInline')
method2(Class1 c) {
  return c.field2;
}

class Class2 {
  var field3 = 0;
}

@pragma('dart2js:noInline')
method3(c) {
  return c.field3;
}

int _field4() => 0;

class Class3 {
  int Function() field4 = _field4;
}

/*member: method4:
 ConstantFieldCall=[name=Class3.field4&value=FunctionConstant(_field4)],
 FieldCall=[]
*/
@pragma('dart2js:noInline')
method4(Class3 c) {
  return c.field4();
}

/*member: method6:
 ConstantFieldGet=[name=Class1.field1&value=IntConstant(0)],
 NullCheck=[selector=field1]
*/
@pragma('dart2js:noInline')
method6(Class1 c) {
  return c.field1;
}

/*member: method7:
 ConstantFieldCall=[name=Class3.field4&value=FunctionConstant(_field4)],
 NullCheck=[selector=field4]
*/
@pragma('dart2js:noInline')
method7(Class3 c) {
  return c.field4();
}

main() {
  Expect.equals(0, method1(new Class1()));
  Expect.equals(0, method2(new Class1()));
  Expect.equals(0, method3(new Class1()));
  Expect.equals(0, method3(new Class2()));
  Expect.equals(0, method4(new Class3()));
  Expect.equals(0, method6(new Class1()));
  Expect.throws(() => method6(null));
  Expect.equals(4, method7(new Class3()));
  Expect.throws(() => method7(null));
}
