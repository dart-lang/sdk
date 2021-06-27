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
  final int extendedConcreteField = 0;

  /*member: AbstractSuper.extendedAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract final int extendedAbstractField;

  /*member: AbstractSuper.declaredConcreteExtendsConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  final int declaredConcreteExtendsConcreteField = 0;

  /*member: AbstractSuper.declaredAbstractExtendsConcreteField#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  final int declaredAbstractExtendsConcreteField = 0;

  /*member: AbstractSuper.declaredConcreteExtendsAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract final int declaredConcreteExtendsAbstractField;

  /*member: AbstractSuper.declaredAbstractExtendsAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  abstract final int declaredAbstractExtendsAbstractField;
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

  /*member: AbstractClass.extendedAbstractField#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteField#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  final int declaredConcreteField = 0;

  /*member: AbstractClass.declaredAbstractField#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  abstract final int declaredAbstractField;

  /*member: AbstractClass.declaredConcreteExtendsConcreteField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsConcreteField],
   isSourceDeclaration
  */
  final int declaredConcreteExtendsConcreteField = 0;

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
   declared-overrides=[AbstractSuper.declaredAbstractExtendsConcreteField],
   isSynthesized
  */
  abstract final int declaredAbstractExtendsConcreteField;

  /*member: AbstractClass.declaredConcreteExtendsAbstractField#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsAbstractField],
   isSourceDeclaration
  */
  final int declaredConcreteExtendsAbstractField = 0;

  /*member: AbstractClass.declaredAbstractExtendsAbstractField#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsAbstractField,
    AbstractSuper.declaredAbstractExtendsAbstractField],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsAbstractField],
   isSynthesized
  */
  abstract final int declaredAbstractExtendsAbstractField;
}

main() {}
