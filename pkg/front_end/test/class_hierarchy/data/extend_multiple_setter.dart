// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteSetter(int value) {}

  /*member: Super.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractSetter(int value);

  /*member: Super.extendedConcreteImplementedSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedSetter(int value) {}

  /*member: Super.extendedAbstractImplementedSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedSetter(int value);

  /*member: Super.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedMultipleSetter(int value) {}

  /*member: Super.extendedAbstractImplementedMultipleSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedMultipleSetter(int value);
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteImplementedSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedSetter(int value) {}

  /*member: Interface1.extendedAbstractImplementedSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedSetter(int value) {}

  /*member: Interface1.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedMultipleSetter(int value) {}

  /*member: Interface1.extendedAbstractImplementedMultipleSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedMultipleSetter(int value) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedMultipleSetter(int value) {}

  /*member: Interface2.extendedAbstractImplementedMultipleSetter=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedMultipleSetter(int value) {}
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
abstract class AbstractClass extends Super implements Interface1, Interface2 {
  /*member: AbstractClass.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteImplementedSetter=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */
  /*member: AbstractClass.extendedConcreteImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedSetter=,
    Super.extendedConcreteImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */

  /*member: AbstractClass.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */
  /*member: AbstractClass.extendedConcreteImplementedMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleSetter=,
    Interface2.extendedConcreteImplementedMultipleSetter=,
    Super.extendedConcreteImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */

  /*member: AbstractClass.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedSetter=,
    Super.extendedAbstractImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedSetter=
  */

  /*member: AbstractClass.extendedAbstractImplementedMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleSetter=,
    Interface2.extendedAbstractImplementedMultipleSetter=,
    Super.extendedAbstractImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleSetter=
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractImplementedMultipleSetter=,
  AbstractClass.extendedAbstractImplementedSetter=,
  Super.extendedAbstractSetter=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  AbstractClass,
  Object,
  Super]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteImplementedSetter=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */
  /*member: ConcreteSub.extendedConcreteImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedSetter=,
    Super.extendedConcreteImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */

  /*member: ConcreteSub.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */
  /*member: ConcreteSub.extendedConcreteImplementedMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleSetter=,
    Interface2.extendedConcreteImplementedMultipleSetter=,
    Super.extendedConcreteImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */

  /*member: ConcreteSub.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedSetter=,
    Super.extendedAbstractImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedSetter=
  */

  /*member: ConcreteSub.extendedAbstractImplementedMultipleSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleSetter=,
    Interface2.extendedAbstractImplementedMultipleSetter=,
    Super.extendedAbstractImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleSetter=
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractImplementedMultipleSetter=,
  Interface1.extendedAbstractImplementedSetter=,
  Interface2.extendedAbstractImplementedMultipleSetter=,
  Super.extendedAbstractImplementedMultipleSetter=,
  Super.extendedAbstractImplementedSetter=,
  Super.extendedAbstractSetter=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteImplementedSetter=#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */
  /*member: ConcreteClass.extendedConcreteImplementedSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedSetter=,
    Super.extendedConcreteImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedSetter=
  */

  /*member: ConcreteClass.extendedConcreteImplementedMultipleSetter=#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */
  /*member: ConcreteClass.extendedConcreteImplementedMultipleSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleSetter=,
    Interface2.extendedConcreteImplementedMultipleSetter=,
    Super.extendedConcreteImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleSetter=
  */

  /*member: ConcreteClass.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractImplementedSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedSetter=,
    Super.extendedAbstractImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedSetter=
  */

  /*member: ConcreteClass.extendedAbstractImplementedMultipleSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleSetter=,
    Interface2.extendedAbstractImplementedMultipleSetter=,
    Super.extendedAbstractImplementedMultipleSetter=],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleSetter=
  */
}

main() {}
