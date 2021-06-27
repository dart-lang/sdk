// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'lib.dart';

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
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteMethod
  */
  /*member: AbstractClass.extendedConcreteMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[Super.extendedConcreteMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: AbstractClass.extendedAbstractMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[Super.extendedAbstractMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: AbstractClass.extendedConcreteImplementedMethod#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */
  /*member: AbstractClass.extendedConcreteImplementedMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.extendedConcreteImplementedMethod,
    Super.extendedConcreteImplementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: AbstractClass.extendedAbstractImplementedMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: AbstractClass.implementedMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[Interface1.implementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: AbstractClass.implementedMultipleMethod#int:
   classBuilder=AbstractClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.implementedMultipleMethod,
    Interface2.implementedMultipleMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractImplementedMethod,
  AbstractClass.extendedAbstractMethod,
  AbstractClass.implementedMethod,
  AbstractClass.implementedMultipleMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  Super,
  AbstractClass,
  Object]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.extendedConcreteMethod#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteMethod],
   isSynthesized,
   member=Super.extendedConcreteMethod
  */
  /*member: ConcreteSub.extendedConcreteMethod#int:
   classBuilder=AbstractClass,
   declarations=[Super.extendedConcreteMethod],
   isSynthesized,
   member=AbstractClass.extendedConcreteMethod
  */

  /*member: ConcreteSub.extendedAbstractMethod#int:
   classBuilder=AbstractClass,
   declarations=[Super.extendedAbstractMethod],
   isSynthesized,
   member=AbstractClass.extendedAbstractMethod
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
   member=AbstractClass.extendedConcreteImplementedMethod
  */

  /*member: ConcreteSub.extendedAbstractImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   member=AbstractClass.extendedAbstractImplementedMethod
  */

  /*member: ConcreteSub.implementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[Interface1.implementedMethod],
   isSynthesized,
   member=AbstractClass.implementedMethod
  */

  /*member: ConcreteSub.implementedMultipleMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementedMultipleMethod,
    Interface2.implementedMultipleMethod],
   isSynthesized,
   member=AbstractClass.implementedMultipleMethod
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Super.extendedAbstractImplementedMethod,
  Super.extendedAbstractMethod,
  Interface1.extendedAbstractImplementedMethod,
  Interface1.implementedMethod,
  Interface1.implementedMultipleMethod,
  Interface2.implementedMultipleMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Super,
  Object]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteMethod],
   isSynthesized,
   member=Super.extendedConcreteMethod
  */
  /*member: ConcreteClass.extendedConcreteMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[Super.extendedConcreteMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: ConcreteClass.extendedAbstractMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[Super.extendedAbstractMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: ConcreteClass.extendedConcreteImplementedMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteImplementedMethod
  */
  /*member: ConcreteClass.extendedConcreteImplementedMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.extendedConcreteImplementedMethod,
    Super.extendedConcreteImplementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: ConcreteClass.extendedAbstractImplementedMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.extendedAbstractImplementedMethod,
    Super.extendedAbstractImplementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: ConcreteClass.implementedMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[Interface1.implementedMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */

  /*member: ConcreteClass.implementedMultipleMethod#int:
   classBuilder=ConcreteClass,
   covariance=Covariance.empty(),
   declarations=[
    Interface1.implementedMultipleMethod,
    Interface2.implementedMultipleMethod],
   isSynthesized,
   memberSignature,
   type=void Function(int*)*
  */
}

/*class: OptOutInterface:
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
/*member: OptOutInterface.extendedConcreteImplementedMethod#cls:
 classBuilder=OptOutInterface,
 isSynthesized,
 member=Super.extendedConcreteImplementedMethod
*/
/*member: OptOutInterface.extendedConcreteImplementedMethod#int:
 classBuilder=OptOutInterface,
 covariance=Covariance.empty(),
 declarations=[Super.extendedConcreteImplementedMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: OptOutInterface.extendedAbstractImplementedMethod#int:
 classBuilder=OptOutInterface,
 covariance=Covariance.empty(),
 declarations=[Super.extendedAbstractImplementedMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: OptOutInterface.extendedConcreteMethod#cls:
 classBuilder=OptOutInterface,
 isSynthesized,
 member=Super.extendedConcreteMethod
*/
/*member: OptOutInterface.extendedConcreteMethod#int:
 classBuilder=OptOutInterface,
 covariance=Covariance.empty(),
 declarations=[Super.extendedConcreteMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: OptOutInterface.extendedAbstractMethod#int:
 classBuilder=OptOutInterface,
 covariance=Covariance.empty(),
 declarations=[Super.extendedAbstractMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
abstract class OptOutInterface extends Super {}

/*class: ClassImplementsOptOut:
 interfaces=[OptOutInterface],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Super]
*/
/*member: ClassImplementsOptOut.extendedConcreteImplementedMethod#int:
 classBuilder=ClassImplementsOptOut,
 covariance=Covariance.empty(),
 declarations=[
  OptOutInterface.extendedConcreteImplementedMethod,
  Super.extendedConcreteImplementedMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: ClassImplementsOptOut.extendedAbstractImplementedMethod#int:
 classBuilder=ClassImplementsOptOut,
 covariance=Covariance.empty(),
 declarations=[
  OptOutInterface.extendedAbstractImplementedMethod,
  Super.extendedAbstractImplementedMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: ClassImplementsOptOut.extendedConcreteMethod#cls:
 classBuilder=ClassImplementsOptOut,
 isSynthesized,
 member=Super.extendedConcreteMethod
*/
/*member: ClassImplementsOptOut.extendedConcreteImplementedMethod#cls:
 classBuilder=ClassImplementsOptOut,
 isSynthesized,
 member=Super.extendedConcreteImplementedMethod
*/
/*member: ClassImplementsOptOut.extendedConcreteMethod#int:
 classBuilder=ClassImplementsOptOut,
 covariance=Covariance.empty(),
 declarations=[
  OptOutInterface.extendedConcreteMethod,
  Super.extendedConcreteMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
/*member: ClassImplementsOptOut.extendedAbstractMethod#int:
 classBuilder=ClassImplementsOptOut,
 covariance=Covariance.empty(),
 declarations=[
  OptOutInterface.extendedAbstractMethod,
  Super.extendedAbstractMethod],
 isSynthesized,
 memberSignature,
 type=void Function(int*)*
*/
abstract class ClassImplementsOptOut extends Super implements OptOutInterface {}
