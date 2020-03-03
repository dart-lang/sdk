// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

/*class: A:A,Object*/
class A {
  /*member: A.method:dynamic Function(dynamic, {dynamic named})**/
  dynamic method(dynamic o, {dynamic named}) {}
}

/*class: B:A,B,Object*/
abstract class B extends A {
  /*member: B.method:Object* Function(Object*, {Object* named})**/
  Object method(Object o, {Object named});
}

/*class: C1:A,B,C1,Object*/
class C1 extends A implements B {
  /*member: C1.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: C2:A,B,C2,Object*/
class C2 extends B implements A {
  /*member: C2.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: C3:A,B,C3,Object*/
class C3 implements A, B {
  /*member: C3.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: C4:A,B,C4,Object*/
class C4 implements B, A {
  /*member: C4.method:dynamic Function(dynamic, {dynamic named})**/
  method(o, {named}) {}
}

/*class: D:D,Object*/
abstract class D {
  /*member: D.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: F:F,Object*/
abstract class F {}

/*class: E:D,E,F,Object*/
class E implements D, F {
  /*cfe|cfe:builder.member: E.==:bool* Function(dynamic)**/
  /*analyzer.member: E.==:bool* Function(Object*)**/
  bool operator ==(other) => true;
}
