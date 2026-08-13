// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.extendedMethod1#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedMethod1(int i) {}

  /*member: Super.extendedMethod2#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedMethod2(num i) {}

  /*member: Super.overriddenMethod1#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void overriddenMethod1(int i) {}

  /*member: Super.overriddenMethod2#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void overriddenMethod2(num n) {}
}

/*class: Class:
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
/*member: Class.extendedMethod1#cls:
 classBuilder=Class,
 inherited-implements=[Class.extendedMethod1],
 isSynthesized,
 member=Super.extendedMethod1
*/
/*member: Class.extendedMethod2#cls:
 classBuilder=Class,
 inherited-implements=[Class.extendedMethod2],
 isSynthesized,
 member=Super.extendedMethod2
*/
class Class extends Super {
  /*member: Class.extendedMethod1#int:
   classBuilder=Class,
   declarations=[
    Class.extendedMethod1,
    Super.extendedMethod1],
   declared-overrides=[Super.extendedMethod1],
   isSynthesized
  */
  void extendedMethod1(num n);

  /*member: Class.extendedMethod2#int:
   classBuilder=Class,
   declarations=[
    Class.extendedMethod2,
    Super.extendedMethod2],
   declared-overrides=[Super.extendedMethod2],
   isSynthesized
  */
  void extendedMethod2(int i);

  /*member: Class.overriddenMethod1#cls:
   classBuilder=Class,
   declared-overrides=[Super.overriddenMethod1],
   isSourceDeclaration
  */
  void overriddenMethod1(num n) {}

  /*member: Class.overriddenMethod2#cls:
   classBuilder=Class,
   declared-overrides=[Super.overriddenMethod2],
   isSourceDeclaration
  */
  void overriddenMethod2(int n) {}
}
