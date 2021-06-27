// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: ConcreteSuper:
 abstractMembers=[
  ConcreteSuper.declaredAbstractExtendsAbstractField,
  ConcreteSuper.declaredConcreteExtendsAbstractField,
  ConcreteSuper.extendedAbstractField],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class ConcreteSuper {
  /*member: ConcreteSuper.extendedConcreteField#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  final int extendedConcreteField = 0;

  /*member: ConcreteSuper.extendedAbstractField#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  abstract final int extendedAbstractField;

  /*member: ConcreteSuper.declaredConcreteExtendsConcreteField#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  final int declaredConcreteExtendsConcreteField = 0;

  /*member: ConcreteSuper.declaredAbstractExtendsConcreteField#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  final int declaredAbstractExtendsConcreteField = 0;

  /*member: ConcreteSuper.declaredConcreteExtendsAbstractField#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  abstract final int declaredConcreteExtendsAbstractField;

  /*member: ConcreteSuper.declaredAbstractExtendsAbstractField#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  abstract final int declaredAbstractExtendsAbstractField;
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractExtendsAbstractField,
  ConcreteClass.declaredAbstractField,
  ConcreteSuper.extendedAbstractField],
 maxInheritancePath=2,
 superclasses=[
  ConcreteSuper,
  Object]
*/
class ConcreteClass extends ConcreteSuper {
  /*member: ConcreteClass.extendedConcreteField#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractField#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteField#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  final int declaredConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractField#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  abstract final int declaredAbstractField;

  /*member: ConcreteClass.declaredConcreteExtendsConcreteField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsConcreteField],
   isSourceDeclaration
  */
  final int declaredConcreteExtendsConcreteField = 0;

  /*member: ConcreteClass.declaredAbstractExtendsConcreteField#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.declaredAbstractExtendsConcreteField],
   isSynthesized,
   member=ConcreteSuper.declaredAbstractExtendsConcreteField
  */
  /*member: ConcreteClass.declaredAbstractExtendsConcreteField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsConcreteField,
    ConcreteSuper.declaredAbstractExtendsConcreteField],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsConcreteField],
   isSynthesized
  */
  abstract final int declaredAbstractExtendsConcreteField;

  /*member: ConcreteClass.declaredConcreteExtendsAbstractField#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsAbstractField],
   isSourceDeclaration
  */
  final int declaredConcreteExtendsAbstractField = 0;

  /*member: ConcreteClass.declaredAbstractExtendsAbstractField#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsAbstractField,
    ConcreteSuper.declaredAbstractExtendsAbstractField],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsAbstractField],
   isSynthesized
  */
  abstract final int declaredAbstractExtendsAbstractField;
}

main() {}
