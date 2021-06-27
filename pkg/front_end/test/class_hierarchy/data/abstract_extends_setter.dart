// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: AbstractSuper:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class AbstractSuper {
  /*member: AbstractSuper.extendedConcreteSetter=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set extendedConcreteSetter(int value) {}

  /*member: AbstractSuper.extendedAbstractSetter=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set extendedAbstractSetter(int value);

  /*member: AbstractSuper.declaredConcreteExtendsConcreteSetter=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set declaredConcreteExtendsConcreteSetter(int value) {}

  /*member: AbstractSuper.declaredAbstractExtendsConcreteSetter=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set declaredAbstractExtendsConcreteSetter(int value) {}

  /*member: AbstractSuper.declaredConcreteExtendsAbstractSetter=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set declaredConcreteExtendsAbstractSetter(int value);

  /*member: AbstractSuper.declaredAbstractExtendsAbstractSetter=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */
  void set declaredAbstractExtendsAbstractSetter(int value);
}

/*class: AbstractClass:
 maxInheritancePath=2,
 superclasses=[
  AbstractSuper,
  Object]
*/
abstract class AbstractClass extends AbstractSuper {
  /*member: AbstractClass.extendedConcreteSetter=#cls:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.extendedAbstractSetter=#int:
   classBuilder=AbstractSuper,
   isSourceDeclaration
  */

  /*member: AbstractClass.declaredConcreteSetter=#cls:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void set declaredConcreteSetter(int value) {}

  /*member: AbstractClass.declaredAbstractSetter=#int:
   classBuilder=AbstractClass,
   isSourceDeclaration
  */
  void set declaredAbstractSetter(int value);

  /*member: AbstractClass.declaredConcreteExtendsConcreteSetter=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsConcreteSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteExtendsConcreteSetter(int value) {}

  /*member: AbstractClass.declaredAbstractExtendsConcreteSetter=#cls:
   classBuilder=AbstractClass,
   isSynthesized,
   member=AbstractSuper.declaredAbstractExtendsConcreteSetter=
  */
  /*member: AbstractClass.declaredAbstractExtendsConcreteSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsConcreteSetter=,
    AbstractSuper.declaredAbstractExtendsConcreteSetter=],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsConcreteSetter=],
   isSynthesized
  */
  void set declaredAbstractExtendsConcreteSetter(int value);

  /*member: AbstractClass.declaredConcreteExtendsAbstractSetter=#cls:
   classBuilder=AbstractClass,
   declared-overrides=[AbstractSuper.declaredConcreteExtendsAbstractSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteExtendsAbstractSetter(int value) {}

  /*member: AbstractClass.declaredAbstractExtendsAbstractSetter=#int:
   classBuilder=AbstractClass,
   declarations=[
    AbstractClass.declaredAbstractExtendsAbstractSetter=,
    AbstractSuper.declaredAbstractExtendsAbstractSetter=],
   declared-overrides=[AbstractSuper.declaredAbstractExtendsAbstractSetter=],
   isSynthesized
  */
  void set declaredAbstractExtendsAbstractSetter(int value);
}

main() {}
