// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  testAbstractClassWithField(0),
  testEnum(0),
  testForwardingConstructor(0),
  testForwardingConstructorGeneric(0),
  testForwardingConstructorTyped(0),
  testGenericMixinInstantiation(0),
  testGenericNamedMixinInstantiation(0),
  testInstanceGenericMethod(0),
  testMixinInstantiation(0),
  testNamedMixinInstantiation(0),
  testStaticGenericMethod(0),
  testSuperCall(0),
  testSuperClosurization(0),
  testSuperFieldSet(0),
  testSuperGet(0),
  testSuperSetterSet(0)]
*/
main() {
  testSuperCall();
  testSuperGet();
  testSuperFieldSet();
  testSuperSetterSet();
  testSuperClosurization();
  testForwardingConstructor();
  testForwardingConstructorTyped();
  testForwardingConstructorGeneric();
  testEnum();
  testStaticGenericMethod();
  testInstanceGenericMethod();
  testAbstractClassWithField();
  testMixinInstantiation();
  testNamedMixinInstantiation();
  testGenericMixinInstantiation();
  testGenericNamedMixinInstantiation();
}

/*element: Super1.:static=[Object.(0)]*/
class Super1 {
  /*element: Super1.foo:*/
  foo() {}
}

class Sub1 extends Super1 {
  /*element: Sub1.:static=[Super1.(0),Super1.foo(0)]*/
  Sub1() {
    super.foo();
  }
}

/*element: testSuperCall:static=[Sub1.(0)]*/
testSuperCall() => new Sub1();

/*element: Super2.:static=[Object.(0)]*/
class Super2 {
  /*element: Super2.foo:type=[inst:JSNull]*/
  var foo;
}

class Sub2 extends Super2 {
  /*element: Sub2.:static=[Super2.(0),Super2.foo]*/
  Sub2() {
    super.foo;
  }
}

/*element: testSuperGet:static=[Sub2.(0)]*/
testSuperGet() => new Sub2();

/*element: Super3.:static=[Object.(0)]*/
class Super3 {
  /*element: Super3.foo:type=[inst:JSNull]*/
  var foo;
}

class Sub3 extends Super3 {
  /*element: Sub3.:static=[Super3.(0),set:Super3.foo],type=[inst:JSBool]*/
  Sub3() {
    super.foo = true;
  }
}

/*element: testSuperFieldSet:static=[Sub3.(0)]*/
testSuperFieldSet() => new Sub3();

/*element: Super4.:static=[Object.(0)]*/
class Super4 {
  /*element: Super4.foo=:*/
  set foo(_) {}
}

class Sub4 extends Super4 {
  /*element: Sub4.:static=[Super4.(0),set:Super4.foo],type=[inst:JSBool]*/
  Sub4() {
    super.foo = true;
  }
}

/*element: testSuperSetterSet:static=[Sub4.(0)]*/
testSuperSetterSet() => new Sub4();

/*element: Super5.:static=[Object.(0)]*/
class Super5 {
  /*element: Super5.foo:*/
  foo() {}
}

/*element: Sub5.:static=[Super5.(0),Super5.foo]*/
class Sub5 extends Super5 {
  Sub5() {
    super.foo;
  }
}

/*element: testSuperClosurization:static=[Sub5.(0)]*/
testSuperClosurization() => new Sub5();

class EmptyMixin {}

class ForwardingConstructorSuperClass {
  /*element: ForwardingConstructorSuperClass.:static=[Object.(0)]*/
  ForwardingConstructorSuperClass(arg);
}

class ForwardingConstructorClass = ForwardingConstructorSuperClass
    with EmptyMixin;

/*element: testForwardingConstructor:
 static=[ForwardingConstructorClass.(1)],
 type=[inst:JSNull]
*/
testForwardingConstructor() => new ForwardingConstructorClass(null);

class ForwardingConstructorTypedSuperClass {
  /*kernel.element: ForwardingConstructorTypedSuperClass.:
   static=[Object.(0)],
   type=[check:int]
  */
  /*strong.element: ForwardingConstructorTypedSuperClass.:
   static=[Object.(0)],
   type=[inst:JSBool,param:int]
  */
  ForwardingConstructorTypedSuperClass(int arg);
}

class ForwardingConstructorTypedClass = ForwardingConstructorTypedSuperClass
    with EmptyMixin;

/*element: testForwardingConstructorTyped:
 static=[ForwardingConstructorTypedClass.(1)],
 type=[inst:JSNull]
*/
testForwardingConstructorTyped() => new ForwardingConstructorTypedClass(null);

class ForwardingConstructorGenericSuperClass<T> {
  /*kernel.element: ForwardingConstructorGenericSuperClass.:
   static=[Object.(0)],
   type=[check:ForwardingConstructorGenericSuperClass.T]
  */
  /*strong.element: ForwardingConstructorGenericSuperClass.:
   static=[
    Object.(0),
    checkSubtype,
    checkSubtypeOfRuntimeType,
    getRuntimeTypeArgument,
    getRuntimeTypeArgumentIntercepted,
    getRuntimeTypeInfo,
    getTypeArgumentByIndex,
    setRuntimeTypeInfo],
   type=[
    inst:JSArray<dynamic>,
    inst:JSBool,
    inst:JSExtendableArray<dynamic>,
    inst:JSFixedArray<dynamic>,
    inst:JSMutableArray<dynamic>,
    inst:JSUnmodifiableArray<dynamic>,
    param:ForwardingConstructorGenericSuperClass.T]
  */
  ForwardingConstructorGenericSuperClass(T arg);
}

class ForwardingConstructorGenericClass<
    S> = ForwardingConstructorGenericSuperClass<S> with EmptyMixin;

/*element: testForwardingConstructorGeneric:
 static=[
  ForwardingConstructorGenericClass.(1),
  assertIsSubtype,
  throwTypeError],
 type=[inst:JSNull]
*/
testForwardingConstructorGeneric() {
  new ForwardingConstructorGenericClass<int>(null);
}

enum Enum {
  /*kernel.element: Enum.A:static=[Enum.(2)],
   type=[
    check:Enum,
    inst:JSDouble,
    inst:JSInt,
    inst:JSNumber,
    inst:JSPositiveInt,
    inst:JSString,
    inst:JSUInt31,
    inst:JSUInt32]
  */
  /*strong.element: Enum.A:static=[Enum.(2)],
   type=[
    inst:JSBool,
    inst:JSDouble,
    inst:JSInt,
    inst:JSNumber,
    inst:JSPositiveInt,
    inst:JSString,
    inst:JSUInt31,
    inst:JSUInt32,
    param:Enum]
  */
  A
}

/*element: testEnum:static=[Enum.A]*/
testEnum() => Enum.A;

/*kernel.element: staticGenericMethod:
 type=[
  check:List<staticGenericMethod.T>,
  check:staticGenericMethod.T,
  inst:List<dynamic>]
 */
/*strong.element: staticGenericMethod:
 static=[
  checkSubtype,
  checkSubtypeOfRuntimeType,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  inst:List<staticGenericMethod.T>,
  param:Object,
  param:staticGenericMethod.T]
*/
List<T> staticGenericMethod<T>(T arg) => [arg];

/*kernel.element: testStaticGenericMethod:
  static=[staticGenericMethod(1)],
  type=[inst:JSBool]
*/
/*strong.element: testStaticGenericMethod:
  static=[staticGenericMethod<bool>(1)],
  type=[inst:JSBool]
*/
testStaticGenericMethod() {
  staticGenericMethod<bool>(true);
}

/*kernel.element: testInstanceGenericMethod:
 dynamic=[genericMethod(1)],
 static=[
  GenericClass.generative(0),
  assertIsSubtype,
  throwTypeError],
 type=[inst:JSBool]
*/
/*strong.element: testInstanceGenericMethod:
 dynamic=[genericMethod<bool>(1)],
 static=[
  GenericClass.generative(0),
  assertIsSubtype,
  throwTypeError],
 type=[inst:JSBool]
*/
testInstanceGenericMethod() {
  new GenericClass<int, String>.generative().genericMethod<bool>(false);
}

abstract class AbstractClass {
  // ignore: UNUSED_FIELD
  final _field;

  /*kernel.element: AbstractClass.:type=[check:AbstractClass,inst:JSNull]*/
  /*strong.element: AbstractClass.:type=[inst:JSNull]*/
  factory AbstractClass() => null;
}

/*element: testAbstractClassWithField:static=[AbstractClass.(0)]*/
testAbstractClassWithField() => new AbstractClass();

/*element: testMixinInstantiation:static=[Sub.(0)]*/
testMixinInstantiation() => new Sub();

/*element: testNamedMixinInstantiation:static=[NamedMixin.(0)]*/
testNamedMixinInstantiation() => new NamedMixin();

/*element: testGenericMixinInstantiation:
 static=[
  GenericSub.(0),
  assertIsSubtype,
  throwTypeError]
*/
testGenericMixinInstantiation() => new GenericSub<int, String>();

/*element: testGenericNamedMixinInstantiation:
 static=[
  GenericNamedMixin.(0),
  assertIsSubtype,
  throwTypeError]
*/
testGenericNamedMixinInstantiation() => new GenericNamedMixin<int, String>();

class Class {
  /*element: GenericClass.generative:static=[Object.(0)]*/
  const Class.generative();
}

class GenericClass<X, Y> {
  const GenericClass.generative();

  /*kernel.element: GenericClass.genericMethod:
   type=[
    check:Map<GenericClass.X,genericMethod.T>,
    check:genericMethod.T,
    inst:JSNull,
    inst:Map<dynamic,dynamic>]
  */
  /*strong.element: GenericClass.genericMethod:
   static=[
    checkSubtype,
    checkSubtypeOfRuntimeType,
    getRuntimeTypeArgument,
    getRuntimeTypeArgumentIntercepted,
    getRuntimeTypeInfo,
    getTypeArgumentByIndex,
    setRuntimeTypeInfo],
   type=[
    inst:JSArray<dynamic>,
    inst:JSBool,
    inst:JSExtendableArray<dynamic>,
    inst:JSFixedArray<dynamic>,
    inst:JSMutableArray<dynamic>,
    inst:JSNull,
    inst:JSUnmodifiableArray<dynamic>,
    inst:Map<GenericClass.X,genericMethod.T>,
    param:Object,
    param:genericMethod.T]
   */
  Map<X, T> genericMethod<T>(T arg) => {null: arg};
}

/*element: Super.:static=[Object.(0)]*/
class Super {}

class Mixin1 {}

class Mixin2 {}

/*element: Sub.:static=[_Sub&Super&Mixin1&Mixin2.(0)]*/
class Sub extends Super with Mixin1, Mixin2 {}

class NamedMixin = Super with Mixin1, Mixin2;

/*element: GenericSuper.:static=[Object.(0)]*/
class GenericSuper<X1, Y1> {}

class GenericMixin1<X2, Y2> {}

class GenericMixin2<X3, Y3> {}

/*element: GenericSub.:
  static=[_GenericSub&GenericSuper&GenericMixin1&GenericMixin2.(0)]
*/
class GenericSub<X4, Y4> extends GenericSuper<X4, Y4>
    with GenericMixin1<X4, Y4>, GenericMixin2<X4, Y4> {}

class GenericNamedMixin<X5, Y5> = GenericSuper<X5, Y5>
    with GenericMixin1<X5, Y5>, GenericMixin2<X5, Y5>;
