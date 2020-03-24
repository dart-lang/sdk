// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  method1(new Class1a());
  method2(new Class2a());
  method2(new Class2b());
  method3(new Class3a());
  method3(new Class3b());
  method4(new Class4a());
  method4(new Class4b());
  method5(new Class5a());
  method6(new Class6a());
  method6(new Class6b());
}

class Class1a {
  @pragma('dart2js:noElision')
  int field1;
}

/*member: method1:FieldSet=[name=Class1a.field1]*/
@pragma('dart2js:noInline')
method1(Class1a c) {
  c.field1 = 42;
}

class Class2a {
  @pragma('dart2js:noElision')
  int field2 = 42;
}

class Class2b extends Class2a {}

/*member: method2:FieldSet=[name=Class2a.field2]*/
@pragma('dart2js:noInline')
method2(Class2a c) {
  c.field2 = 42;
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
  c.field3 = 42;
}

class Class4a {
  int field4;
}

class Class4b implements Class4a {
  int field4;
}

@pragma('dart2js:noInline')
method4(Class4a c) {
  c.field4 = 42;
}

class Class5a {
  int field5;
}

/*member: method5:FieldSet=[removed=field5]*/
@pragma('dart2js:noInline')
method5(Class5a c) {
  c.field5 = 42;
}

class Class6a {
  int field6 = 42;
}

class Class6b extends Class6a {}

/*member: method6:FieldSet=[removed=field6]*/
@pragma('dart2js:noInline')
method6(Class6a c) {
  c.field6 = 42;
}
