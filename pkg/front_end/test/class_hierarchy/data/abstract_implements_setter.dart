// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Interface {
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

/*class: AbstractClass:
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface {
  /*member: AbstractClass.implementedConcreteSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.implementedAbstractSetter=#int:
   classBuilder=Interface,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteSetter=#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void set declaredConcreteSetter(int value) {}

  /*member: AbstractClass.declaredAbstractSetter=#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void set declaredAbstractSetter(int value);

  /*member: AbstractClass.declaredConcreteImplementsConcreteSetter=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsConcreteSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteImplementsConcreteSetter(int value) {}

  /*member: AbstractClass.declaredAbstractImplementsConcreteSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsConcreteSetter=,
    Interface.declaredAbstractImplementsConcreteSetter=],
   declared-overrides=[Interface.declaredAbstractImplementsConcreteSetter=],
   isSynthesized
  */
  void set declaredAbstractImplementsConcreteSetter(int value);

  /*member: AbstractClass.declaredConcreteImplementsAbstractSetter=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[Interface.declaredConcreteImplementsAbstractSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteImplementsAbstractSetter(int value) {}

  /*member: AbstractClass.declaredAbstractImplementsAbstractSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractImplementsAbstractSetter=,
    Interface.declaredAbstractImplementsAbstractSetter=],
   declared-overrides=[Interface.declaredAbstractImplementsAbstractSetter=],
   isSynthesized
  */
  void set declaredAbstractImplementsAbstractSetter(int value);
}

main() {}
