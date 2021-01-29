// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface {
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

/*class: AbstractClass:
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface {
  /*member: AbstractClass.implementedConcreteMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.implementedAbstractMethod#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteMethod#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void declaredConcreteMethod() {}

  /*member: AbstractClass.declaredAbstractMethod#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void declaredAbstractMethod();

  /*member: AbstractClass.declaredConcreteImplementsConcreteMethod#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteMethod],
   isSourceDeclaration
  */
  void declaredConcreteImplementsConcreteMethod() {}

  /*member: AbstractClass.declaredAbstractImplementsConcreteMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteMethod,
    Interface.declaredAbstractImplementsConcreteMethod],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteMethod],
   isSynthesized
  */
  void declaredAbstractImplementsConcreteMethod();

  /*member: AbstractClass.declaredConcreteImplementsAbstractMethod#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractMethod],
   isSourceDeclaration
  */
  void declaredConcreteImplementsAbstractMethod() {}

  /*member: AbstractClass.declaredAbstractImplementsAbstractMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractMethod,
    Interface.declaredAbstractImplementsAbstractMethod],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractMethod],
   isSynthesized
  */
  void declaredAbstractImplementsAbstractMethod();
}
