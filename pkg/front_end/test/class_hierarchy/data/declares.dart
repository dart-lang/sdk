// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 abstractMembers=[
  Super.extendedAbstractDeclaredAbstractMethod,
  Super.extendedAbstractDeclaredConcreteMethod,
  Super.extendedAbstractImplementedDeclaredAbstractMethod,
  Super.extendedAbstractImplementedDeclaredConcreteMethod],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.extendedConcreteDeclaredConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteDeclaredConcreteMethod() {}

  /*member: Super.extendedAbstractDeclaredConcreteMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractDeclaredConcreteMethod();

  /*member: Super.extendedConcreteDeclaredAbstractMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteDeclaredAbstractMethod() {}
  /*member: Super.extendedAbstractDeclaredAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractDeclaredAbstractMethod();

  /*member: Super.extendedConcreteImplementedDeclaredConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  /*member: Super.extendedAbstractImplementedDeclaredConcreteMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedDeclaredConcreteMethod();

  /*member: Super.extendedConcreteImplementedDeclaredAbstractMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedDeclaredAbstractMethod() {}

  /*member: Super.extendedAbstractImplementedDeclaredAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedDeclaredAbstractMethod();
}

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
  /*member: Interface.implementedDeclaredConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void implementedDeclaredConcreteMethod() {}

  /*member: Interface.implementedDeclaredAbstractMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void implementedDeclaredAbstractMethod() {}

  /*member: Interface.extendedConcreteImplementedDeclaredConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  /*member: Interface.extendedAbstractImplementedDeclaredConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void extendedAbstractImplementedDeclaredConcreteMethod() {}

  /*member: Interface.extendedConcreteImplementedDeclaredAbstractMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void extendedConcreteImplementedDeclaredAbstractMethod() {}

  /*member: Interface.extendedAbstractImplementedDeclaredAbstractMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void extendedAbstractImplementedDeclaredAbstractMethod() {}
}

/*class: Class:
 abstractMembers=[
  Class.extendedAbstractDeclaredAbstractMethod,
  Class.extendedAbstractImplementedDeclaredAbstractMethod,
  Class.implementedDeclaredAbstractMethod],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class Class extends Super implements Interface {
  /*member: Class.extendedConcreteDeclaredConcreteMethod#cls:
   classBuilder=Class,
   declared-overrides=[Super.extendedConcreteDeclaredConcreteMethod],
   isSourceDeclaration
  */
  void extendedConcreteDeclaredConcreteMethod() {}

  /*member: Class.extendedAbstractDeclaredConcreteMethod#cls:
   classBuilder=Class,
   declared-overrides=[Super.extendedAbstractDeclaredConcreteMethod],
   isSourceDeclaration
  */
  void extendedAbstractDeclaredConcreteMethod() {}

  /*member: Class.extendedConcreteDeclaredAbstractMethod#cls:
   classBuilder=Class,
   inherited-implements=[Class.extendedConcreteDeclaredAbstractMethod],
   isSynthesized,
   member=Super.extendedConcreteDeclaredAbstractMethod
  */
  /*member: Class.extendedConcreteDeclaredAbstractMethod#int:
   classBuilder=Class,
   declarations=[
    Class.extendedConcreteDeclaredAbstractMethod,
    Super.extendedConcreteDeclaredAbstractMethod],
   declared-overrides=[Super.extendedConcreteDeclaredAbstractMethod],
   isSynthesized
  */
  void extendedConcreteDeclaredAbstractMethod();

  /*member: Class.extendedAbstractDeclaredAbstractMethod#int:
   classBuilder=Class,
   declarations=[
    Class.extendedAbstractDeclaredAbstractMethod,
    Super.extendedAbstractDeclaredAbstractMethod],
   declared-overrides=[Super.extendedAbstractDeclaredAbstractMethod],
   isSynthesized
  */
  void extendedAbstractDeclaredAbstractMethod();

  /*member: Class.implementedDeclaredConcreteMethod#cls:
   classBuilder=Class,
   declared-overrides=[Interface.implementedDeclaredConcreteMethod],
   isSourceDeclaration
  */
  void implementedDeclaredConcreteMethod() {}

  /*member: Class.implementedDeclaredAbstractMethod#int:
   classBuilder=Class,
   declarations=[
    Class.implementedDeclaredAbstractMethod,
    Interface.implementedDeclaredAbstractMethod],
   declared-overrides=[Interface.implementedDeclaredAbstractMethod],
   isSynthesized
  */
  void implementedDeclaredAbstractMethod();

  /*member: Class.extendedConcreteImplementedDeclaredConcreteMethod#cls:
   classBuilder=Class,
   declared-overrides=[
    Interface.extendedConcreteImplementedDeclaredConcreteMethod,
    Super.extendedConcreteImplementedDeclaredConcreteMethod],
   isSourceDeclaration
  */
  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  /*member: Class.extendedAbstractImplementedDeclaredConcreteMethod#cls:
   classBuilder=Class,
   declared-overrides=[
    Interface.extendedAbstractImplementedDeclaredConcreteMethod,
    Super.extendedAbstractImplementedDeclaredConcreteMethod],
   isSourceDeclaration
  */
  void extendedAbstractImplementedDeclaredConcreteMethod() {}

  /*member: Class.extendedConcreteImplementedDeclaredAbstractMethod#cls:
   classBuilder=Class,
   inherited-implements=[Class.extendedConcreteImplementedDeclaredAbstractMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedDeclaredAbstractMethod
  */
  /*member: Class.extendedConcreteImplementedDeclaredAbstractMethod#int:
   classBuilder=Class,
   declarations=[
    Class.extendedConcreteImplementedDeclaredAbstractMethod,
    Interface.extendedConcreteImplementedDeclaredAbstractMethod,
    Super.extendedConcreteImplementedDeclaredAbstractMethod],
   declared-overrides=[
    Interface.extendedConcreteImplementedDeclaredAbstractMethod,
    Super.extendedConcreteImplementedDeclaredAbstractMethod],
   isSynthesized
  */
  void extendedConcreteImplementedDeclaredAbstractMethod();

  /*member: Class.extendedAbstractImplementedDeclaredAbstractMethod#int:
   classBuilder=Class,
   declarations=[
    Class.extendedAbstractImplementedDeclaredAbstractMethod,
    Interface.extendedAbstractImplementedDeclaredAbstractMethod,
    Super.extendedAbstractImplementedDeclaredAbstractMethod],
   declared-overrides=[
    Interface.extendedAbstractImplementedDeclaredAbstractMethod,
    Super.extendedAbstractImplementedDeclaredAbstractMethod],
   isSynthesized
  */
  void extendedAbstractImplementedDeclaredAbstractMethod();
}
