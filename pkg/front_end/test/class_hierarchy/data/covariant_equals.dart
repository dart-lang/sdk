// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

/*class: A:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class A {
  /*member: A.==#cls:
   classBuilder=A,
   declared-overrides=[Object.==],
   isSourceDeclaration
  */
  bool operator ==(covariant A other) => true;
}

/*class: B:
 maxInheritancePath=2,
 superclasses=[
  A,
  Object]
*/
class B extends A {
  /*member: B.==#cls:
   classBuilder=B,
   declared-overrides=[A.==],
   isSourceDeclaration
  */
  bool operator ==(other) => true;
}

/*class: C:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class C<T> {
  /*member: C.==#cls:
   classBuilder=C,
   declared-overrides=[Object.==],
   isSourceDeclaration
  */
  bool operator ==(covariant C<T> other) => true;
}

/*class: D:
 maxInheritancePath=2,
 superclasses=[
  C<int>,
  Object]
*/
class D extends C<int> {
  /*member: D.==#cls:
   classBuilder=C,
   isSourceDeclaration
  */
}

main() {}
