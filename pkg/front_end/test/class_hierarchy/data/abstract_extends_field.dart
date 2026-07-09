// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: AbstractSuper:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class AbstractSuper {
  /*member: AbstractSuper.extendedConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.extendedConcreteField=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int extendedConcreteField = 0;

  /*member: AbstractSuper.extendedAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.extendedAbstractField=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract int extendedAbstractField;

  /*member: AbstractSuper.declaredConcreteExtendsConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.declaredConcreteExtendsConcreteField=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int declaredConcreteExtendsConcreteField = 0;

  /*member: AbstractSuper.declaredAbstractExtendsConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.declaredAbstractExtendsConcreteField=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int declaredAbstractExtendsConcreteField = 0;

  /*member: AbstractSuper.declaredConcreteExtendsAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.declaredConcreteExtendsAbstractField=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract int declaredConcreteExtendsAbstractField;

  /*member: AbstractSuper.declaredAbstractExtendsAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractSuper.declaredAbstractExtendsAbstractField=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract int declaredAbstractExtendsAbstractField;
}

/*class: AbstractClass:
 maxInheritancePath=2,
 superclasses=[
  AbstractSuper,
  Object]
*/
abstract class AbstractClass extends AbstractSuper {
  /*member: AbstractClass.extendedConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractClass.extendedConcreteField=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  /*member: AbstractClass.extendedAbstractField=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteField#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteField=#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int declaredConcreteField = 0;

  /*member: AbstractClass.declaredAbstractField#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredAbstractField=#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  abstract int declaredAbstractField;

  /*member: AbstractClass.declaredConcreteExtendsConcreteField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredConcreteExtendsConcreteField,
    AbstractSuper.declaredConcreteExtendsConcreteField=],
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteExtendsConcreteField=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredConcreteExtendsConcreteField,
    AbstractSuper.declaredConcreteExtendsConcreteField=],
   isSourceDeclaration
  */
  int declaredConcreteExtendsConcreteField = 0;

  /*member: AbstractClass.declaredAbstractExtendsConcreteField#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=AbstractSuper.declaredAbstractExtendsConcreteField
  */
  /*member: AbstractClass.declaredAbstractExtendsConcreteField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsConcreteField,
    AbstractSuper.declaredAbstractExtendsConcreteField],
   declared-overrides=[
    AbstractSuper.declaredAbstractExtendsConcreteField,
    AbstractSuper.declaredAbstractExtendsConcreteField=],
   isSynthesized
  */
  /*member: AbstractClass.declaredAbstractExtendsConcreteField=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=AbstractSuper.declaredAbstractExtendsConcreteField
  */
  /*member: AbstractClass.declaredAbstractExtendsConcreteField=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsConcreteField=,
    AbstractSuper.declaredAbstractExtendsConcreteField=],
   declared-overrides=[
    AbstractSuper.declaredAbstractExtendsConcreteField,
    AbstractSuper.declaredAbstractExtendsConcreteField=],
   isSynthesized
  */
  abstract int declaredAbstractExtendsConcreteField;

  /*member: AbstractClass.declaredConcreteExtendsAbstractField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredConcreteExtendsAbstractField,
    AbstractSuper.declaredConcreteExtendsAbstractField=],
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredConcreteExtendsAbstractField=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredConcreteExtendsAbstractField,
    AbstractSuper.declaredConcreteExtendsAbstractField=],
   isSourceDeclaration
  */
  int declaredConcreteExtendsAbstractField = 0;

  /*member: AbstractClass.declaredAbstractExtendsAbstractField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredAbstractExtendsAbstractField,
    AbstractSuper.declaredAbstractExtendsAbstractField=],
   isSourceDeclaration
  */
  /*member: AbstractClass.declaredAbstractExtendsAbstractField=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[
    AbstractSuper.declaredAbstractExtendsAbstractField,
    AbstractSuper.declaredAbstractExtendsAbstractField=],
   isSourceDeclaration
  */
  int declaredAbstractExtendsAbstractField = 0;
}

main() {}
