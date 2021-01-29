// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface {
  /*member: Interface.implementedConcreteGetter#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get implementedConcreteGetter => 0;

  /*member: Interface.implementedAbstractGetter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get implementedAbstractGetter;

  /*member: Interface.declaredConcreteImplementsConcreteGetter#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get declaredConcreteImplementsConcreteGetter => 0;

  /*member: Interface.declaredAbstractImplementsConcreteGetter#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get declaredAbstractImplementsConcreteGetter => 0;

  /*member: Interface.declaredConcreteImplementsAbstractGetter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get declaredConcreteImplementsAbstractGetter;

  /*member: Interface.declaredAbstractImplementsAbstractGetter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  int get declaredAbstractImplementsAbstractGetter;
}

/*class: AbstractClass:
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface {
  /*member: AbstractClass.implementedConcreteGetter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.implementedAbstractGetter#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteGetter#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int get declaredConcreteGetter => 0;

  /*member: AbstractClass.declaredAbstractGetter#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int get declaredAbstractGetter;

  /*member: AbstractClass.declaredConcreteImplementsConcreteGetter#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteGetter],
   isSourceDeclaration
  */
  int get declaredConcreteImplementsConcreteGetter => 0;

  /*member: AbstractClass.declaredAbstractImplementsConcreteGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteGetter,
    Interface.declaredAbstractImplementsConcreteGetter],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteGetter],
   isSynthesized
  */
  int get declaredAbstractImplementsConcreteGetter;

  /*member: AbstractClass.declaredConcreteImplementsAbstractGetter#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractGetter],
   isSourceDeclaration
  */
  int get declaredConcreteImplementsAbstractGetter => 0;

  /*member: AbstractClass.declaredAbstractImplementsAbstractGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractGetter,
    Interface.declaredAbstractImplementsAbstractGetter],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractGetter],
   isSynthesized
  */
  int get declaredAbstractImplementsAbstractGetter;
}

main() {}
