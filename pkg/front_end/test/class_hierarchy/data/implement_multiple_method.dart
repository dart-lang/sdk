// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.implementMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void implementMultipleMethod() {}

  /*member: Interface1.declareConcreteImplementMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void declareConcreteImplementMultipleMethod() {}

  /*member: Interface1.declareAbstractImplementMultipleMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void declareAbstractImplementMultipleMethod() {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void implementMultipleMethod() {}
  /*member: Interface2.declareConcreteImplementMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void declareConcreteImplementMultipleMethod() {}
  /*member: Interface2.declareAbstractImplementMultipleMethod#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void declareAbstractImplementMultipleMethod() {}
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declareAbstractImplementMultipleMethod,
  Interface1.implementMultipleMethod,
  Interface2.implementMultipleMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface1, Interface2 {
  /*member: ConcreteClass.implementMultipleMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementMultipleMethod,
    Interface2.implementMultipleMethod],
   isSynthesized,
   member=Interface1.implementMultipleMethod
  */

  /*member: ConcreteClass.declareConcreteImplementMultipleMethod#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleMethod,
    Interface2.declareConcreteImplementMultipleMethod],
   isSourceDeclaration
  */
  void declareConcreteImplementMultipleMethod() {}

  /*member: ConcreteClass.declareAbstractImplementMultipleMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declareAbstractImplementMultipleMethod,
    Interface1.declareAbstractImplementMultipleMethod,
    Interface2.declareAbstractImplementMultipleMethod],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleMethod,
    Interface2.declareAbstractImplementMultipleMethod],
   isSynthesized
  */
  void declareAbstractImplementMultipleMethod();
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface1, Interface2 {
  /*member: AbstractClass.implementMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleMethod,
    Interface2.implementMultipleMethod],
   isSynthesized,
   member=Interface1.implementMultipleMethod
  */

  /*member: AbstractClass.declareConcreteImplementMultipleMethod#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleMethod,
    Interface2.declareConcreteImplementMultipleMethod],
   isSourceDeclaration
  */
  void declareConcreteImplementMultipleMethod() {}

  /*member: AbstractClass.declareAbstractImplementMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleMethod,
    Interface1.declareAbstractImplementMultipleMethod,
    Interface2.declareAbstractImplementMultipleMethod],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleMethod,
    Interface2.declareAbstractImplementMultipleMethod],
   isSynthesized
  */
  void declareAbstractImplementMultipleMethod();
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.declareAbstractImplementMultipleMethod,
  AbstractClass.implementMultipleMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  AbstractClass,
  Object]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.declareConcreteImplementMultipleMethod#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */

  /*member: ConcreteSub.declareAbstractImplementMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleMethod,
    Interface1.declareAbstractImplementMultipleMethod,
    Interface2.declareAbstractImplementMultipleMethod],
   isSynthesized,
   member=AbstractClass.declareAbstractImplementMultipleMethod
  */

  /*member: ConcreteSub.implementMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleMethod,
    Interface2.implementMultipleMethod],
   isSynthesized,
   member=Interface1.implementMultipleMethod
  */
}
