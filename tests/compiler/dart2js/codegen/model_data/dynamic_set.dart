// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:calls=*,params=0*/
main() {
  method1(new Class1a());
  method2(new Class2a<int>());
  method3(new Class3a());
  method3(new Class3b());
  method4(new Class4a());
  method4(new Class4b());
}

class Class1a {
  /*element: Class1a.field1:elided*/
  int field1;
}

/*element: method1:params=1*/
@pragma('dart2js:noInline')
method1(dynamic c) {
  c.field1 = 42;
}

class Class2a<T> {
  /*strong.element: Class2a.field2:checked,elided*/
  /*omit.element: Class2a.field2:elided*/
  T field2;
}

/*strong.element: method2:calls=[set$field2(1)],params=1*/
/*omit.element: method2:params=1*/
@pragma('dart2js:noInline')
method2(dynamic c) {
  c.field2 = 42;
}

class Class3a {
  /*strong.element: Class3a.field3:checked,elided*/
  /*omit.element: Class3a.field3:elided,set=simple*/
  int field3;
}

class Class3b {
  /*strong.element: Class3b.field3:checked,elided*/
  /*omit.element: Class3b.field3:elided,set=simple*/
  int field3;
}

/*element: method3:calls=[set$field3(1)],params=1*/
@pragma('dart2js:noInline')
method3(dynamic c) {
  c.field3 = 42;
}

class Class4a {
  /*strong.element: Class4a.field4:checked,elided*/
  /*omit.element: Class4a.field4:elided,set=simple*/
  int field4;
}

class Class4b implements Class4a {
  /*strong.element: Class4b.field4:checked,elided*/
  /*omit.element: Class4b.field4:elided,set=simple*/
  int field4;
}

/*element: method4:calls=[set$field4(1)],params=1*/
@pragma('dart2js:noInline')
method4(Class4a c) {
  c.field4 = 42;
}
