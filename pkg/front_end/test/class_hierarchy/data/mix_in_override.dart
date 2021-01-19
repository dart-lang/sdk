// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 abstractMembers=[
  Super.extendedAbstractMethod,
  Super.extendedAbstractMixedInAbstractMethod,
  Super.extendedAbstractMixedInConcreteMethod],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
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

  /*member: Super.extendedConcreteMixedInConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteMixedInConcreteMethod() {}

  /*member: Super.extendedAbstractMixedInConcreteMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractMixedInConcreteMethod();

  /*member: Super.extendedConcreteMixedInAbstractMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedConcreteMixedInAbstractMethod() {}

  /*member: Super.extendedAbstractMixedInAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void extendedAbstractMixedInAbstractMethod();
}

/*class: Mixin:
 abstractMembers=[
  Mixin.extendedAbstractMixedInAbstractMethod,
  Mixin.extendedConcreteMixedInAbstractMethod,
  Mixin.mixedInAbstractMethod],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin {
  /*member: Mixin.mixedInConcreteMethod#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void mixedInConcreteMethod(int i) {}

  /*member: Mixin.mixedInAbstractMethod#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void mixedInAbstractMethod(int i);

  /*member: Mixin.extendedConcreteMixedInConcreteMethod#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void extendedConcreteMixedInConcreteMethod(int i) {}

  /*member: Mixin.extendedAbstractMixedInConcreteMethod#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void extendedAbstractMixedInConcreteMethod(int i) {}

  /*member: Mixin.extendedConcreteMixedInAbstractMethod#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void extendedConcreteMixedInAbstractMethod(int i);

  /*member: Mixin.extendedAbstractMixedInAbstractMethod#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void extendedAbstractMixedInAbstractMethod(int i);
}

/*class: _ClassMixin&Super&Mixin:
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteMethod#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteMethod
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractMethod#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractMethod
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractMethod,
  Super.extendedConcreteMixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractMethod,
  Super.extendedConcreteMixedInAbstractMethod]
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMethod#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: _ClassMixin&Super&Mixin.mixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[Mixin.mixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractMethod]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractMethod,
  Super.extendedAbstractMixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractMethod,
  Super.extendedAbstractMixedInAbstractMethod]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMethod#int:
 classBuilder=Super,
 isSourceDeclaration
*/

/*class: ClassMixin:
 abstractMembers=[
  Super.extendedAbstractMethod,
  _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractMethod,
  _ClassMixin&Super&Mixin.mixedInAbstractMethod],
 interfaces=[Mixin],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Super,
  _ClassMixin&Super&Mixin]
*/
/*member: _ClassMixin&Super&Mixin.mixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteMethod
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteMethod,
  Super.extendedConcreteMixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteMethod
*/
/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteMethod,
  Super.extendedAbstractMixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteMethod
*/
/*member: ClassMixin.mixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[Mixin.mixedInConcreteMethod],
 isSynthesized,
 member=_ClassMixin&Super&Mixin.mixedInConcreteMethod
*/
/*member: ClassMixin.extendedConcreteMixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteMethod,
  Super.extendedConcreteMixedInConcreteMethod],
 isSynthesized,
 member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteMethod
*/
/*member: ClassMixin.extendedAbstractMixedInConcreteMethod#int:
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteMethod,
  Super.extendedAbstractMixedInConcreteMethod],
 isSynthesized,
 member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteMethod
*/
class ClassMixin extends Super with Mixin {
  /*member: ClassMixin.extendedConcreteMixedInConcreteMethod#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteMethod
  */

  /*member: ClassMixin.extendedConcreteMixedInAbstractMethod#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractMethod],
   isSynthesized,
   member=Super.extendedConcreteMixedInAbstractMethod
  */
  /*member: ClassMixin.extendedConcreteMixedInAbstractMethod#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInAbstractMethod,
    Super.extendedConcreteMixedInAbstractMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractMethod
  */

  /*member: ClassMixin.extendedConcreteMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ClassMixin.mixedInAbstractMethod#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInAbstractMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInAbstractMethod
  */

  /*member: ClassMixin.extendedAbstractMixedInAbstractMethod#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInAbstractMethod,
    Super.extendedAbstractMixedInAbstractMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractMethod
  */

  /*member: ClassMixin.extendedAbstractMethod#int:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: _ClassMixin&Super&Mixin.mixedInConcreteMethod#cls:
   classBuilder=_ClassMixin&Super&Mixin,
   concreteMixinStub,
   isSynthesized,
   stubTarget=Mixin.mixedInConcreteMethod
  */

  /*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteMethod#cls:
   classBuilder=_ClassMixin&Super&Mixin,
   concreteMixinStub,
   isSynthesized,
   stubTarget=Mixin.extendedAbstractMixedInConcreteMethod
  */

  /*member: ClassMixin.mixedInConcreteMethod#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.mixedInConcreteMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteMethod
  */

  /*member: ClassMixin.extendedAbstractMixedInConcreteMethod#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteMethod],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteMethod
  */
}

/*class: NamedMixin:
 abstractMembers=[
  NamedMixin.extendedAbstractMixedInAbstractMethod,
  NamedMixin.mixedInAbstractMethod,
  Super.extendedAbstractMethod],
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: NamedMixin.extendedConcreteMixedInConcreteMethod#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedConcreteMixedInConcreteMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInConcreteMethod,
  Super.extendedConcreteMixedInConcreteMethod],
 stubTarget=Mixin.extendedConcreteMixedInConcreteMethod
*/

/*member: NamedMixin.extendedConcreteMixedInAbstractMethod#cls:
 classBuilder=NamedMixin,
 inherited-implements=[NamedMixin.extendedConcreteMixedInAbstractMethod],
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractMethod
*/
/*member: NamedMixin.extendedConcreteMixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractMethod,
  Super.extendedConcreteMixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractMethod,
  Super.extendedConcreteMixedInAbstractMethod]
*/

/*member: NamedMixin.extendedConcreteMethod#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: NamedMixin.mixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[Mixin.mixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractMethod]
*/

/*member: NamedMixin.extendedAbstractMixedInAbstractMethod#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractMethod,
  Super.extendedAbstractMixedInAbstractMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractMethod,
  Super.extendedAbstractMixedInAbstractMethod]
*/

/*member: NamedMixin.extendedAbstractMethod#int:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: NamedMixin.mixedInConcreteMethod#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.mixedInConcreteMethod],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInConcreteMethod],
 stubTarget=Mixin.mixedInConcreteMethod
*/

/*member: NamedMixin.extendedAbstractMixedInConcreteMethod#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedAbstractMixedInConcreteMethod],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInConcreteMethod,
  Super.extendedAbstractMixedInConcreteMethod],
 stubTarget=Mixin.extendedAbstractMixedInConcreteMethod
*/
/*member: NamedMixin.mixedInConcreteMethod#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteMethod
*/
/*member: NamedMixin.extendedConcreteMixedInConcreteMethod#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteMethod,
  Super.extendedConcreteMixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteMethod
*/
/*member: NamedMixin.extendedAbstractMixedInConcreteMethod#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteMethod,
  Super.extendedAbstractMixedInConcreteMethod],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteMethod
*/
class NamedMixin = Super with Mixin;
