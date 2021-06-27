// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: ConcreteSuper:
 abstractMembers=[
  ConcreteSuper.declaredAbstractExtendsAbstractMethod,
  ConcreteSuper.declaredConcreteExtendsAbstractMethod,
  ConcreteSuper.extendedAbstractMethod],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class ConcreteSuper {
  /*member: ConcreteSuper.extendedConcreteMethod#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void extendedConcreteMethod() {}

  /*member: ConcreteSuper.extendedAbstractMethod#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void extendedAbstractMethod();

  /*member: ConcreteSuper.declaredConcreteExtendsConcreteMethod#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void declaredConcreteExtendsConcreteMethod() {}

  /*member: ConcreteSuper.declaredAbstractExtendsConcreteMethod#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void declaredAbstractExtendsConcreteMethod() {}

  /*member: ConcreteSuper.declaredConcreteExtendsAbstractMethod#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void declaredConcreteExtendsAbstractMethod();

  /*member: ConcreteSuper.declaredAbstractExtendsAbstractMethod#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  void declaredAbstractExtendsAbstractMethod();
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractExtendsAbstractMethod,
  ConcreteClass.declaredAbstractMethod,
  ConcreteSuper.extendedAbstractMethod],
 maxInheritancePath=2,
 superclasses=[
  ConcreteSuper,
  Object]
*/
class ConcreteClass extends ConcreteSuper {
  /*member: ConcreteClass.extendedConcreteMethod#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractMethod#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteMethod#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void declaredConcreteMethod() {}

  /*member: ConcreteClass.declaredAbstractMethod#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  void declaredAbstractMethod();

  /*member: ConcreteClass.declaredConcreteExtendsConcreteMethod#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsConcreteMethod],
   isSourceDeclaration
  */
  void declaredConcreteExtendsConcreteMethod() {}

  /*member: ConcreteClass.declaredAbstractExtendsConcreteMethod#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.declaredAbstractExtendsConcreteMethod],
   isSynthesized,
   member=ConcreteSuper.declaredAbstractExtendsConcreteMethod
  */
  /*member: ConcreteClass.declaredAbstractExtendsConcreteMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsConcreteMethod,
    ConcreteSuper.declaredAbstractExtendsConcreteMethod],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsConcreteMethod],
   isSynthesized
  */
  void declaredAbstractExtendsConcreteMethod();

  /*member: ConcreteClass.declaredConcreteExtendsAbstractMethod#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsAbstractMethod],
   isSourceDeclaration
  */
  void declaredConcreteExtendsAbstractMethod() {}

  /*member: ConcreteClass.declaredAbstractExtendsAbstractMethod#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsAbstractMethod,
    ConcreteSuper.declaredAbstractExtendsAbstractMethod],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsAbstractMethod],
   isSynthesized
  */
  void declaredAbstractExtendsAbstractMethod();
}
