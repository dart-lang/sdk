// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 abstractMembers=[
  Super.extendedAbstractMixedInAbstractSetter=,
  Super.extendedAbstractMixedInConcreteSetter=,
  Super.extendedAbstractSetter=],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteSetter(int i) {}

  /*member: Super.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractSetter(int i);

  /*member: Super.extendedConcreteMixedInConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteMixedInConcreteSetter(int i) {}

  /*member: Super.extendedAbstractMixedInConcreteSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractMixedInConcreteSetter(int i);

  /*member: Super.extendedConcreteMixedInAbstractSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedConcreteMixedInAbstractSetter(int i) {}

  /*member: Super.extendedAbstractMixedInAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  void set extendedAbstractMixedInAbstractSetter(int i);
}

/*class: Mixin:
 abstractMembers=[
  Mixin.extendedAbstractMixedInAbstractSetter=,
  Mixin.extendedConcreteMixedInAbstractSetter=,
  Mixin.mixedInAbstractSetter=],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin {
  /*member: Mixin.mixedInConcreteSetter=#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set mixedInConcreteSetter(int i) {}

  /*member: Mixin.mixedInAbstractSetter=#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set mixedInAbstractSetter(int i);

  /*member: Mixin.extendedConcreteMixedInConcreteSetter=#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set extendedConcreteMixedInConcreteSetter(int i) {}

  /*member: Mixin.extendedAbstractMixedInConcreteSetter=#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set extendedAbstractMixedInConcreteSetter(int i) {}

  /*member: Mixin.extendedConcreteMixedInAbstractSetter=#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set extendedConcreteMixedInAbstractSetter(int i);

  /*member: Mixin.extendedAbstractMixedInAbstractSetter=#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  void set extendedAbstractMixedInAbstractSetter(int i);
}

/*class: _ClassMixin&Super&Mixin:
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: _ClassMixin&Super&Mixin.mixedInConcreteSetter=#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteSetter=
*/
/*member: _ClassMixin&Super&Mixin.mixedInConcreteSetter=#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteSetter=
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteSetter=#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteSetter=
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteSetter=#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteSetter=,
  Super.extendedConcreteMixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteSetter=
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteSetter=#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteSetter=
*/
/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteSetter=#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteSetter=,
  Super.extendedAbstractMixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteSetter=
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractSetter=#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractSetter=
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractSetter=,
  Super.extendedConcreteMixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractSetter=,
  Super.extendedConcreteMixedInAbstractSetter=]
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteSetter=#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: _ClassMixin&Super&Mixin.mixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[Mixin.mixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractSetter=]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractSetter=,
  Super.extendedAbstractMixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractSetter=,
  Super.extendedAbstractMixedInAbstractSetter=]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractSetter=#int:
 classBuilder=Super,
 isSourceDeclaration
*/

/*class: ClassMixin:
 abstractMembers=[
  Super.extendedAbstractSetter=,
  _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractSetter=,
  _ClassMixin&Super&Mixin.mixedInAbstractSetter=],
 interfaces=[Mixin],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Super,
  _ClassMixin&Super&Mixin]
*/
class ClassMixin extends Super with Mixin {
  /*member: ClassMixin.mixedInConcreteSetter=#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.mixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteSetter=
  */
  /*member: ClassMixin.mixedInConcreteSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteSetter=
  */

  /*member: ClassMixin.extendedConcreteMixedInConcreteSetter=#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteSetter=
  */
  /*member: ClassMixin.extendedConcreteMixedInConcreteSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInConcreteSetter=,
    Super.extendedConcreteMixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteSetter=
  */

  /*member: ClassMixin.extendedAbstractMixedInConcreteSetter=#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteSetter=
  */
  /*member: ClassMixin.extendedAbstractMixedInConcreteSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInConcreteSetter=,
    Super.extendedAbstractMixedInConcreteSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteSetter=
  */

  /*member: ClassMixin.extendedConcreteMixedInAbstractSetter=#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractSetter=],
   isSynthesized,
   member=Super.extendedConcreteMixedInAbstractSetter=
  */
  /*member: ClassMixin.extendedConcreteMixedInAbstractSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInAbstractSetter=,
    Super.extendedConcreteMixedInAbstractSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractSetter=
  */

  /*member: ClassMixin.extendedConcreteSetter=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ClassMixin.mixedInAbstractSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInAbstractSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInAbstractSetter=
  */

  /*member: ClassMixin.extendedAbstractMixedInAbstractSetter=#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInAbstractSetter=,
    Super.extendedAbstractMixedInAbstractSetter=],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractSetter=
  */

  /*member: ClassMixin.extendedAbstractSetter=#int:
   classBuilder=Super,
   isSourceDeclaration
  */
}

/*class: NamedMixin:
 abstractMembers=[
  NamedMixin.extendedAbstractMixedInAbstractSetter=,
  NamedMixin.mixedInAbstractSetter=,
  Super.extendedAbstractSetter=],
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: NamedMixin.mixedInConcreteSetter=#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.mixedInConcreteSetter=],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInConcreteSetter=],
 stubTarget=Mixin.mixedInConcreteSetter=
*/
/*member: NamedMixin.mixedInConcreteSetter=#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteSetter=
*/

/*member: NamedMixin.extendedConcreteMixedInConcreteSetter=#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedConcreteMixedInConcreteSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInConcreteSetter=,
  Super.extendedConcreteMixedInConcreteSetter=],
 stubTarget=Mixin.extendedConcreteMixedInConcreteSetter=
*/
/*member: NamedMixin.extendedConcreteMixedInConcreteSetter=#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteSetter=,
  Super.extendedConcreteMixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteSetter=
*/

/*member: NamedMixin.extendedAbstractMixedInConcreteSetter=#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedAbstractMixedInConcreteSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInConcreteSetter=,
  Super.extendedAbstractMixedInConcreteSetter=],
 stubTarget=Mixin.extendedAbstractMixedInConcreteSetter=
*/
/*member: NamedMixin.extendedAbstractMixedInConcreteSetter=#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteSetter=,
  Super.extendedAbstractMixedInConcreteSetter=],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteSetter=
*/

/*member: NamedMixin.extendedConcreteMixedInAbstractSetter=#cls:
 classBuilder=NamedMixin,
 inherited-implements=[NamedMixin.extendedConcreteMixedInAbstractSetter=],
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractSetter=
*/
/*member: NamedMixin.extendedConcreteMixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractSetter=,
  Super.extendedConcreteMixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractSetter=,
  Super.extendedConcreteMixedInAbstractSetter=]
*/

/*member: NamedMixin.extendedConcreteSetter=#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: NamedMixin.mixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[Mixin.mixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractSetter=]
*/

/*member: NamedMixin.extendedAbstractMixedInAbstractSetter=#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractSetter=,
  Super.extendedAbstractMixedInAbstractSetter=],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractSetter=,
  Super.extendedAbstractMixedInAbstractSetter=]
*/

/*member: NamedMixin.extendedAbstractSetter=#int:
 classBuilder=Super,
 isSourceDeclaration
*/
class NamedMixin = Super with Mixin;

main() {}
