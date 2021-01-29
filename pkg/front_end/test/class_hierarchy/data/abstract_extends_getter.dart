// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: AbstractSuper:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class AbstractSuper {
  /*member: AbstractSuper.extendedConcreteGetter#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get extendedConcreteGetter => 0;

  /*member: AbstractSuper.extendedAbstractGetter#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get extendedAbstractGetter;

  /*member: AbstractSuper.declaredConcreteExtendsConcreteGetter#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get declaredConcreteExtendsConcreteGetter => 0;

  /*member: AbstractSuper.declaredAbstractExtendsConcreteGetter#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get declaredAbstractExtendsConcreteGetter => 0;

  /*member: AbstractSuper.declaredConcreteExtendsAbstractGetter#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get declaredConcreteExtendsAbstractGetter;

  /*member: AbstractSuper.declaredAbstractExtendsAbstractGetter#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  int get declaredAbstractExtendsAbstractGetter;
}

/*class: AbstractClass:
 maxInheritancePath=2,
 superclasses=[
  AbstractSuper,
  Object]
*/
abstract class AbstractClass extends AbstractSuper {
  /*member: AbstractClass.extendedConcreteGetter#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractGetter#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteGetter#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int get declaredConcreteGetter => 0;

  /*member: AbstractClass.declaredAbstractGetter#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  int get declaredAbstractGetter;

  /*member: AbstractClass.declaredConcreteExtendsConcreteGetter#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsConcreteGetter],
   isSourceDeclaration
  */
  int get declaredConcreteExtendsConcreteGetter => 0;

  /*member: AbstractClass.declaredAbstractExtendsConcreteGetter#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=AbstractSuper.declaredAbstractExtendsConcreteGetter
  */
  /*member: AbstractClass.declaredAbstractExtendsConcreteGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsConcreteGetter,
    AbstractSuper.declaredAbstractExtendsConcreteGetter],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsConcreteGetter],
   isSynthesized
  */
  int get declaredAbstractExtendsConcreteGetter;

  /*member: AbstractClass.declaredConcreteExtendsAbstractGetter#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsAbstractGetter],
   isSourceDeclaration
  */
  int get declaredConcreteExtendsAbstractGetter => 0;

  /*member: AbstractClass.declaredAbstractExtendsAbstractGetter#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsAbstractGetter,
    AbstractSuper.declaredAbstractExtendsAbstractGetter],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsAbstractGetter],
   isSynthesized
  */
  int get declaredAbstractExtendsAbstractGetter;
}

main() {}
