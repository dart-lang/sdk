// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteMethod() {}

  /*member: Super.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractMethod();

  /*member: Super.extendedConcreteImplementedMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMethod() {}

  /*member: Super.extendedAbstractImplementedMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMethod();

  /*member: Super.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMultipleMethod() {}

  /*member: Super.extendedAbstractImplementedMultipleMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMultipleMethod();
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMethod() {}

  /*member: Interface1.extendedAbstractImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMethod() {}

  /*member: Interface1.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMultipleMethod() {}

  /*member: Interface1.extendedAbstractImplementedMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMultipleMethod() {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void extendedConcreteImplementedMultipleMethod() {}
  /*member: Interface2.extendedAbstractImplementedMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void extendedAbstractImplementedMultipleMethod() {}
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Super,
  Object]
*/
abstract class AbstractClass extends Super implements Interface1, Interface2 {
  /*member: AbstractClass.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteImplementedMethod#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */
  /*member: AbstractClass.extendedConcreteImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMethod,
    Super.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */

  /*member: AbstractClass.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */
  /*member: AbstractClass.extendedConcreteImplementedMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleMethod,
    Interface2.extendedConcreteImplementedMultipleMethod,
    Super.extendedConcreteImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */

  /*member: AbstractClass.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMethod
  */

  /*member: AbstractClass.extendedAbstractImplementedMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleMethod,
    Interface2.extendedAbstractImplementedMultipleMethod,
    Super.extendedAbstractImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleMethod
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractImplementedMethod,
  AbstractClass.extendedAbstractImplementedMultipleMethod,
  Super.extendedAbstractMethod],
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
  /*member: ConcreteSub.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteImplementedMethod#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */
  /*member: ConcreteSub.extendedConcreteImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMethod,
    Super.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */

  /*member: ConcreteSub.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */
  /*member: ConcreteSub.extendedConcreteImplementedMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleMethod,
    Interface2.extendedConcreteImplementedMultipleMethod,
    Super.extendedConcreteImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */

  /*member: ConcreteSub.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMethod
  */

  /*member: ConcreteSub.extendedAbstractImplementedMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleMethod,
    Interface2.extendedAbstractImplementedMultipleMethod,
    Super.extendedAbstractImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleMethod
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractImplementedMethod,
  Interface1.extendedAbstractImplementedMultipleMethod,
  Interface2.extendedAbstractImplementedMultipleMethod,
  Super.extendedAbstractImplementedMethod,
  Super.extendedAbstractImplementedMultipleMethod,
  Super.extendedAbstractMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteImplementedMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */
  /*member: ConcreteClass.extendedConcreteImplementedMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedMethod,
    Super.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */

  /*member: ConcreteClass.extendedConcreteImplementedMultipleMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */
  /*member: ConcreteClass.extendedConcreteImplementedMultipleMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleMethod,
    Interface2.extendedConcreteImplementedMultipleMethod,
    Super.extendedConcreteImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleMethod
  */

  /*member: ConcreteClass.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractImplementedMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMethod
  */
  /*member: ConcreteClass.extendedAbstractImplementedMultipleMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleMethod,
    Interface2.extendedAbstractImplementedMultipleMethod,
    Super.extendedAbstractImplementedMultipleMethod],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleMethod
  */
}
