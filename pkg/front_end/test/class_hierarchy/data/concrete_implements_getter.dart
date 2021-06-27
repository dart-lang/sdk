// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 abstractMembers=[
  Interface.declaredAbstractImplementsAbstractGetter,
  Interface.declaredConcreteImplementsAbstractGetter,
  Interface.implementedAbstractGetter],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
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

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractGetter,
  ConcreteClass.declaredAbstractImplementsAbstractGetter,
  ConcreteClass.declaredAbstractImplementsConcreteGetter,
  Interface.implementedAbstractGetter,
  Interface.implementedConcreteGetter],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
/*member: ConcreteClass.implementedConcreteGetter#int:
 classBuilder=Interface,
 isSourceDeclaration
*/
/*member: ConcreteClass.implementedAbstractGetter#int:
 classBuilder=Interface,
 isSourceDeclaration
*/
class ConcreteClass implements Interface {
  /*member: ConcreteClass.declaredConcreteGetter#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  int get declaredConcreteGetter => 0;

  /*member: ConcreteClass.declaredAbstractGetter#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  int get declaredAbstractGetter;

  /*member: ConcreteClass.declaredConcreteImplementsConcreteGetter#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteGetter],
   isSourceDeclaration
  */
  int get declaredConcreteImplementsConcreteGetter => 0;

  /*member: ConcreteClass.declaredAbstractImplementsConcreteGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteGetter,
    Interface.declaredAbstractImplementsConcreteGetter],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteGetter],
   isSynthesized
  */
  int get declaredAbstractImplementsConcreteGetter;

  /*member: ConcreteClass.declaredConcreteImplementsAbstractGetter#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractGetter],
   isSourceDeclaration
  */
  int get declaredConcreteImplementsAbstractGetter => 0;

  /*member: ConcreteClass.declaredAbstractImplementsAbstractGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractGetter,
    Interface.declaredAbstractImplementsAbstractGetter],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractGetter],
   isSynthesized
  */
  int get declaredAbstractImplementsAbstractGetter;
}

main() {}
