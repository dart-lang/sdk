// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:calls=*,params=0*/
main() {
  method1(new Class1a());
  method2(new Class2a<int>());
  method3(new Class3a());
  method3(new Class3b());
  method4(new Class4a());
  method4(new Class4b());
}

class Class1a {
  /*member: Class1a.field1:emitted*/
  @pragma('dart2js:noElision')
  int field1;
}

/*member: method1:access=[field1],params=1*/
@pragma('dart2js:noInline')
method1(dynamic c) {
  return c.field1;
}

class Class2a<T> {
  /*member: Class2a.field2:emitted*/
  @pragma('dart2js:noElision')
  T field2;
}

/*member: method2:access=[field2],params=1*/
@pragma('dart2js:noInline')
method2(dynamic c) {
  return c.field2;
}

class Class3a {
  /*member: Class3a.field3:emitted,get=simple*/
  @pragma('dart2js:noElision')
  int field3;
}

class Class3b {
  /*member: Class3b.field3:emitted,get=simple*/
  @pragma('dart2js:noElision')
  int field3;
}

/*member: method3:calls=[get$field3(0)],params=1*/
@pragma('dart2js:noInline')
method3(dynamic c) {
  return c.field3;
}

class Class4a {
  /*member: Class4a.field4:emitted,get=simple*/
  @pragma('dart2js:noElision')
  int field4;
}

class Class4b implements Class4a {
  /*member: Class4b.field4:emitted,get=simple*/
  @pragma('dart2js:noElision')
  @override
  int field4;
}

/*member: method4:calls=[get$field4(0)],params=1*/
@pragma('dart2js:noInline')
method4(Class4a c) {
  return c.field4;
}
