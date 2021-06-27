// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.implementMultipleGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get implementMultipleGetter => 0;

  /*member: Interface1.declareConcreteImplementMultipleGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get declareConcreteImplementMultipleGetter => 0;

  /*member: Interface1.declareAbstractImplementMultipleGetter#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  int get declareAbstractImplementMultipleGetter => 0;
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.implementMultipleGetter#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int get implementMultipleGetter => 0;

  /*member: Interface2.declareConcreteImplementMultipleGetter#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int get declareConcreteImplementMultipleGetter => 0;

  /*member: Interface2.declareAbstractImplementMultipleGetter#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  int get declareAbstractImplementMultipleGetter => 0;
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declareAbstractImplementMultipleGetter,
  Interface1.implementMultipleGetter,
  Interface2.implementMultipleGetter],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class ConcreteClass implements Interface1, Interface2 {
  /*member: ConcreteClass.implementMultipleGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    Interface1.implementMultipleGetter,
    Interface2.implementMultipleGetter],
   isSynthesized,
   member=Interface1.implementMultipleGetter
  */

  /*member: ConcreteClass.declareConcreteImplementMultipleGetter#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleGetter,
    Interface2.declareConcreteImplementMultipleGetter],
   isSourceDeclaration
  */
  int get declareConcreteImplementMultipleGetter => 0;

  /*member: ConcreteClass.declareAbstractImplementMultipleGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declareAbstractImplementMultipleGetter,
    Interface1.declareAbstractImplementMultipleGetter,
    Interface2.declareAbstractImplementMultipleGetter],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleGetter,
    Interface2.declareAbstractImplementMultipleGetter],
   isSynthesized
  */
  int get declareAbstractImplementMultipleGetter;
}

/*class: AbstractClass:
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=2,
 superclasses=[Object]
*/
abstract class AbstractClass implements Interface1, Interface2 {
  /*member: AbstractClass.implementMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleGetter,
    Interface2.implementMultipleGetter],
   isSynthesized,
   member=Interface1.implementMultipleGetter
  */

  /*member: AbstractClass.declareConcreteImplementMultipleGetter#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    Interface1.declareConcreteImplementMultipleGetter,
    Interface2.declareConcreteImplementMultipleGetter],
   isSourceDeclaration
  */
  int get declareConcreteImplementMultipleGetter => 0;

  /*member: AbstractClass.declareAbstractImplementMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleGetter,
    Interface1.declareAbstractImplementMultipleGetter,
    Interface2.declareAbstractImplementMultipleGetter],
   declared-overrides=[
    Interface1.declareAbstractImplementMultipleGetter,
    Interface2.declareAbstractImplementMultipleGetter],
   isSynthesized
  */
  int get declareAbstractImplementMultipleGetter;
}

/*class: ConcreteSub:
 abstractMembers=[
  AbstractClass.declareAbstractImplementMultipleGetter,
  AbstractClass.implementMultipleGetter],
 interfaces=[
  Interface1,
  Interface2],
 maxInheritancePath=3,
 superclasses=[
  AbstractClass,
  Object]
*/
class ConcreteSub extends AbstractClass {
  /*member: ConcreteSub.declareConcreteImplementMultipleGetter#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */

  /*member: ConcreteSub.declareAbstractImplementMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declareAbstractImplementMultipleGetter,
    Interface1.declareAbstractImplementMultipleGetter,
    Interface2.declareAbstractImplementMultipleGetter],
   isSynthesized,
   member=AbstractClass.declareAbstractImplementMultipleGetter
  */

  /*member: ConcreteSub.implementMultipleGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    Interface1.implementMultipleGetter,
    Interface2.implementMultipleGetter],
   isSynthesized,
   member=Interface1.implementMultipleGetter
  */
}

main() {}
