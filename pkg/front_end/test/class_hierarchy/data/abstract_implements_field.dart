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
  /*member: Interface.implementedConcreteField=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int implementedConcreteField = 0;

  /*member: Interface.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.implementedAbstractField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract int implementedAbstractField;

  /*member: Interface.declaredConcreteImplementsConcreteField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.declaredConcreteImplementsConcreteField=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int declaredConcreteImplementsConcreteField = 0;

  /*member: Interface.declaredAbstractImplementsConcreteField#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.declaredAbstractImplementsConcreteField=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int declaredAbstractImplementsConcreteField = 0;

  /*member: Interface.declaredConcreteImplementsAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.declaredConcreteImplementsAbstractField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract int declaredConcreteImplementsAbstractField;

  /*member: Interface.declaredAbstractImplementsAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.declaredAbstractImplementsAbstractField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  abstract int declaredAbstractImplementsAbstractField;
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
  /*member: AbstractClass.implementedConcreteField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: AbstractClass.implementedAbstractField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteField#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteField=#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int declaredConcreteField = 0;

  /*member: AbstractClass.declaredAbstractField#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredAbstractField=#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  abstract int declaredAbstractField;

  /*member: AbstractClass.declaredConcreteImplementsConcreteField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsConcreteField,
    Interface.declaredConcreteImplementsConcreteField=],
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteImplementsConcreteField=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsConcreteField,
    Interface.declaredConcreteImplementsConcreteField=],
   isSourceDeclaration
  */
  int declaredConcreteImplementsConcreteField = 0;

  /*member: AbstractClass.declaredAbstractImplementsConcreteField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField],
   declared-overrides=[
    Interface.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField=],
   isSynthesized
  */
  /*member: AbstractClass.declaredAbstractImplementsConcreteField=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteField=,
    Interface.declaredAbstractImplementsConcreteField=],
   declared-overrides=[
    Interface.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField=],
   isSynthesized
  */
  abstract int declaredAbstractImplementsConcreteField;

  /*member: AbstractClass.declaredConcreteImplementsAbstractField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsAbstractField,
    Interface.declaredConcreteImplementsAbstractField=],
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteImplementsAbstractField=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsAbstractField,
    Interface.declaredConcreteImplementsAbstractField=],
   isSourceDeclaration
  */
  int declaredConcreteImplementsAbstractField = 0;

  /*member: AbstractClass.declaredAbstractImplementsAbstractField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField],
   declared-overrides=[
    Interface.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField=],
   isSynthesized
  */
  /*member: AbstractClass.declaredAbstractImplementsAbstractField=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractField=,
    Interface.declaredAbstractImplementsAbstractField=],
   declared-overrides=[
    Interface.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField=],
   isSynthesized
  */
  abstract int declaredAbstractImplementsAbstractField;
}

main() {}
