// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  method1(new Class1a());
  method2(new Class2a());
  method2(new Class2b());
  method3(new Class3a());
  method3(new Class3b());
  method4(new Class4a());
  method4(new Class4b());
}

class Class1a {
  int field1;
}

/*element: method1:FieldGet=[name=Class1a.field1]*/
@pragma('dart2js:noInline')
method1(Class1a c) {
  return c.field1;
}

class Class2a {
  int field2;
}

class Class2b extends Class2a {}

/*element: method2:FieldGet=[name=Class2a.field2]*/
@pragma('dart2js:noInline')
method2(Class2a c) {
  return c.field2;
}

class Class3a {
  int field3;
}

class Class3b implements Class3a {
  int get field3 => 42;
  set field3(int _) {}
}

@pragma('dart2js:noInline')
method3(Class3a c) {
  return c.field3;
}

class Class4a {
  int field4;
}

class Class4b implements Class4a {
  int field4;
}

@pragma('dart2js:noInline')
method4(Class4a c) {
  return c.field4;
}
