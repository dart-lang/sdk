// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 abstractMembers=[
  Interface.declaredAbstractImplementsAbstractSetter=,
  Interface.declaredConcreteImplementsAbstractSetter=,
  Interface.implementedAbstractSetter=],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
  /*member: Interface.implementedConcreteSetter=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set implementedConcreteSetter(int value) {}

  /*member: Interface.implementedAbstractSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set implementedAbstractSetter(int value);

  /*member: Interface.declaredConcreteImplementsConcreteSetter=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set declaredConcreteImplementsConcreteSetter(int value) {}

  /*member: Interface.declaredAbstractImplementsConcreteSetter=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set declaredAbstractImplementsConcreteSetter(int value) {}

  /*member: Interface.declaredConcreteImplementsAbstractSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set declaredConcreteImplementsAbstractSetter(int value);

  /*member: Interface.declaredAbstractImplementsAbstractSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */
  void set declaredAbstractImplementsAbstractSetter(int value);
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractImplementsAbstractSetter=,
  ConcreteClass.declaredAbstractImplementsConcreteSetter=,
  ConcreteClass.declaredAbstractSetter=,
  Interface.implementedAbstractSetter=,
  Interface.implementedConcreteSetter=],
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface {
  /*member: ConcreteClass.implementedConcreteSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.implementedAbstractSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteSetter=#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void set declaredConcreteSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractSetter=#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void set declaredAbstractSetter(int value);

  /*member: ConcreteClass.declaredConcreteImplementsConcreteSetter=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteImplementsConcreteSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractImplementsConcreteSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsConcreteSetter=,
    Interface.declaredAbstractImplementsConcreteSetter=],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteSetter=],
   isSynthesized
  */
  void set declaredAbstractImplementsConcreteSetter(int value);

  /*member: ConcreteClass.declaredConcreteImplementsAbstractSetter=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteImplementsAbstractSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractImplementsAbstractSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractImplementsAbstractSetter=,
    Interface.declaredAbstractImplementsAbstractSetter=],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractSetter=],
   isSynthesized
  */
  void set declaredAbstractImplementsAbstractSetter(int value);
}

main() {}
