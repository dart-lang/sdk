// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  final int extendedConcreteField = 0;

  /*member: Super.extendedAbstractField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract final int extendedAbstractField;

  /*member: Super.extendedConcreteImplementedField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  final int extendedConcreteImplementedField = 0;

  /*member: Super.extendedAbstractImplementedField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract final int extendedAbstractImplementedField;

  /*member: Super.extendedConcreteImplementedMultipleField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  final int extendedConcreteImplementedMultipleField = 0;

  /*member: Super.extendedAbstractImplementedMultipleField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract final int extendedAbstractImplementedMultipleField;
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteImplementedField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int extendedConcreteImplementedField = 0;

  /*member: Interface1.extendedAbstractImplementedField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int extendedAbstractImplementedField = 0;

  /*member: Interface1.extendedConcreteImplementedMultipleField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int extendedConcreteImplementedMultipleField = 0;

  /*member: Interface1.extendedAbstractImplementedMultipleField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  final int extendedAbstractImplementedMultipleField = 0;
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.extendedConcreteImplementedMultipleField#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  final int extendedConcreteImplementedMultipleField = 0;

  /*member: Interface2.extendedAbstractImplementedMultipleField#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  final int extendedAbstractImplementedMultipleField = 0;
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
  /*member: AbstractClass.extendedConcreteField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteImplementedField#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedField
  */
  /*member: AbstractClass.extendedConcreteImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedField,
    Super.extendedConcreteImplementedField],
   isSynthesized,
   member=Super.extendedConcreteImplementedField
  */

  /*member: AbstractClass.extendedConcreteImplementedMultipleField#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleField
  */
  /*member: AbstractClass.extendedConcreteImplementedMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleField,
    Interface2.extendedConcreteImplementedMultipleField,
    Super.extendedConcreteImplementedMultipleField],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleField
  */

  /*member: AbstractClass.extendedAbstractImplementedMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleField,
    Interface2.extendedAbstractImplementedMultipleField,
    Super.extendedAbstractImplementedMultipleField],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleField
  */

  /*member: AbstractClass.extendedAbstractField#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedField,
    Super.extendedAbstractImplementedField],
   isSynthesized,
   member=Super.extendedAbstractImplementedField
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractImplementedField,
  AbstractClass.extendedAbstractImplementedMultipleField,
  Super.extendedAbstractField],
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
  /*member: ConcreteSub.extendedConcreteField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteImplementedField#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedField],
   isSynthesized,
   member=Super.extendedConcreteImplementedField
  */
  /*member: ConcreteSub.extendedConcreteImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedField,
    Super.extendedConcreteImplementedField],
   isSynthesized,
   member=Super.extendedConcreteImplementedField
  */

  /*member: ConcreteSub.extendedConcreteImplementedMultipleField#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedMultipleField],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleField
  */
  /*member: ConcreteSub.extendedConcreteImplementedMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedMultipleField,
    Interface2.extendedConcreteImplementedMultipleField,
    Super.extendedConcreteImplementedMultipleField],
   isSynthesized,
   member=Super.extendedConcreteImplementedMultipleField
  */

  /*member: ConcreteSub.extendedAbstractImplementedMultipleField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMultipleField,
    Interface2.extendedAbstractImplementedMultipleField,
    Super.extendedAbstractImplementedMultipleField],
   isSynthesized,
   member=Super.extendedAbstractImplementedMultipleField
  */

  /*member: ConcreteSub.extendedAbstractField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: ConcreteSub.extendedAbstractImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedField,
    Super.extendedAbstractImplementedField],
   isSynthesized,
   member=Super.extendedAbstractImplementedField
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractImplementedField,
  Interface1.extendedAbstractImplementedMultipleField,
  Interface2.extendedAbstractImplementedMultipleField,
  Super.extendedAbstractField,
  Super.extendedAbstractImplementedField,
  Super.extendedAbstractImplementedMultipleField],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
/*member: ConcreteClass.extendedConcreteField#cls:
 classBuilder=Super,
 isSourceDeclaration
*/
/*member: ConcreteClass.extendedConcreteImplementedField#cls:
 classBuilder=ConcreteClass,
 inherited-implements=[ConcreteClass.extendedConcreteImplementedField],
 isSynthesized,
 member=Super.extendedConcreteImplementedField
*/
/*member: ConcreteClass.extendedConcreteImplementedMultipleField#cls:
 classBuilder=ConcreteClass,
 inherited-implements=[ConcreteClass.extendedConcreteImplementedMultipleField],
 isSynthesized,
 member=Super.extendedConcreteImplementedMultipleField
*/
/*member: ConcreteClass.extendedConcreteImplementedField#int:
 classBuilder=ConcreteClass,
 declarations=[
  Interface1.extendedConcreteImplementedField,
  Super.extendedConcreteImplementedField],
 isSynthesized,
 member=Super.extendedConcreteImplementedField
*/
/*member: ConcreteClass.extendedConcreteImplementedMultipleField#int:
 classBuilder=ConcreteClass,
 declarations=[
  Interface1.extendedConcreteImplementedMultipleField,
  Interface2.extendedConcreteImplementedMultipleField,
  Super.extendedConcreteImplementedMultipleField],
 isSynthesized,
 member=Super.extendedConcreteImplementedMultipleField
*/
/*member: ConcreteClass.extendedAbstractImplementedMultipleField#int:
 classBuilder=ConcreteClass,
 declarations=[
  Interface1.extendedAbstractImplementedMultipleField,
  Interface2.extendedAbstractImplementedMultipleField,
  Super.extendedAbstractImplementedMultipleField],
 isSynthesized,
 member=Super.extendedAbstractImplementedMultipleField
*/
/*member: ConcreteClass.extendedAbstractField#int:
 classBuilder=Super,
 isSourceDeclaration
*/
/*member: ConcreteClass.extendedAbstractImplementedField#int:
 classBuilder=ConcreteClass,
 declarations=[
  Interface1.extendedAbstractImplementedField,
  Super.extendedAbstractImplementedField],
 isSynthesized,
 member=Super.extendedAbstractImplementedField
*/
class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
