// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:calls=*,params=0*/
main() {
  method1(new Class1a()..field1);
  method2(new Class2a<int>()..field2);
  method3(new Class3a()..field3);
  method3(new Class3b()..field3);
  method4(new Class4a()..field4);
  method4(new Class4b()..field4);
}

class Class1a {
  /*member: Class1a.field1:emitted*/
  int field1;
}

/*member: method1:assign=[field1],params=1*/
@pragma('dart2js:noInline')
method1(dynamic c) {
  c.field1 = 42;
}

class Class2a<T> {
  /*spec.member: Class2a.field2:
   checked,
   emitted
  */
  /*prod.member: Class2a.field2:emitted*/
  T field2;
}

@pragma('dart2js:noInline')
/*spec.member: method2:
 calls=[set$field2(1)],
 params=1
*/
/*prod.member: method2:
 assign=[field2],
 params=1
*/
method2(dynamic c) {
  c.field2 = 42;
}

class Class3a {
  /*spec.member: Class3a.field3:
   checked,
   emitted
  */
  /*prod.member: Class3a.field3:
   emitted,
   set=simple
  */
  int field3;
}

class Class3b {
  /*spec.member: Class3b.field3:
   checked,
   emitted
  */
  /*prod.member: Class3b.field3:
   emitted,
   set=simple
  */
  int field3;
}

/*member: method3:calls=[set$field3(1)],params=1*/
@pragma('dart2js:noInline')
method3(dynamic c) {
  c.field3 = 42;
}

class Class4a {
  /*spec.member: Class4a.field4:
   checked,
   emitted
  */
  /*prod.member: Class4a.field4:
   emitted,
   set=simple
  */
  int field4;
}

class Class4b implements Class4a {
  @override
  /*spec.member: Class4b.field4:
   checked,
   emitted
  */
  /*prod.member: Class4b.field4:
   emitted,
   set=simple
  */
  int field4;
}

/*member: method4:calls=[set$field4(1)],params=1*/
@pragma('dart2js:noInline')
method4(Class4a c) {
  c.field4 = 42;
}
