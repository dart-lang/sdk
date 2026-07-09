// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: ConcreteSuper:
 abstractMembers=[
  ConcreteSuper.declaredAbstractExtendsAbstractGetter,
  ConcreteSuper.declaredConcreteExtendsAbstractGetter,
  ConcreteSuper.extendedAbstractGetter],
 maxInheritancePath=1,
 superclasses=[Object]
*/
class ConcreteSuper {
  /*member: ConcreteSuper.extendedConcreteGetter#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get extendedConcreteGetter => 0;

  /*member: ConcreteSuper.extendedAbstractGetter#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get extendedAbstractGetter;

  /*member: ConcreteSuper.declaredConcreteExtendsConcreteGetter#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get declaredConcreteExtendsConcreteGetter => 0;

  /*member: ConcreteSuper.declaredAbstractExtendsConcreteGetter#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get declaredAbstractExtendsConcreteGetter => 0;

  /*member: ConcreteSuper.declaredConcreteExtendsAbstractGetter#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get declaredConcreteExtendsAbstractGetter;

  /*member: ConcreteSuper.declaredAbstractExtendsAbstractGetter#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */
  int get declaredAbstractExtendsAbstractGetter;
}

/*class: ConcreteClass:
 abstractMembers=[
  ConcreteClass.declaredAbstractExtendsAbstractGetter,
  ConcreteClass.declaredAbstractGetter,
  ConcreteSuper.extendedAbstractGetter],
 maxInheritancePath=2,
 superclasses=[
  ConcreteSuper,
  Object]
*/
class ConcreteClass extends ConcreteSuper {
  /*member: ConcreteClass.extendedConcreteGetter#cls:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.extendedAbstractGetter#int:
   classBuilder=ConcreteSuper,
   isSourceDeclaration
  */

  /*member: ConcreteClass.declaredConcreteGetter#cls:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  int get declaredConcreteGetter => 0;

  /*member: ConcreteClass.declaredAbstractGetter#int:
   classBuilder=ConcreteClass,
   isSourceDeclaration
  */
  int get declaredAbstractGetter;

  /*member: ConcreteClass.declaredConcreteExtendsConcreteGetter#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsConcreteGetter],
   isSourceDeclaration
  */
  int get declaredConcreteExtendsConcreteGetter => 0;

  /*member: ConcreteClass.declaredAbstractExtendsConcreteGetter#cls:
   classBuilder=ConcreteClass,
   inherited-implements=[ConcreteClass.declaredAbstractExtendsConcreteGetter],
   isSynthesized,
   member=ConcreteSuper.declaredAbstractExtendsConcreteGetter
  */
  /*member: ConcreteClass.declaredAbstractExtendsConcreteGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsConcreteGetter,
    ConcreteSuper.declaredAbstractExtendsConcreteGetter],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsConcreteGetter],
   isSynthesized
  */
  int get declaredAbstractExtendsConcreteGetter;

  /*member: ConcreteClass.declaredConcreteExtendsAbstractGetter#cls:
   classBuilder=ConcreteClass,
   declared-overrides=[ConcreteSuper.declaredConcreteExtendsAbstractGetter],
   isSourceDeclaration
  */
  int get declaredConcreteExtendsAbstractGetter => 0;

  /*member: ConcreteClass.declaredAbstractExtendsAbstractGetter#int:
   classBuilder=ConcreteClass,
   declarations=[
    ConcreteClass.declaredAbstractExtendsAbstractGetter,
    ConcreteSuper.declaredAbstractExtendsAbstractGetter],
   declared-overrides=[ConcreteSuper.declaredAbstractExtendsAbstractGetter],
   isSynthesized
  */
  int get declaredAbstractExtendsAbstractGetter;
}

main() {}
