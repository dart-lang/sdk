// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 abstractMembers=[
  Interface.declaredAbstractImplementsAbstractMethod,
  Interface.declaredConcreteImplementsAbstractMethod,
  Interface.implementedAbstractMethod],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
  /*member: Interface.implementedConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void implementedConcreteMethod() {}

  /*member: Interface.implementedAbstractMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void implementedAbstractMethod();

  /*member: Interface.declaredConcreteImplementsConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void declaredConcreteImplementsConcreteMethod() {}

  /*member: Interface.declaredAbstractImplementsConcreteMethod#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void declaredAbstractImplementsConcreteMethod() {}

  /*member: Interface.declaredConcreteImplementsAbstractMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void declaredConcreteImplementsAbstractMethod();

  /*member: Interface.declaredAbstractImplementsAbstractMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void declaredAbstractImplementsAbstractMethod();
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractImplementsAbstractMethod,
  ConcreteClass.declaredAbstractImplementsConcreteMethod,
  ConcreteClass.declaredAbstractMethod,
  Interface.implementedAbstractMethod,
  Interface.implementedConcreteMethod],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface {
  /*member: ConcreteClass.implementedConcreteMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.implementedAbstractMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteMethod#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void declaredConcreteMethod() {}

  /*member: ConcreteClass.declaredAbstractMethod#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void declaredAbstractMethod();

  /*member: ConcreteClass.declaredConcreteImplementsConcreteMethod#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteMethod],
   isSourceDeclaration
  */
  void declaredConcreteImplementsConcreteMethod() {}

  /*member: ConcreteClass.declaredAbstractImplementsConcreteMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteMethod,
    Interface.declaredAbstractImplementsConcreteMethod],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteMethod],
   isSynthesized
  */
  void declaredAbstractImplementsConcreteMethod();

  /*member: ConcreteClass.declaredConcreteImplementsAbstractMethod#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractMethod],
   isSourceDeclaration
  */
  void declaredConcreteImplementsAbstractMethod() {}

  /*member: ConcreteClass.declaredAbstractImplementsAbstractMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractMethod,
    Interface.declaredAbstractImplementsAbstractMethod],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractMethod],
   isSynthesized
  */
  void declaredAbstractImplementsAbstractMethod();
}
