// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteGetter => 0;

  /*member: Super.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractGetter;

  /*member: Super.extendedConcreteImplementedGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteImplementedGetter => 0;

  /*member: Super.extendedAbstractImplementedGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractImplementedGetter;

  /*member: Super.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteImplementedMultipleGetter => 0;

  /*member: Super.extendedAbstractImplementedMultipleGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractImplementedMultipleGetter;
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteImplementedGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get extendedConcreteImplementedGetter => 0;

  /*member: Interface1.extendedAbstractImplementedGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get extendedAbstractImplementedGetter => 0;

  /*member: Interface1.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get extendedConcreteImplementedMultipleGetter => 0;

  /*member: Interface1.extendedAbstractImplementedMultipleGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get extendedAbstractImplementedMultipleGetter => 0;
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int get extendedConcreteImplementedMultipleGetter => 0;

  /*member: Interface2.extendedAbstractImplementedMultipleGetter#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int get extendedAbstractImplementedMultipleGetter => 0;
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
  /*member: AbstractClass.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteImplementedGetter#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */
  /*member: AbstractClass.extendedConcreteImplementedGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedGetter,
    Super.extendedConcreteImplementedGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */

  /*member: AbstractClass.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */
  /*member: AbstractClass.extendedConcreteImplementedMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleGetter,
    Interface2.extendedConcreteImplementedMultipleGetter,
    Super.extendedConcreteImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */

  /*member: AbstractClass.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractImplementedGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedGetter,
    Super.extendedAbstractImplementedGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedGetter
  */

  /*member: AbstractClass.extendedAbstractImplementedMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleGetter,
    Interface2.extendedAbstractImplementedMultipleGetter,
    Super.extendedAbstractImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleGetter
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractImplementedGetter,
  AbstractClass.extendedAbstractImplementedMultipleGetter,
  Super.extendedAbstractGetter],
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
  /*member: ConcreteSub.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteImplementedGetter#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */
  /*member: ConcreteSub.extendedConcreteImplementedGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedGetter,
    Super.extendedConcreteImplementedGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */

  /*member: ConcreteSub.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */
  /*member: ConcreteSub.extendedConcreteImplementedMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleGetter,
    Interface2.extendedConcreteImplementedMultipleGetter,
    Super.extendedConcreteImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */

  /*member: ConcreteSub.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractImplementedGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedGetter,
    Super.extendedAbstractImplementedGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedGetter
  */

  /*member: ConcreteSub.extendedAbstractImplementedMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleGetter,
    Interface2.extendedAbstractImplementedMultipleGetter,
    Super.extendedAbstractImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleGetter
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractImplementedGetter,
  Interface1.extendedAbstractImplementedMultipleGetter,
  Interface2.extendedAbstractImplementedMultipleGetter,
  Super.extendedAbstractGetter,
  Super.extendedAbstractImplementedGetter,
  Super.extendedAbstractImplementedMultipleGetter],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteImplementedGetter#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */
  /*member: ConcreteClass.extendedConcreteImplementedGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedGetter,
    Super.extendedConcreteImplementedGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedGetter
  */

  /*member: ConcreteClass.extendedConcreteImplementedMultipleGetter#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */
  /*member: ConcreteClass.extendedConcreteImplementedMultipleGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleGetter,
    Interface2.extendedConcreteImplementedMultipleGetter,
    Super.extendedConcreteImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleGetter
  */

  /*member: ConcreteClass.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractImplementedGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedGetter,
    Super.extendedAbstractImplementedGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedGetter
  */

  /*member: ConcreteClass.extendedAbstractImplementedMultipleGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleGetter,
    Interface2.extendedAbstractImplementedMultipleGetter,
    Super.extendedAbstractImplementedMultipleGetter],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleGetter
  */
}

main() {}
