// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 abstractMembers=[
  Interface.declaredAbstractImplementsAbstractField,
  Interface.declaredConcreteImplementsAbstractField,
  Interface.implementedAbstractField],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
  /*member: Interface.implementedConcreteField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  final int implementedConcreteField = 0;

  /*member: Interface.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract final int implementedAbstractField;

  /*member: Interface.declaredConcreteImplementsConcreteField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  final int declaredConcreteImplementsConcreteField = 0;

  /*member: Interface.declaredAbstractImplementsConcreteField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  final int declaredAbstractImplementsConcreteField = 0;

  /*member: Interface.declaredConcreteImplementsAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract final int declaredConcreteImplementsAbstractField;

  /*member: Interface.declaredAbstractImplementsAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract final int declaredAbstractImplementsAbstractField;
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractField,
  ConcreteClass.declaredAbstractImplementsAbstractField,
  ConcreteClass.declaredAbstractImplementsConcreteField,
  Interface.implementedAbstractField,
  Interface.implementedConcreteField],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface {
  /*member: ConcreteClass.implementedConcreteField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteField#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  final int declaredConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractField#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  abstract final int declaredAbstractField;

  /*member: ConcreteClass.declaredConcreteImplementsConcreteField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteField],
   isSourceDeclaration
  */
  final int declaredConcreteImplementsConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractImplementsConcreteField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteField],
   isSynthesized
  */
  abstract final int declaredAbstractImplementsConcreteField;

  /*member: ConcreteClass.declaredConcreteImplementsAbstractField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractField],
   isSourceDeclaration
  */
  final int declaredConcreteImplementsAbstractField = 0;

  /*member: ConcreteClass.declaredAbstractImplementsAbstractField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractField],
   isSynthesized
  */
  abstract final int declaredAbstractImplementsAbstractField;
}

main() {}
