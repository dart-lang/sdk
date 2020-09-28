// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

_field4() => 4;

class Class1 {
  var field1 = 0;

  @pragma('dart2js:noElision')
  var field2 = 1;

  var field3 = 2;

  var field4 = _field4;
}

@pragma('dart2js:noInline')
method1(Class1 c) {
  return c.field1;
}

@pragma('dart2js:noInline')
method2(Class1 c) {
  return c.field2;
}

class Class2 {
  var field3 = 3;
}

@pragma('dart2js:noInline')
method3(c) {
  return c.field3;
}

class Class3 extends Class1 {
  @pragma('dart2js:noInline')
  method4() {
    return super.field1;
  }
}

class Class4 extends Class1 {
  @pragma('dart2js:noInline')
  method5() {
    return super.field4();
  }
}

@pragma('dart2js:noInline')
method6(Class1? c) {
  return c!.field1;
}

@pragma('dart2js:noInline')
method7(Class1 c) {
  return c.field4();
}

main() {
  Expect.equals(0, method1(new Class1()));
  Expect.equals(1, method2(new Class1()));
  Expect.equals(2, method3(new Class1()));
  Expect.equals(3, method3(new Class2()));
  Expect.equals(0, new Class3().method4());
  Expect.equals(4, new Class4().method5());
  Expect.equals(0, method6(new Class1()));
  Expect.throws(() => method6(null));
  Expect.equals(4, method7(new Class1()));
}
