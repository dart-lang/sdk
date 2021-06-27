// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteCovariantField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedConcreteCovariantField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  covariant int extendedConcreteCovariantField = 0;

  /*member: Super.extendedAbstractCovariantField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedAbstractCovariantField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract covariant int extendedAbstractCovariantField;

  /*member: Super.extendedConcreteCovariantImplementedField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedConcreteCovariantImplementedField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  covariant int extendedConcreteCovariantImplementedField = 0;

  /*member: Super.extendedAbstractCovariantImplementedField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedAbstractCovariantImplementedField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract covariant int extendedAbstractCovariantImplementedField;

  /*member: Super.extendedConcreteImplementedCovariantField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedConcreteImplementedCovariantField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int extendedConcreteImplementedCovariantField = 0;

  /*member: Super.extendedAbstractImplementedCovariantField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedAbstractImplementedCovariantField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract int extendedAbstractImplementedCovariantField;
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteCovariantImplementedField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.extendedConcreteCovariantImplementedField=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int extendedConcreteCovariantImplementedField = 0;

  /*member: Interface1.extendedAbstractCovariantImplementedField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.extendedAbstractCovariantImplementedField=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int extendedAbstractCovariantImplementedField = 0;

  /*member: Interface1.extendedConcreteImplementedCovariantField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.extendedConcreteImplementedCovariantField=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  covariant int extendedConcreteImplementedCovariantField = 0;

  /*member: Interface1.extendedAbstractImplementedCovariantField#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.extendedAbstractImplementedCovariantField=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  covariant int extendedAbstractImplementedCovariantField = 0;

  /*member: Interface1.implementsMultipleCovariantField1#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.implementsMultipleCovariantField1=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  covariant int implementsMultipleCovariantField1 = 0;

  /*member: Interface1.implementsMultipleCovariantField2#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  /*member: Interface1.implementsMultipleCovariantField2=#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int implementsMultipleCovariantField2 = 0;
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementsMultipleCovariantField1#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  /*member: Interface2.implementsMultipleCovariantField1=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int implementsMultipleCovariantField1 = 0;

  /*member: Interface2.implementsMultipleCovariantField2#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  /*member: Interface2.implementsMultipleCovariantField2=#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  covariant int implementsMultipleCovariantField2 = 0;
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
  /*member: AbstractClass.extendedConcreteCovariantField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: AbstractClass.extendedConcreteCovariantField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteCovariantImplementedField#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: AbstractClass.extendedConcreteCovariantImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField,
    Super.extendedConcreteCovariantImplementedField],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: AbstractClass.extendedConcreteCovariantImplementedField=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: AbstractClass.extendedConcreteCovariantImplementedField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField=,
    Super.extendedConcreteCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */

  /*member: AbstractClass.extendedConcreteImplementedCovariantField#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: AbstractClass.extendedConcreteImplementedCovariantField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField,
    Super.extendedConcreteImplementedCovariantField],
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: AbstractClass.extendedConcreteImplementedCovariantField=#cls:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantField,
   type=int
  */
  /*member: AbstractClass.extendedConcreteImplementedCovariantField=#int:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField=,
    Super.extendedConcreteImplementedCovariantField=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantField,
   type=int
  */

  /*member: AbstractClass.extendedAbstractCovariantField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: AbstractClass.extendedAbstractCovariantField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractCovariantImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField,
    Super.extendedAbstractCovariantImplementedField],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField
  */
  /*member: AbstractClass.extendedAbstractCovariantImplementedField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField=,
    Super.extendedAbstractCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField=
  */

  /*member: AbstractClass.extendedAbstractImplementedCovariantField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField,
    Super.extendedAbstractImplementedCovariantField],
   isSynthesized,
   member=Super.extendedAbstractImplementedCovariantField
  */
  /*member: AbstractClass.extendedAbstractImplementedCovariantField=#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField=,
    Super.extendedAbstractImplementedCovariantField=],
   isSynthesized,
   type=int
  */

  /*member: AbstractClass.implementsMultipleCovariantField1#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1,
    Interface2.implementsMultipleCovariantField1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */
  /*member: AbstractClass.implementsMultipleCovariantField1=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1=,
    Interface2.implementsMultipleCovariantField1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */

  /*member: AbstractClass.implementsMultipleCovariantField2#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField2,
    Interface2.implementsMultipleCovariantField2],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField2
  */
  /*member: AbstractClass.implementsMultipleCovariantField2=#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantField2=,
    Interface2.implementsMultipleCovariantField2=],
   isSynthesized,
   type=int
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractCovariantImplementedField,
  AbstractClass.extendedAbstractCovariantImplementedField=,
  AbstractClass.extendedAbstractImplementedCovariantField,
  AbstractClass.extendedAbstractImplementedCovariantField=,
  AbstractClass.implementsMultipleCovariantField1,
  AbstractClass.implementsMultipleCovariantField1=,
  AbstractClass.implementsMultipleCovariantField2,
  AbstractClass.implementsMultipleCovariantField2=,
  Super.extendedAbstractCovariantField,
  Super.extendedAbstractCovariantField=],
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
  /*member: ConcreteSub.extendedConcreteCovariantField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: ConcreteSub.extendedConcreteCovariantField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteCovariantImplementedField#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteCovariantImplementedField],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteSub.extendedConcreteCovariantImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField,
    Super.extendedConcreteCovariantImplementedField],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteSub.extendedConcreteCovariantImplementedField=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteSub.extendedConcreteCovariantImplementedField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField=,
    Super.extendedConcreteCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */

  /*member: ConcreteSub.extendedConcreteImplementedCovariantField#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedCovariantField],
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: ConcreteSub.extendedConcreteImplementedCovariantField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField,
    Super.extendedConcreteImplementedCovariantField],
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: ConcreteSub.extendedConcreteImplementedCovariantField=#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedCovariantField=],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantField=
  */
  /*member: ConcreteSub.extendedConcreteImplementedCovariantField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField=,
    Super.extendedConcreteImplementedCovariantField=],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantField=
  */

  /*member: ConcreteSub.extendedAbstractCovariantField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: ConcreteSub.extendedAbstractCovariantField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractCovariantImplementedField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField,
    Super.extendedAbstractCovariantImplementedField],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField
  */
  /*member: ConcreteSub.extendedAbstractCovariantImplementedField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField=,
    Super.extendedAbstractCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField=
  */

  /*member: ConcreteSub.extendedAbstractImplementedCovariantField#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField,
    Super.extendedAbstractImplementedCovariantField],
   isSynthesized,
   member=Super.extendedAbstractImplementedCovariantField
  */
  /*member: ConcreteSub.extendedAbstractImplementedCovariantField=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField=,
    Super.extendedAbstractImplementedCovariantField=],
   isSynthesized,
   member=AbstractClass.extendedAbstractImplementedCovariantField=
  */

  /*member: ConcreteSub.implementsMultipleCovariantField1#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1,
    Interface2.implementsMultipleCovariantField1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */
  /*member: ConcreteSub.implementsMultipleCovariantField1=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1=,
    Interface2.implementsMultipleCovariantField1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */

  /*member: ConcreteSub.implementsMultipleCovariantField2#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField2,
    Interface2.implementsMultipleCovariantField2],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField2
  */
  /*member: ConcreteSub.implementsMultipleCovariantField2=#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantField2=,
    Interface2.implementsMultipleCovariantField2=],
   isSynthesized,
   member=AbstractClass.implementsMultipleCovariantField2=
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractCovariantImplementedField,
  Interface1.extendedAbstractCovariantImplementedField=,
  Interface1.extendedAbstractImplementedCovariantField,
  Interface1.extendedAbstractImplementedCovariantField=,
  Interface1.implementsMultipleCovariantField1,
  Interface1.implementsMultipleCovariantField1=,
  Interface1.implementsMultipleCovariantField2,
  Interface1.implementsMultipleCovariantField2=,
  Interface2.implementsMultipleCovariantField1,
  Interface2.implementsMultipleCovariantField1=,
  Interface2.implementsMultipleCovariantField2,
  Interface2.implementsMultipleCovariantField2=,
  Super.extendedAbstractCovariantField,
  Super.extendedAbstractCovariantField=,
  Super.extendedAbstractCovariantImplementedField,
  Super.extendedAbstractCovariantImplementedField=,
  Super.extendedAbstractImplementedCovariantField,
  Super.extendedAbstractImplementedCovariantField=],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteCovariantField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: ConcreteClass.extendedConcreteCovariantField=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteCovariantImplementedField#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteCovariantImplementedField],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteClass.extendedConcreteCovariantImplementedField#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField,
    Super.extendedConcreteCovariantImplementedField],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteClass.extendedConcreteCovariantImplementedField=#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */
  /*member: ConcreteClass.extendedConcreteCovariantImplementedField=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedField=,
    Super.extendedConcreteCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedField
  */

  /*member: ConcreteClass.extendedConcreteImplementedCovariantField#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteImplementedCovariantField],
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: ConcreteClass.extendedConcreteImplementedCovariantField#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField,
    Super.extendedConcreteImplementedCovariantField],
   isSynthesized,
   member=Super.extendedConcreteImplementedCovariantField
  */
  /*member: ConcreteClass.extendedConcreteImplementedCovariantField=#cls:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   inherited-implements=[ConcreteClass.extendedConcreteImplementedCovariantField=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantField,
   type=int
  */
  /*member: ConcreteClass.extendedConcreteImplementedCovariantField=#int:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantField=,
    Super.extendedConcreteImplementedCovariantField=],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantField,
   type=int
  */

  /*member: ConcreteClass.extendedAbstractCovariantField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: ConcreteClass.extendedAbstractCovariantField=#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractCovariantImplementedField#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField,
    Super.extendedAbstractCovariantImplementedField],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField
  */
  /*member: ConcreteClass.extendedAbstractCovariantImplementedField=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedField=,
    Super.extendedAbstractCovariantImplementedField=],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedField=
  */

  /*member: ConcreteClass.extendedAbstractImplementedCovariantField#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField,
    Super.extendedAbstractImplementedCovariantField],
   isSynthesized,
   member=Super.extendedAbstractImplementedCovariantField
  */
  /*member: ConcreteClass.extendedAbstractImplementedCovariantField=#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantField=,
    Super.extendedAbstractImplementedCovariantField=],
   isSynthesized,
   type=int
  */

  /*member: ConcreteClass.implementsMultipleCovariantField1#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1,
    Interface2.implementsMultipleCovariantField1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */
  /*member: ConcreteClass.implementsMultipleCovariantField1=#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementsMultipleCovariantField1=,
    Interface2.implementsMultipleCovariantField1=],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField1
  */

  /*member: ConcreteClass.implementsMultipleCovariantField2#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementsMultipleCovariantField2,
    Interface2.implementsMultipleCovariantField2],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantField2
  */
  /*member: ConcreteClass.implementsMultipleCovariantField2=#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantField2=,
    Interface2.implementsMultipleCovariantField2=],
   isSynthesized,
   type=int
  */
}

main() {}
