// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: ConcreteSuper:
 abstractMembers=[
  ConcreteSuper.declaredAbstractExtendsAbstractSetter=,
  ConcreteSuper.declaredConcreteExtendsAbstractSetter=,
  ConcreteSuper.extendedAbstractSetter=],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class ConcreteSuper {
  /*member: ConcreteSuper.extendedConcreteSetter=#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set extendedConcreteSetter(int value) {}

  /*member: ConcreteSuper.extendedAbstractSetter=#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set extendedAbstractSetter(int value);

  /*member: ConcreteSuper.declaredConcreteExtendsConcreteSetter=#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set declaredConcreteExtendsConcreteSetter(int value) {}

  /*member: ConcreteSuper.declaredAbstractExtendsConcreteSetter=#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set declaredAbstractExtendsConcreteSetter(int value) {}

  /*member: ConcreteSuper.declaredConcreteExtendsAbstractSetter=#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set declaredConcreteExtendsAbstractSetter(int value);

  /*member: ConcreteSuper.declaredAbstractExtendsAbstractSetter=#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void set declaredAbstractExtendsAbstractSetter(int value);
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractExtendsAbstractSetter=,
  ConcreteClass.declaredAbstractSetter=,
  ConcreteSuper.extendedAbstractSetter=],
 maxInheritancePath=2,
 superclasses=[
  ConcreteSuper,
  Object]
*/
class ConcreteClass extends ConcreteSuper {
  /*member: ConcreteClass.extendedConcreteSetter=#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractSetter=#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteSetter=#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void set declaredConcreteSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractSetter=#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void set declaredAbstractSetter(int value);

  /*member: ConcreteClass.declaredConcreteExtendsConcreteSetter=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsConcreteSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteExtendsConcreteSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractExtendsConcreteSetter=#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.declaredAbstractExtendsConcreteSetter=],
   isSynthesized,
   member=ConcreteSuper.declaredAbstractExtendsConcreteSetter=
  */
  /*member: ConcreteClass.declaredAbstractExtendsConcreteSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsConcreteSetter=,
    ConcreteSuper.declaredAbstractExtendsConcreteSetter=],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsConcreteSetter=],
   isSynthesized
  */
  void set declaredAbstractExtendsConcreteSetter(int value);

  /*member: ConcreteClass.declaredConcreteExtendsAbstractSetter=#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsAbstractSetter=],
   isSourceDeclaration
  */
  void set declaredConcreteExtendsAbstractSetter(int value) {}

  /*member: ConcreteClass.declaredAbstractExtendsAbstractSetter=#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsAbstractSetter=,
    ConcreteSuper.declaredAbstractExtendsAbstractSetter=],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsAbstractSetter=],
   isSynthesized
  */
  void set declaredAbstractExtendsAbstractSetter(int value);
}

main() {}
