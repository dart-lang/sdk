// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteMethod(int i) {}

  /*member: Super.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractMethod(int i);

  /*member: Super.extendedConcreteImplementedMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMethod(int i) {}

  /*member: Super.extendedAbstractImplementedMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMethod(int i);
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface1 {
  /*member: Interface1.extendedConcreteImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMethod(int i) {}

  /*member: Interface1.extendedAbstractImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMethod(int i) {}

  /*member: Interface1.implementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void implementedMethod(int i) {}

  /*member: Interface1.implementedMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void implementedMultipleMethod(int i) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface2 {
  /*member: Interface2.implementedMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void implementedMultipleMethod(int i) {}
}
