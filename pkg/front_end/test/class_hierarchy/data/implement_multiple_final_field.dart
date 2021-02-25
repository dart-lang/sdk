// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.implementMultipleField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int implementMultipleField = 0;

  /*member: Interface1.declareConcreteImplementMultipleField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int declareConcreteImplementMultipleField = 0;

  /*member: Interface1.declareAbstractImplementMultipleField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int declareAbstractImplementMultipleField = 0;
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementMultipleField#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  final int implementMultipleField = 0;

  /*member: Interface2.declareConcreteImplementMultipleField#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  final int declareConcreteImplementMultipleField = 0;

  /*member: Interface2.declareAbstractImplementMultipleField#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  final int declareAbstractImplementMultipleField = 0;
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declareAbstractImplementMultipleField,
  Interface1.implementMultipleField,
  Interface2.implementMultipleField],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface1, Interface2 {
  /*member: ConcreteClass.implementMultipleField#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementMultipleField,
    Interface2.implementMultipleField],
   isSynthesized,
   member=Interface1.implementMultipleField
  */

  /*member: ConcreteClass.declareConcreteImplementMultipleField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleField,
    Interface2.declareConcreteImplementMultipleField],
   isSourceDeclaration
  */
  final int declareConcreteImplementMultipleField = 0;

  /*member: ConcreteClass.declareAbstractImplementMultipleField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declareAbstractImplementMultipleField,
    Interface1.declareAbstractImplementMultipleField,
    Interface2.declareAbstractImplementMultipleField],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleField,
    Interface2.declareAbstractImplementMultipleField],
   isSynthesized
  */
  abstract final int declareAbstractImplementMultipleField;
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface1, Interface2 {
  /*member: AbstractClass.implementMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleField,
    Interface2.implementMultipleField],
   isSynthesized,
   member=Interface1.implementMultipleField
  */

  /*member: AbstractClass.declareConcreteImplementMultipleField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleField,
    Interface2.declareConcreteImplementMultipleField],
   isSourceDeclaration
  */
  final int declareConcreteImplementMultipleField = 0;

  /*member: AbstractClass.declareAbstractImplementMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleField,
    Interface1.declareAbstractImplementMultipleField,
    Interface2.declareAbstractImplementMultipleField],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleField,
    Interface2.declareAbstractImplementMultipleField],
   isSynthesized
  */
  abstract final int declareAbstractImplementMultipleField;
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.declareAbstractImplementMultipleField,
  AbstractClass.implementMultipleField],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  AbstractClass,
  Object]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.declareConcreteImplementMultipleField#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */

  /*member: ConcreteSub.declareAbstractImplementMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleField,
    Interface1.declareAbstractImplementMultipleField,
    Interface2.declareAbstractImplementMultipleField],
   isSynthesized,
   member=AbstractClass.declareAbstractImplementMultipleField
  */

  /*member: ConcreteSub.implementMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleField,
    Interface2.implementMultipleField],
   isSynthesized,
   member=Interface1.implementMultipleField
  */
}

main() {}
