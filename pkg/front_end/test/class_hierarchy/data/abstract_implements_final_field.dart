// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface {
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

/*class: AbstractClass:
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface {
  /*member: AbstractClass.implementedConcreteField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteField#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  final int declaredConcreteField = 0;

  /*member: AbstractClass.declaredAbstractField#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  abstract final int declaredAbstractField;

  /*member: AbstractClass.declaredConcreteImplementsConcreteField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteField],
   isSourceDeclaration
  */
  final int declaredConcreteImplementsConcreteField = 0;

  /*member: AbstractClass.declaredAbstractImplementsConcreteField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteField],
   isSynthesized
  */
  abstract final int declaredAbstractImplementsConcreteField;

  /*member: AbstractClass.declaredConcreteImplementsAbstractField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractField],
   isSourceDeclaration
  */
  final int declaredConcreteImplementsAbstractField = 0;

  /*member: AbstractClass.declaredAbstractImplementsAbstractField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractField],
   isSynthesized
  */
  abstract final int declaredAbstractImplementsAbstractField;
}

main() {}
