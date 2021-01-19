// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 abstractMembers=[
  Super.extendedAbstractGetter,
  Super.extendedAbstractMixedInAbstractGetter,
  Super.extendedAbstractMixedInConcreteGetter],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteGetter => 0;

  /*member: Super.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractGetter;

  /*member: Super.extendedConcreteMixedInConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteMixedInConcreteGetter => 0;

  /*member: Super.extendedAbstractMixedInConcreteGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractMixedInConcreteGetter;

  /*member: Super.extendedConcreteMixedInAbstractGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedConcreteMixedInAbstractGetter => 0;

  /*member: Super.extendedAbstractMixedInAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  int get extendedAbstractMixedInAbstractGetter;
}

/*class: Mixin:
 abstractMembers=[
  Mixin.extendedAbstractMixedInAbstractGetter,
  Mixin.extendedConcreteMixedInAbstractGetter,
  Mixin.mixedInAbstractGetter],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin {
  /*member: Mixin.mixedInConcreteGetter#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get mixedInConcreteGetter => 0;

  /*member: Mixin.mixedInAbstractGetter#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get mixedInAbstractGetter;

  /*member: Mixin.extendedConcreteMixedInConcreteGetter#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get extendedConcreteMixedInConcreteGetter => 0;

  /*member: Mixin.extendedAbstractMixedInConcreteGetter#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get extendedAbstractMixedInConcreteGetter => 0;

  /*member: Mixin.extendedConcreteMixedInAbstractGetter#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get extendedConcreteMixedInAbstractGetter;

  /*member: Mixin.extendedAbstractMixedInAbstractGetter#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  int get extendedAbstractMixedInAbstractGetter;
}

/*class: _ClassMixin&Super&Mixin:
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: _ClassMixin&Super&Mixin.mixedInConcreteGetter#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteGetter
*/
/*member: _ClassMixin&Super&Mixin.mixedInConcreteGetter#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteGetter
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteGetter#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteGetter
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteGetter#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteGetter,
  Super.extendedConcreteMixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteGetter
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteGetter#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteGetter
*/
/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteGetter#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteGetter,
  Super.extendedAbstractMixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteGetter
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractGetter#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractGetter
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractGetter,
  Super.extendedConcreteMixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractGetter,
  Super.extendedConcreteMixedInAbstractGetter]
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteGetter#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: _ClassMixin&Super&Mixin.mixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[Mixin.mixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractGetter]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractGetter,
  Super.extendedAbstractMixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractGetter,
  Super.extendedAbstractMixedInAbstractGetter]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractGetter#int:
 classBuilder=Super,
 isSourceDeclaration
*/

/*class: ClassMixin:
 abstractMembers=[
  Super.extendedAbstractGetter,
  _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractGetter,
  _ClassMixin&Super&Mixin.mixedInAbstractGetter],
 interfaces=[Mixin],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Super,
  _ClassMixin&Super&Mixin]
*/
class ClassMixin extends Super with Mixin {
  /*member: ClassMixin.mixedInConcreteGetter#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.mixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteGetter
  */
  /*member: ClassMixin.mixedInConcreteGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteGetter
  */

  /*member: ClassMixin.extendedConcreteMixedInConcreteGetter#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteGetter
  */
  /*member: ClassMixin.extendedConcreteMixedInConcreteGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInConcreteGetter,
    Super.extendedConcreteMixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteGetter
  */

  /*member: ClassMixin.extendedAbstractMixedInConcreteGetter#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteGetter
  */
  /*member: ClassMixin.extendedAbstractMixedInConcreteGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInConcreteGetter,
    Super.extendedAbstractMixedInConcreteGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteGetter
  */

  /*member: ClassMixin.extendedConcreteMixedInAbstractGetter#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractGetter],
   isSynthesized,
   member=Super.extendedConcreteMixedInAbstractGetter
  */
  /*member: ClassMixin.extendedConcreteMixedInAbstractGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInAbstractGetter,
    Super.extendedConcreteMixedInAbstractGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractGetter
  */

  /*member: ClassMixin.extendedConcreteGetter#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ClassMixin.mixedInAbstractGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInAbstractGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInAbstractGetter
  */

  /*member: ClassMixin.extendedAbstractMixedInAbstractGetter#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInAbstractGetter,
    Super.extendedAbstractMixedInAbstractGetter],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractGetter
  */

  /*member: ClassMixin.extendedAbstractGetter#int:
   classBuilder=Super,
   isSourceDeclaration
  */
}

/*class: NamedMixin:
 abstractMembers=[
  NamedMixin.extendedAbstractMixedInAbstractGetter,
  NamedMixin.mixedInAbstractGetter,
  Super.extendedAbstractGetter],
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: NamedMixin.mixedInConcreteGetter#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.mixedInConcreteGetter],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInConcreteGetter],
 stubTarget=Mixin.mixedInConcreteGetter
*/
/*member: NamedMixin.mixedInConcreteGetter#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteGetter
*/
/*member: NamedMixin.mixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[Mixin.mixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractGetter]
*/

/*member: NamedMixin.extendedConcreteMixedInConcreteGetter#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedConcreteMixedInConcreteGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInConcreteGetter,
  Super.extendedConcreteMixedInConcreteGetter],
 stubTarget=Mixin.extendedConcreteMixedInConcreteGetter
*/
/*member: NamedMixin.extendedConcreteMixedInConcreteGetter#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteGetter,
  Super.extendedConcreteMixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteGetter
*/

/*member: NamedMixin.extendedAbstractMixedInConcreteGetter#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedAbstractMixedInConcreteGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInConcreteGetter,
  Super.extendedAbstractMixedInConcreteGetter],
 stubTarget=Mixin.extendedAbstractMixedInConcreteGetter
*/
/*member: NamedMixin.extendedAbstractMixedInConcreteGetter#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteGetter,
  Super.extendedAbstractMixedInConcreteGetter],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteGetter
*/

/*member: NamedMixin.extendedConcreteMixedInAbstractGetter#cls:
 classBuilder=NamedMixin,
 inherited-implements=[NamedMixin.extendedConcreteMixedInAbstractGetter],
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractGetter
*/
/*member: NamedMixin.extendedConcreteMixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractGetter,
  Super.extendedConcreteMixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractGetter,
  Super.extendedConcreteMixedInAbstractGetter]
*/

/*member: NamedMixin.extendedConcreteGetter#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: NamedMixin.extendedAbstractMixedInAbstractGetter#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractGetter,
  Super.extendedAbstractMixedInAbstractGetter],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractGetter,
  Super.extendedAbstractMixedInAbstractGetter]
*/

/*member: NamedMixin.extendedAbstractGetter#int:
 classBuilder=Super,
 isSourceDeclaration
*/
class NamedMixin = Super with Mixin;

main() {}
