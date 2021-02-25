// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Super {
  /*member: Super.extendedConcreteCovariantMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteCovariantMethod(covariant int i) {}

  /*member: Super.extendedAbstractCovariantMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractCovariantMethod(covariant int i);

  /*member: Super.extendedConcreteCovariantImplementedMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteCovariantImplementedMethod(covariant int i) {}

  /*member: Super.extendedAbstractCovariantImplementedMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractCovariantImplementedMethod(covariant int i);

  /*member: Super.extendedConcreteImplementedCovariantMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteImplementedCovariantMethod(int i) {}

  /*member: Super.extendedAbstractImplementedCovariantMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractImplementedCovariantMethod(int i);
}

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.extendedConcreteCovariantImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedConcreteCovariantImplementedMethod(int i) {}

  /*member: Interface1.extendedAbstractCovariantImplementedMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedAbstractCovariantImplementedMethod(int i) {}

  /*member: Interface1.extendedConcreteImplementedCovariantMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedConcreteImplementedCovariantMethod(covariant int i) {}

  /*member: Interface1.extendedAbstractImplementedCovariantMethod#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void extendedAbstractImplementedCovariantMethod(covariant int i) {}

  /*member: Interface1.implementsMultipleCovariantMethod1#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */

  void implementsMultipleCovariantMethod1(covariant int i) {}
  /*member: Interface1.implementsMultipleCovariantMethod2#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void implementsMultipleCovariantMethod2(int i) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementsMultipleCovariantMethod1#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */

  void implementsMultipleCovariantMethod1(int i) {}
  /*member: Interface2.implementsMultipleCovariantMethod2#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void implementsMultipleCovariantMethod2(covariant int i) {}
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
  /*member: AbstractClass.extendedConcreteCovariantMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractCovariantMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedConcreteCovariantImplementedMethod#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */
  /*member: AbstractClass.extendedConcreteCovariantImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedMethod,
    Super.extendedConcreteCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */

  /*member: AbstractClass.extendedAbstractImplementedCovariantMethod#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantMethod,
    Super.extendedAbstractImplementedCovariantMethod],
   isSynthesized,
   type=void Function(int)
  */
  /*member: AbstractClass.extendedAbstractCovariantImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedMethod,
    Super.extendedAbstractCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedMethod
  */

  /*member: AbstractClass.extendedConcreteImplementedCovariantMethod#cls:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantMethod,
   type=void Function(int)
  */
  /*member: AbstractClass.extendedConcreteImplementedCovariantMethod#int:
   classBuilder=AbstractClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantMethod,
    Super.extendedConcreteImplementedCovariantMethod],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantMethod,
   type=void Function(int)
  */

  /*member: AbstractClass.implementsMultipleCovariantMethod1#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantMethod1,
    Interface2.implementsMultipleCovariantMethod1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantMethod1
  */

  /*member: AbstractClass.implementsMultipleCovariantMethod2#int:
   abstractForwardingStub,
   classBuilder=AbstractClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantMethod2,
    Interface2.implementsMultipleCovariantMethod2],
   isSynthesized,
   type=void Function(int)
  */
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.extendedAbstractCovariantImplementedMethod,
  AbstractClass.extendedAbstractImplementedCovariantMethod,
  AbstractClass.implementsMultipleCovariantMethod1,
  AbstractClass.implementsMultipleCovariantMethod2,
  Super.extendedAbstractCovariantMethod],
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
  /*member: ConcreteSub.extendedConcreteCovariantMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedAbstractCovariantMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteSub.extendedConcreteCovariantImplementedMethod#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */
  /*member: ConcreteSub.extendedConcreteCovariantImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedMethod,
    Super.extendedConcreteCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */

  /*member: ConcreteSub.extendedAbstractCovariantImplementedMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedMethod,
    Super.extendedAbstractCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedMethod
  */

  /*member: ConcreteSub.extendedConcreteImplementedCovariantMethod#cls:
   classBuilder=ConcreteSub,
   inherited-implements=[AbstractClass.extendedConcreteImplementedCovariantMethod],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantMethod
  */
  /*member: ConcreteSub.extendedConcreteImplementedCovariantMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedConcreteImplementedCovariantMethod,
    Super.extendedConcreteImplementedCovariantMethod],
   isSynthesized,
   member=AbstractClass.extendedConcreteImplementedCovariantMethod
  */

  /*member: ConcreteSub.extendedAbstractImplementedCovariantMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.extendedAbstractImplementedCovariantMethod,
    Super.extendedAbstractImplementedCovariantMethod],
   isSynthesized,
   member=AbstractClass.extendedAbstractImplementedCovariantMethod
  */

  /*member: ConcreteSub.implementsMultipleCovariantMethod1#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantMethod1,
    Interface2.implementsMultipleCovariantMethod1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantMethod1
  */

  /*member: ConcreteSub.implementsMultipleCovariantMethod2#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementsMultipleCovariantMethod2,
    Interface2.implementsMultipleCovariantMethod2],
   isSynthesized,
   member=AbstractClass.implementsMultipleCovariantMethod2
  */
}

/*class: ConcreteClass:
 abstractMembers=[
  Interface1.extendedAbstractCovariantImplementedMethod,
  Interface1.extendedAbstractImplementedCovariantMethod,
  Interface1.implementsMultipleCovariantMethod1,
  Interface1.implementsMultipleCovariantMethod2,
  Interface2.implementsMultipleCovariantMethod1,
  Interface2.implementsMultipleCovariantMethod2,
  Super.extendedAbstractCovariantImplementedMethod,
  Super.extendedAbstractCovariantMethod,
  Super.extendedAbstractImplementedCovariantMethod],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class ConcreteClass extends Super implements Interface1, Interface2 {
  /*member: ConcreteClass.extendedConcreteCovariantMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractCovariantMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedConcreteCovariantImplementedMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.extendedConcreteCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */
  /*member: ConcreteClass.extendedConcreteCovariantImplementedMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedConcreteCovariantImplementedMethod,
    Super.extendedConcreteCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedConcreteCovariantImplementedMethod
  */

  /*member: ConcreteClass.extendedAbstractCovariantImplementedMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.extendedAbstractCovariantImplementedMethod,
    Super.extendedAbstractCovariantImplementedMethod],
   isSynthesized,
   member=Super.extendedAbstractCovariantImplementedMethod
  */

  /*member: ConcreteClass.extendedConcreteImplementedCovariantMethod#cls:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   inherited-implements=[ConcreteClass.extendedConcreteImplementedCovariantMethod],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantMethod,
   type=void Function(int)
  */
  /*member: ConcreteClass.extendedConcreteImplementedCovariantMethod#int:
   classBuilder=ConcreteClass,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedConcreteImplementedCovariantMethod,
    Super.extendedConcreteImplementedCovariantMethod],
   isSynthesized,
   stubTarget=Super.extendedConcreteImplementedCovariantMethod,
   type=void Function(int)
  */

  /*member: ConcreteClass.extendedAbstractImplementedCovariantMethod#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.extendedAbstractImplementedCovariantMethod,
    Super.extendedAbstractImplementedCovariantMethod],
   isSynthesized,
   type=void Function(int)
  */

  /*member: ConcreteClass.implementsMultipleCovariantMethod1#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementsMultipleCovariantMethod1,
    Interface2.implementsMultipleCovariantMethod1],
   isSynthesized,
   member=Interface1.implementsMultipleCovariantMethod1
  */

  /*member: ConcreteClass.implementsMultipleCovariantMethod2#int:
   abstractForwardingStub,
   classBuilder=ConcreteClass,
   covariance=Covariance(0:Covariant),
   declarations=[
    Interface1.implementsMultipleCovariantMethod2,
    Interface2.implementsMultipleCovariantMethod2],
   isSynthesized,
   type=void Function(int)
  */
}
