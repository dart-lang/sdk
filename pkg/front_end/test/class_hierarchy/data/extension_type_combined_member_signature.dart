// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class A {
  /*member: A.method#int:
   classBuilder=A,
   isSourceDeclaration
  */
  (Object?, dynamic) method();
  /*member: A.getter#int:
   classBuilder=A,
   isSourceDeclaration
  */
  (Object?, dynamic) get getter;
  /*member: A.setter=#int:
   classBuilder=A,
   isSourceDeclaration
  */
  void set setter((int, int) Function(Object?, dynamic) f);
}

/*class: B:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class B {
  /*member: B.method#int:
   classBuilder=B,
   isSourceDeclaration
  */
  (dynamic, Object?) method();
  /*member: B.getter#int:
   classBuilder=B,
   isSourceDeclaration
  */
  (dynamic, Object?) get getter;
  /*member: B.setter=#int:
   classBuilder=B,
   isSourceDeclaration
  */
  void set setter((int, int) Function(dynamic, Object?) f);
}

/*class: C:
 interfaces=[
  A,
  B],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class C implements A, B {
  /*member: C.method#cls:
   classBuilder=C,
   declared-overrides=[
    A.method,
    B.method],
   isSourceDeclaration
  */
  (int, int) method() => (42, 87);
  /*member: C.getter#cls:
   classBuilder=C,
   declared-overrides=[
    A.getter,
    B.getter],
   isSourceDeclaration
  */
  (int, int) get getter => (42, 87);
  /*member: C.setter=#cls:
   classBuilder=C,
   declared-overrides=[
    A.setter=,
    B.setter=],
   isSourceDeclaration
  */
  void set setter((int, int) Function(dynamic, dynamic) f) {}
}

/*class: E:superExtensionTypes=[
  A,
  B,
  Object]*/
/*member: E.c:
 extensionTypeBuilder=E,
 isSourceDeclaration
*/
/*member: E.method:
 classBuilder=E,
 declarations=[
  A.method,
  B.method],
 isSynthesized,
 member=E.method,
 nonExtensionTypeMember
*/
/*member: E.getter:
 classBuilder=E,
 declarations=[
  A.getter,
  B.getter],
 isSynthesized,
 member=E.getter,
 nonExtensionTypeMember
*/
/*member: E.setter=:
 classBuilder=E,
 declarations=[
  A.setter=,
  B.setter=],
 isSynthesized,
 member=E.setter=,
 nonExtensionTypeMember
*/
extension type E(C c) implements A, B {}
