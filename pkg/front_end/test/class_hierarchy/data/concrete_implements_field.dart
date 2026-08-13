// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 abstractMembers=[
  Interface.declaredAbstractImplementsAbstractField,
  Interface.declaredAbstractImplementsAbstractField=,
  Interface.declaredConcreteImplementsAbstractField,
  Interface.declaredConcreteImplementsAbstractField=,
  Interface.implementedAbstractField,
  Interface.implementedAbstractField=],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
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

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractField,
  ConcreteClass.declaredAbstractField=,
  ConcreteClass.declaredAbstractImplementsAbstractField,
  ConcreteClass.declaredAbstractImplementsAbstractField=,
  ConcreteClass.declaredAbstractImplementsConcreteField,
  ConcreteClass.declaredAbstractImplementsConcreteField=,
  Interface.implementedAbstractField,
  Interface.implementedAbstractField=,
  Interface.implementedConcreteField,
  Interface.implementedConcreteField=],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface {
  /*member: ConcreteClass.implementedConcreteField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: ConcreteClass.implementedConcreteField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.implementedAbstractField#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: ConcreteClass.implementedAbstractField=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteField#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  /*member: ConcreteClass.declaredConcreteField=#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  int declaredConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractField#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  /*member: ConcreteClass.declaredAbstractField=#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  abstract int declaredAbstractField;

  /*member: ConcreteClass.declaredConcreteImplementsConcreteField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsConcreteField,
    Interface.declaredConcreteImplementsConcreteField=],
   isSourceDeclaration
  */
  /*member: ConcreteClass.declaredConcreteImplementsConcreteField=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsConcreteField,
    Interface.declaredConcreteImplementsConcreteField=],
   isSourceDeclaration
  */
  int declaredConcreteImplementsConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractImplementsConcreteField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField],
   declared-overrides=[
    Interface.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField=],
   isSynthesized
  */
  /*member: ConcreteClass.declaredAbstractImplementsConcreteField=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteField=,
    Interface.declaredAbstractImplementsConcreteField=],
   declared-overrides=[
    Interface.declaredAbstractImplementsConcreteField,
    Interface.declaredAbstractImplementsConcreteField=],
   isSynthesized
  */
  abstract int declaredAbstractImplementsConcreteField;

  /*member: ConcreteClass.declaredConcreteImplementsAbstractField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsAbstractField,
    Interface.declaredConcreteImplementsAbstractField=],
   isSourceDeclaration
  */
  /*member: ConcreteClass.declaredConcreteImplementsAbstractField=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface.declaredConcreteImplementsAbstractField,
    Interface.declaredConcreteImplementsAbstractField=],
   isSourceDeclaration
  */
  int declaredConcreteImplementsAbstractField = 0;

  /*member: ConcreteClass.declaredAbstractImplementsAbstractField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField],
   declared-overrides=[
    Interface.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField=],
   isSynthesized
  */
  /*member: ConcreteClass.declaredAbstractImplementsAbstractField=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractField=,
    Interface.declaredAbstractImplementsAbstractField=],
   declared-overrides=[
    Interface.declaredAbstractImplementsAbstractField,
    Interface.declaredAbstractImplementsAbstractField=],
   isSynthesized
  */
  abstract int declaredAbstractImplementsAbstractField;
}

main() {}
