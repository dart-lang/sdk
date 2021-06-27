// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.implementMultipleSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set implementMultipleSetter(int i) {}

  /*member: Interface1.declareConcreteImplementMultipleSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set declareConcreteImplementMultipleSetter(int i) {}

  /*member: Interface1.declareAbstractImplementMultipleSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set declareAbstractImplementMultipleSetter(int i) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementMultipleSetter=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set implementMultipleSetter(int i) {}

  /*member: Interface2.declareConcreteImplementMultipleSetter=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set declareConcreteImplementMultipleSetter(int i) {}

  /*member: Interface2.declareAbstractImplementMultipleSetter=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set declareAbstractImplementMultipleSetter(int i) {}
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declareAbstractImplementMultipleSetter=,
  Interface1.implementMultipleSetter=,
  Interface2.implementMultipleSetter=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface1, Interface2 {
  /*member: ConcreteClass.implementMultipleSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementMultipleSetter=,
    Interface2.implementMultipleSetter=],
   isSynthesized,
   member=Interface1.implementMultipleSetter=
  */

  /*member: ConcreteClass.declareConcreteImplementMultipleSetter=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleSetter=,
    Interface2.declareConcreteImplementMultipleSetter=],
   isSourceDeclaration
  */
  void set declareConcreteImplementMultipleSetter(int i) {}

  /*member: ConcreteClass.declareAbstractImplementMultipleSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declareAbstractImplementMultipleSetter=,
    Interface1.declareAbstractImplementMultipleSetter=,
    Interface2.declareAbstractImplementMultipleSetter=],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleSetter=,
    Interface2.declareAbstractImplementMultipleSetter=],
   isSynthesized
  */
  void set declareAbstractImplementMultipleSetter(int i);
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/

abstract class AbstractClass implements Interface1, Interface2 {
  /*member: AbstractClass.implementMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleSetter=,
    Interface2.implementMultipleSetter=],
   isSynthesized,
   member=Interface1.implementMultipleSetter=
  */

  /*member: AbstractClass.declareConcreteImplementMultipleSetter=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleSetter=,
    Interface2.declareConcreteImplementMultipleSetter=],
   isSourceDeclaration
  */
  void set declareConcreteImplementMultipleSetter(int i) {}

  /*member: AbstractClass.declareAbstractImplementMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleSetter=,
    Interface1.declareAbstractImplementMultipleSetter=,
    Interface2.declareAbstractImplementMultipleSetter=],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleSetter=,
    Interface2.declareAbstractImplementMultipleSetter=],
   isSynthesized
  */
  void set declareAbstractImplementMultipleSetter(int i);
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.declareAbstractImplementMultipleSetter=,
  AbstractClass.implementMultipleSetter=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  AbstractClass,
  Object]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.declareConcreteImplementMultipleSetter=#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */

  /*member: ConcreteSub.declareAbstractImplementMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleSetter=,
    Interface1.declareAbstractImplementMultipleSetter=,
    Interface2.declareAbstractImplementMultipleSetter=],
   isSynthesized,
   member=AbstractClass.declareAbstractImplementMultipleSetter=
  */

  /*member: ConcreteSub.implementMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleSetter=,
    Interface2.implementMultipleSetter=],
   isSynthesized,
   member=Interface1.implementMultipleSetter=
  */
}

main() {}
