// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

/*class: A:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class A {
  /*member: A.method#cls:
   classBuilder=A,
   isSourceDeclaration
  */
  dynamic method(dynamic o, {dynamic named}) {}
}

/*class: B:
 maxInheritancePath=2,
 superclasses=[
  A,
  Object]
*/
abstract class B extends A {
  /*member: B.method#cls:
   classBuilder=B,
   isSynthesized,
   member=A.method
  */
  /*member: B.method#int:
   classBuilder=B,
   declarations=[
    A.method,
    B.method],
   declared-overrides=[A.method],
   isSynthesized
  */
  Object method(Object o, {Object named});
}

/*class: C1:
 interfaces=[B],
 maxInheritancePath=3,
 superclasses=[
  A,
  Object]
*/
class C1 extends A implements B {
  /*member: C1.method#cls:
   classBuilder=C1,
   declared-overrides=[
    A.method,
    B.method],
   isSourceDeclaration
  */
  method(o, {named}) {}
}

/*class: C2:
 maxInheritancePath=3,
 superclasses=[
  A,
  B,
  Object]
*/
class C2 extends B implements A {
  /*member: C2.method#cls:
   classBuilder=C2,
   declared-overrides=[
    A.method,
    B.method],
   isSourceDeclaration
  */
  method(o, {named}) {}
}

/*class: C3:
 interfaces=[
  A,
  B],
 maxInheritancePath=3,
 superclasses=[Object]
*/
class C3 implements A, B {
  /*member: C3.method#cls:
   classBuilder=C3,
   declared-overrides=[
    A.method,
    B.method],
   isSourceDeclaration
  */
  method(o, {named}) {}
}

/*class: C4:
 interfaces=[
  A,
  B],
 maxInheritancePath=3,
 superclasses=[Object]
*/
class C4 implements B, A {
  /*member: C4.method#cls:
   classBuilder=C4,
   declared-overrides=[
    A.method,
    B.method],
   isSourceDeclaration
  */
  method(o, {named}) {}
}

/*class: D:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class D {
  /*member: D.==#int:
   classBuilder=D,
   declarations=[
    D.==,
    Object.==],
   declared-overrides=[Object.==],
   isSynthesized
  */
  bool operator ==(Object other);
}

/*class: F:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class F {}

/*class: E:
 interfaces=[
  D,
  F],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class E implements D, F {
  /*member: E.==#cls:
   classBuilder=E,
   declared-overrides=[
    D.==,
    F.==,
    Object.==],
   isSourceDeclaration
  */
  bool operator ==(other) => true;
}
