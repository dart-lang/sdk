// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 abstractMembers=[
  Super.extendedAbstractField,
  Super.extendedAbstractMixedInAbstractField,
  Super.extendedAbstractMixedInConcreteField],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
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

  /*member: Super.extendedConcreteMixedInConcreteField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  final int extendedConcreteMixedInConcreteField = 0;

  /*member: Super.extendedAbstractMixedInConcreteField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract final int extendedAbstractMixedInConcreteField;

  /*member: Super.extendedConcreteMixedInAbstractField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  final int extendedConcreteMixedInAbstractField = 0;

  /*member: Super.extendedAbstractMixedInAbstractField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
  abstract final int extendedAbstractMixedInAbstractField;
}

/*class: Mixin:
 abstractMembers=[
  Mixin.extendedAbstractMixedInAbstractField,
  Mixin.extendedConcreteMixedInAbstractField,
  Mixin.mixedInAbstractField],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin {
  /*member: Mixin.mixedInConcreteField#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  final int mixedInConcreteField = 0;

  /*member: Mixin.mixedInAbstractField#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  abstract final int mixedInAbstractField;

  /*member: Mixin.extendedConcreteMixedInConcreteField#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  final int extendedConcreteMixedInConcreteField = 0;

  /*member: Mixin.extendedAbstractMixedInConcreteField#cls:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  final int extendedAbstractMixedInConcreteField = 0;

  /*member: Mixin.extendedConcreteMixedInAbstractField#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  abstract final int extendedConcreteMixedInAbstractField;

  /*member: Mixin.extendedAbstractMixedInAbstractField#int:
   classBuilder=Mixin,
   isSourceDeclaration
  */
  abstract final int extendedAbstractMixedInAbstractField;
}

/*class: _ClassMixin&Super&Mixin:
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: _ClassMixin&Super&Mixin.mixedInConcreteField#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteField
*/
/*member: _ClassMixin&Super&Mixin.mixedInConcreteField#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteField
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteField#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteField
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteField#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteField,
  Super.extendedConcreteMixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteField
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteField#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteField
*/
/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteField#int:
 classBuilder=_ClassMixin&Super&Mixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteField,
  Super.extendedAbstractMixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteField
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractField#cls:
 classBuilder=_ClassMixin&Super&Mixin,
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractField
*/
/*member: _ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractField,
  Super.extendedConcreteMixedInAbstractField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractField,
  Super.extendedConcreteMixedInAbstractField]
*/

/*member: _ClassMixin&Super&Mixin.extendedConcreteField#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: _ClassMixin&Super&Mixin.mixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[Mixin.mixedInAbstractField],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractField]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=_ClassMixin&Super&Mixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractField,
  Super.extendedAbstractMixedInAbstractField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractField,
  Super.extendedAbstractMixedInAbstractField]
*/

/*member: _ClassMixin&Super&Mixin.extendedAbstractField#int:
 classBuilder=Super,
 isSourceDeclaration
*/

/*class: ClassMixin:
 abstractMembers=[
  Super.extendedAbstractField,
  _ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractField,
  _ClassMixin&Super&Mixin.mixedInAbstractField],
 interfaces=[Mixin],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Super,
  _ClassMixin&Super&Mixin]
*/
class ClassMixin extends Super with Mixin {
  /*member: ClassMixin.mixedInConcreteField#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.mixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteField
  */
  /*member: ClassMixin.mixedInConcreteField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInConcreteField
  */

  /*member: ClassMixin.extendedConcreteMixedInConcreteField#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteField
  */
  /*member: ClassMixin.extendedConcreteMixedInConcreteField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInConcreteField,
    Super.extendedConcreteMixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInConcreteField
  */

  /*member: ClassMixin.extendedAbstractMixedInConcreteField#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteField
  */
  /*member: ClassMixin.extendedAbstractMixedInConcreteField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInConcreteField,
    Super.extendedAbstractMixedInConcreteField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInConcreteField
  */

  /*member: ClassMixin.extendedConcreteMixedInAbstractField#cls:
   classBuilder=ClassMixin,
   inherited-implements=[_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractField],
   isSynthesized,
   member=Super.extendedConcreteMixedInAbstractField
  */
  /*member: ClassMixin.extendedConcreteMixedInAbstractField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedConcreteMixedInAbstractField,
    Super.extendedConcreteMixedInAbstractField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedConcreteMixedInAbstractField
  */

  /*member: ClassMixin.extendedConcreteField#cls:
   classBuilder=Super,
   isSourceDeclaration
  */

  /*member: ClassMixin.mixedInAbstractField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[Mixin.mixedInAbstractField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.mixedInAbstractField
  */

  /*member: ClassMixin.extendedAbstractMixedInAbstractField#int:
   classBuilder=_ClassMixin&Super&Mixin,
   declarations=[
    Mixin.extendedAbstractMixedInAbstractField,
    Super.extendedAbstractMixedInAbstractField],
   isSynthesized,
   member=_ClassMixin&Super&Mixin.extendedAbstractMixedInAbstractField
  */

  /*member: ClassMixin.extendedAbstractField#int:
   classBuilder=Super,
   isSourceDeclaration
  */
}

/*class: NamedMixin:
 abstractMembers=[
  NamedMixin.extendedAbstractMixedInAbstractField,
  NamedMixin.mixedInAbstractField,
  Super.extendedAbstractField],
 interfaces=[Mixin],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/

/*member: NamedMixin.mixedInConcreteField#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.mixedInConcreteField],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInConcreteField],
 stubTarget=Mixin.mixedInConcreteField
*/
/*member: NamedMixin.mixedInConcreteField#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[Mixin.mixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.mixedInConcreteField
*/

/*member: NamedMixin.extendedConcreteMixedInConcreteField#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedConcreteMixedInConcreteField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInConcreteField,
  Super.extendedConcreteMixedInConcreteField],
 stubTarget=Mixin.extendedConcreteMixedInConcreteField
*/
/*member: NamedMixin.extendedConcreteMixedInConcreteField#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedConcreteMixedInConcreteField,
  Super.extendedConcreteMixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.extendedConcreteMixedInConcreteField
*/

/*member: NamedMixin.extendedAbstractMixedInConcreteField#cls:
 classBuilder=NamedMixin,
 concreteMixinStub,
 inherited-implements=[NamedMixin.extendedAbstractMixedInConcreteField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInConcreteField,
  Super.extendedAbstractMixedInConcreteField],
 stubTarget=Mixin.extendedAbstractMixedInConcreteField
*/
/*member: NamedMixin.extendedAbstractMixedInConcreteField#int:
 classBuilder=NamedMixin,
 concreteMixinStub,
 declarations=[
  Mixin.extendedAbstractMixedInConcreteField,
  Super.extendedAbstractMixedInConcreteField],
 isSynthesized,
 stubTarget=Mixin.extendedAbstractMixedInConcreteField
*/

/*member: NamedMixin.extendedConcreteMixedInAbstractField#cls:
 classBuilder=NamedMixin,
 inherited-implements=[NamedMixin.extendedConcreteMixedInAbstractField],
 isSynthesized,
 member=Super.extendedConcreteMixedInAbstractField
*/
/*member: NamedMixin.extendedConcreteMixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedConcreteMixedInAbstractField,
  Super.extendedConcreteMixedInAbstractField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedConcreteMixedInAbstractField,
  Super.extendedConcreteMixedInAbstractField]
*/

/*member: NamedMixin.extendedConcreteField#cls:
 classBuilder=Super,
 isSourceDeclaration
*/

/*member: NamedMixin.mixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[Mixin.mixedInAbstractField],
 isSynthesized,
 mixin-overrides=[Mixin.mixedInAbstractField]
*/

/*member: NamedMixin.extendedAbstractMixedInAbstractField#int:
 abstractMixinStub,
 classBuilder=NamedMixin,
 declarations=[
  Mixin.extendedAbstractMixedInAbstractField,
  Super.extendedAbstractMixedInAbstractField],
 isSynthesized,
 mixin-overrides=[
  Mixin.extendedAbstractMixedInAbstractField,
  Super.extendedAbstractMixedInAbstractField]
*/

/*member: NamedMixin.extendedAbstractField#int:
 classBuilder=Super,
 isSourceDeclaration
*/
class NamedMixin = Super with Mixin;

main() {}
