// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: AbstractSuper:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class AbstractSuper {
  /*member: AbstractSuper.extendedConcreteMethod#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void extendedConcreteMethod() {}

  /*member: AbstractSuper.extendedAbstractMethod#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void extendedAbstractMethod();

  /*member: AbstractSuper.declaredConcreteExtendsConcreteMethod#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void declaredConcreteExtendsConcreteMethod() {}

  /*member: AbstractSuper.declaredAbstractExtendsConcreteMethod#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void declaredAbstractExtendsConcreteMethod() {}

  /*member: AbstractSuper.declaredConcreteExtendsAbstractMethod#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void declaredConcreteExtendsAbstractMethod();

  /*member: AbstractSuper.declaredAbstractExtendsAbstractMethod#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void declaredAbstractExtendsAbstractMethod();
}

/*class: AbstractClass:
 maxInheritancePath=2,
 superclasses=[
  AbstractSuper,
  Object]
*/
/*member: AbstractClass.declaredAbstractExtendsConcreteMethod#cls:
 classBuilder=AbstractClass,
 isSynthesized,
 member=AbstractSuper.declaredAbstractExtendsConcreteMethod
*/
abstract class AbstractClass extends AbstractSuper {
  /*member: AbstractClass.extendedConcreteMethod#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractMethod#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteMethod#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void declaredConcreteMethod() {}

  /*member: AbstractClass.declaredAbstractMethod#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void declaredAbstractMethod();

  /*member: AbstractClass.declaredConcreteExtendsConcreteMethod#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsConcreteMethod],
   isSourceDeclaration
  */
  void declaredConcreteExtendsConcreteMethod() {}

  /*member: AbstractClass.declaredAbstractExtendsConcreteMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsConcreteMethod,
    AbstractSuper.declaredAbstractExtendsConcreteMethod],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsConcreteMethod],
   isSynthesized
  */
  void declaredAbstractExtendsConcreteMethod();

  /*member: AbstractClass.declaredConcreteExtendsAbstractMethod#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsAbstractMethod],
   isSourceDeclaration
  */
  void declaredConcreteExtendsAbstractMethod() {}

  /*member: AbstractClass.declaredAbstractExtendsAbstractMethod#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsAbstractMethod,
    AbstractSuper.declaredAbstractExtendsAbstractMethod],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsAbstractMethod],
   isSynthesized
  */
  void declaredAbstractExtendsAbstractMethod();
}
