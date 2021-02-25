// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteCovariantSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteCovariantSetter(covariant int i) {}

  /*member: Super.extendedAbstractCovariantSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractCovariantSetter(covariant int i);

  /*member: Super.extendedConcreteCovariantImplementedSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteCovariantImplementedSetter(covariant int i) {}

  /*member: Super.extendedAbstractCovariantImplementedSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractCovariantImplementedSetter(covariant int i);

  /*member: Super.extendedConcreteImplementedCovariantSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedCovariantSetter(int i) {}

  /*member: Super.extendedAbstractImplementedCovariantSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedCovariantSetter(int i);
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteCovariantImplementedSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedConcreteCovariantImplementedSetter(int i) {}

  /*member: Interface1.extendedAbstractCovariantImplementedSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedAbstractCovariantImplementedSetter(int i) {}

  /*member: Interface1.extendedConcreteImplementedCovariantSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedConcreteImplementedCovariantSetter(covariant int i) {}

  /*member: Interface1.extendedAbstractImplementedCovariantSetter=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set extendedAbstractImplementedCovariantSetter(covariant int i) {}

  /*member: Interface1.implementsMultipleCovariantSetter1=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set implementsMultipleCovariantSetter1(covariant int i) {}

  /*member: Interface1.implementsMultipleCovariantSetter2=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void set implementsMultipleCovariantSetter2(int i) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementsMultipleCovariantSetter1=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set implementsMultipleCovariantSetter1(int i) {}

  /*member: Interface2.implementsMultipleCovariantSetter2=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void set implementsMultipleCovariantSetter2(covariant int i) {}
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
  /*member: AbstractClass.extendedConcreteCovariantSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteCovariantImplementedSetter=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */
  /*member: AbstractClass.extendedConcreteCovariantImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedSetter=,
    Super.extendedConcreteCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */

  /*member: AbstractClass.extendedConcreteImplementedCovariantSetter=#cls:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantSetter=,
   type=int
  */
  /*member: AbstractClass.extendedConcreteImplementedCovariantSetter=#int:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantSetter=,
    Super.extendedConcreteImplementedCovariantSetter=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantSetter=,
   type=int
  */

  /*member: AbstractClass.extendedAbstractCovariantSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractCovariantImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedSetter=,
    Super.extendedAbstractCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedSetter=
  */

  /*member: AbstractClass.extendedAbstractImplementedCovariantSetter=#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantSetter=,
    Super.extendedAbstractImplementedCovariantSetter=],
   isSynthesized,
   type=int
  */

  /*member: AbstractClass.implementsMultipleCovariantSetter1=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantSetter1=,
    Interface2.implementsMultipleCovariantSetter1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantSetter1=
  */

  /*member: AbstractClass.implementsMultipleCovariantSetter2=#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantSetter2=,
    Interface2.implementsMultipleCovariantSetter2=],
   isSynthesized,
   type=int
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractCovariantImplementedSetter=,
  AbstractClass.extendedAbstractImplementedCovariantSetter=,
  AbstractClass.implementsMultipleCovariantSetter1=,
  AbstractClass.implementsMultipleCovariantSetter2=,
  Super.extendedAbstractCovariantSetter=],
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
  /*member: ConcreteSub.extendedConcreteCovariantSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteCovariantImplementedSetter=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */
  /*member: ConcreteSub.extendedConcreteCovariantImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedSetter=,
    Super.extendedConcreteCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */

  /*member: ConcreteSub.extendedConcreteImplementedCovariantSetter=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedCovariantSetter=],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantSetter=
  */
  /*member: ConcreteSub.extendedConcreteImplementedCovariantSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantSetter=,
    Super.extendedConcreteImplementedCovariantSetter=],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantSetter=
  */

  /*member: ConcreteSub.extendedAbstractCovariantSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractCovariantImplementedSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedSetter=,
    Super.extendedAbstractCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedSetter=
  */

  /*member: ConcreteSub.extendedAbstractImplementedCovariantSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantSetter=,
    Super.extendedAbstractImplementedCovariantSetter=],
   isSynthesized,
   member=AbstractClass.extendedAbstractImplementedCovariantSetter=
  */

  /*member: ConcreteSub.implementsMultipleCovariantSetter1=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantSetter1=,
    Interface2.implementsMultipleCovariantSetter1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantSetter1=
  */

  /*member: ConcreteSub.implementsMultipleCovariantSetter2=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantSetter2=,
    Interface2.implementsMultipleCovariantSetter2=],
   isSynthesized,
   member=AbstractClass.implementsMultipleCovariantSetter2=
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractCovariantImplementedSetter=,
  Interface1.extendedAbstractImplementedCovariantSetter=,
  Interface1.implementsMultipleCovariantSetter1=,
  Interface1.implementsMultipleCovariantSetter2=,
  Interface2.implementsMultipleCovariantSetter1=,
  Interface2.implementsMultipleCovariantSetter2=,
  Super.extendedAbstractCovariantImplementedSetter=,
  Super.extendedAbstractCovariantSetter=,
  Super.extendedAbstractImplementedCovariantSetter=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteCovariantSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteCovariantImplementedSetter=#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */
  /*member: ConcreteClass.extendedConcreteCovariantImplementedSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedSetter=,
    Super.extendedConcreteCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedSetter=
  */

  /*member: ConcreteClass.extendedConcreteImplementedCovariantSetter=#cls:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   inherited-implements=[ConcreteClass.extendedConcreteImplementedCovariantSetter=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantSetter=,
   type=int
  */
  /*member: ConcreteClass.extendedConcreteImplementedCovariantSetter=#int:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantSetter=,
    Super.extendedConcreteImplementedCovariantSetter=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantSetter=,
   type=int
  */

  /*member: ConcreteClass.extendedAbstractCovariantSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractCovariantImplementedSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedSetter=,
    Super.extendedAbstractCovariantImplementedSetter=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedSetter=
  */

  /*member: ConcreteClass.extendedAbstractImplementedCovariantSetter=#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantSetter=,
    Super.extendedAbstractImplementedCovariantSetter=],
   isSynthesized,
   type=int
  */

  /*member: ConcreteClass.implementsMultipleCovariantSetter1=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementsMultipleCovariantSetter1=,
    Interface2.implementsMultipleCovariantSetter1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantSetter1=
  */

  /*member: ConcreteClass.implementsMultipleCovariantSetter2=#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantSetter2=,
    Interface2.implementsMultipleCovariantSetter2=],
   isSynthesized,
   type=int
  */
}

main() {}
