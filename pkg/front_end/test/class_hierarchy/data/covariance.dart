// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From language/covariant_override/tear_off_type_test

// If a parameter is directly or indirectly a covariant override, its type in
// the method tear-off should become Object?.

/*class: M1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class M1 {
  /*member: M1.method#cls:
   classBuilder=M1,
   isSourceDeclaration
  */
  method(covariant int a, int b) {}
}

/*class: M2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class M2 {
  /*member: M2.method#cls:
   classBuilder=M2,
   isSourceDeclaration
  */
  method(int a, covariant int b) {}
}

/*class: _C&Object&M1:
 interfaces=[M1],
 maxInheritancePath=2,
 superclasses=[Object]
*/

/*member: _C&Object&M1.method#cls:
 classBuilder=_C&Object&M1,
 concreteMixinStub,
 isSynthesized,
 stubTarget=M1.method
*/
/*member: _C&Object&M1.method#int:
 classBuilder=_C&Object&M1,
 concreteMixinStub,
 declarations=[M1.method],
 isSynthesized,
 stubTarget=M1.method
*/

/*class: _C&Object&M1&M2:
 interfaces=[
  M1,
  M2],
 maxInheritancePath=3,
 superclasses=[
  Object,
  _C&Object&M1]
*/

/*member: _C&Object&M1&M2.method#cls:
 classBuilder=_C&Object&M1&M2,
 concreteForwardingStub,
 covariance=Covariance(0:Covariant,1:Covariant),
 isSynthesized,
 stubTarget=M2.method,
 type=dynamic Function(int, int)
*/
/*member: _C&Object&M1&M2.method#int:
 classBuilder=_C&Object&M1&M2,
 concreteForwardingStub,
 covariance=Covariance(0:Covariant,1:Covariant),
 declarations=[
  M2.method,
  _C&Object&M1.method],
 isSynthesized,
 stubTarget=M2.method,
 type=dynamic Function(int, int)
*/

/*class: C:
 interfaces=[
  M1,
  M2],
 maxInheritancePath=4,
 superclasses=[
  Object,
  _C&Object&M1,
  _C&Object&M1&M2]
*/
class C extends Object with M1, M2 {
  /*member: C.method#cls:
   classBuilder=C,
   inherited-implements=[_C&Object&M1&M2.method],
   isSynthesized,
   member=_C&Object&M1&M2.method
  */
  /*member: C.method#int:
   classBuilder=_C&Object&M1&M2,
   declarations=[
    M2.method,
    _C&Object&M1.method],
   isSynthesized,
   member=_C&Object&M1&M2.method
  */
}

/*class: Direct:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Direct {
  /*member: Direct.positional#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */
  void positional(covariant int a, int b, covariant int c, int d, int e) {}

  /*member: Direct.optional#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */
  void optional(
      [covariant int a = 0, int b = 0, covariant int c = 0, int d = 0]) {}

  /*member: Direct.named#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */
  void named(
      {covariant int a = 0, int b = 0, covariant int c = 0, int d = 0}) {}
}

/*class: Inherited:
 maxInheritancePath=2,
 superclasses=[
  Direct,
  Object]
*/
class Inherited extends Direct {
  /*member: Inherited.positional#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */

  /*member: Inherited.optional#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */

  /*member: Inherited.named#cls:
   classBuilder=Direct,
   isSourceDeclaration
  */
}

// ---

/*class: Override1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Override1 {
  /*member: Override1.method#cls:
   classBuilder=Override1,
   isSourceDeclaration
  */
  void method(covariant int a, int b, int c, int d, int e) {}
}

/*class: Override2:
 maxInheritancePath=2,
 superclasses=[
  Object,
  Override1]
*/
class Override2 extends Override1 {
  /*member: Override2.method#cls:
   classBuilder=Override2,
   declared-overrides=[Override1.method],
   isSourceDeclaration
  */
  void method(int a, int b, covariant int c, int d, int e) {}
}

/*class: Override3:
 maxInheritancePath=3,
 superclasses=[
  Object,
  Override1,
  Override2]
*/
class Override3 extends Override2 {
  /*member: Override3.method#cls:
   classBuilder=Override3,
   declared-overrides=[Override2.method],
   isSourceDeclaration
  */
  void method(int a, int b, int c, int d, int e) {}
}

// ---

/*class: Implement1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class Implement1 {
  /*member: Implement1.method#cls:
   classBuilder=Implement1,
   isSourceDeclaration
  */
  void method(covariant int a, int b, int c, int d, int e) {}
}

/*class: Implement2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Implement2 {
  /*member: Implement2.method#cls:
   classBuilder=Implement2,
   isSourceDeclaration
  */
  void method(int a, covariant int b, int c, int d, int e) {}
}

/*class: Implement3:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Implement3 {
  /*member: Implement3.method#cls:
   classBuilder=Implement3,
   isSourceDeclaration
  */
  void method(int a, int b, covariant int c, int d, int e) {}
}

/*class: Implement4:
 interfaces=[Implement3],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class Implement4 implements Implement3 {
  /*member: Implement4.method#cls:
   classBuilder=Implement4,
   declared-overrides=[Implement3.method],
   isSourceDeclaration
  */
  void method(int a, int b, int c, covariant int d, int e) {}
}

/*class: Implement5:
 interfaces=[
  Implement1,
  Implement2,
  Implement3,
  Implement4],
 maxInheritancePath=3,
 superclasses=[Object]
*/
class Implement5 implements Implement1, Implement2, Implement4 {
  /*member: Implement5.method#cls:
   classBuilder=Implement5,
   declared-overrides=[
    Implement1.method,
    Implement2.method,
    Implement4.method],
   isSourceDeclaration
  */
  void method(int a, int b, int c, int d, covariant int e) {}
}

// ---

/*class: Interface1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface1 {
  /*member: Interface1.method#cls:
   classBuilder=Interface1,
   isSourceDeclaration
  */
  void method(covariant int a, int b, int c, int d, int e) {}
}

/*class: Interface2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface2 {
  /*member: Interface2.method#cls:
   classBuilder=Interface2,
   isSourceDeclaration
  */
  void method(int a, covariant int b, int c, int d, int e) {}
}

/*class: Mixin1:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin1 {
  /*member: Mixin1.method#cls:
   classBuilder=Mixin1,
   isSourceDeclaration
  */
  void method(int a, int b, covariant int c, int d, int e) {}
}

/*class: Mixin2:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Mixin2 {
  /*member: Mixin2.method#cls:
   classBuilder=Mixin2,
   isSourceDeclaration
  */
  void method(int a, int b, int c, covariant int d, int e) {}
}

/*class: Superclass:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Superclass {
  /*member: Superclass.method#cls:
   classBuilder=Superclass,
   isSourceDeclaration
  */
  void method(int a, int b, int c, int d, covariant int e) {}
}

/*class: _Mixed&Superclass&Mixin1:
 interfaces=[Mixin1],
 maxInheritancePath=2,
 superclasses=[
  Object,
  Superclass]
*/

/*member: _Mixed&Superclass&Mixin1.method#cls:
 classBuilder=_Mixed&Superclass&Mixin1,
 concreteForwardingStub,
 covariance=Covariance(2:Covariant,4:Covariant),
 isSynthesized,
 stubTarget=Mixin1.method,
 type=void Function(int, int, int, int, int)
*/
/*member: _Mixed&Superclass&Mixin1.method#int:
 classBuilder=_Mixed&Superclass&Mixin1,
 concreteForwardingStub,
 covariance=Covariance(2:Covariant,4:Covariant),
 declarations=[
  Mixin1.method,
  Superclass.method],
 isSynthesized,
 stubTarget=Mixin1.method,
 type=void Function(int, int, int, int, int)
*/

/*class: _Mixed&Superclass&Mixin1&Mixin2:
 interfaces=[
  Mixin1,
  Mixin2],
 maxInheritancePath=3,
 superclasses=[
  Object,
  Superclass,
  _Mixed&Superclass&Mixin1]
*/

/*member: _Mixed&Superclass&Mixin1&Mixin2.method#cls:
 classBuilder=_Mixed&Superclass&Mixin1&Mixin2,
 concreteForwardingStub,
 covariance=Covariance(2:Covariant,3:Covariant,4:Covariant),
 isSynthesized,
 stubTarget=Mixin2.method,
 type=void Function(int, int, int, int, int)
*/
/*member: _Mixed&Superclass&Mixin1&Mixin2.method#int:
 classBuilder=_Mixed&Superclass&Mixin1&Mixin2,
 concreteForwardingStub,
 covariance=Covariance(2:Covariant,3:Covariant,4:Covariant),
 declarations=[
  Mixin2.method,
  _Mixed&Superclass&Mixin1.method],
 isSynthesized,
 stubTarget=Mixin2.method,
 type=void Function(int, int, int, int, int)
*/

/*class: Mixed:
 interfaces=[
  Interface1,
  Interface2,
  Mixin1,
  Mixin2],
 maxInheritancePath=4,
 superclasses=[
  Object,
  Superclass,
  _Mixed&Superclass&Mixin1,
  _Mixed&Superclass&Mixin1&Mixin2]
*/
class Mixed extends Superclass
    with Mixin1, Mixin2
    implements Interface1, Interface2 {
  /*member: Mixed.method#cls:
   classBuilder=Mixed,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant,1:Covariant,2:Covariant,3:Covariant,4:Covariant),
   inherited-implements=[Mixed.method],
   isSynthesized,
   stubTarget=Mixin2.method,
   type=void Function(int, int, int, int, int)
  */
  /*member: Mixed.method#int:
   classBuilder=Mixed,
   concreteForwardingStub,
   covariance=Covariance(0:Covariant,1:Covariant,2:Covariant,3:Covariant,4:Covariant),
   declarations=[
    Interface1.method,
    Interface2.method,
    _Mixed&Superclass&Mixin1&Mixin2.method],
   isSynthesized,
   stubTarget=Mixin2.method,
   type=void Function(int, int, int, int, int)
  */
}

void main() {}
