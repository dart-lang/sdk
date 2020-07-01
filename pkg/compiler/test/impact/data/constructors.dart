// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:
 static=[
  testConstRedirectingFactoryInvoke(0),
  testConstRedirectingFactoryInvokeGeneric(0),
  testConstRedirectingFactoryInvokeGenericDynamic(0),
  testConstRedirectingFactoryInvokeGenericRaw(0),
  testConstructorInvoke(0),
  testConstructorInvokeGeneric(0),
  testConstructorInvokeGenericDynamic(0),
  testConstructorInvokeGenericRaw(0),
  testFactoryConstructor(0),
  testFactoryInvoke(0),
  testFactoryInvokeGeneric(0),
  testFactoryInvokeGenericDynamic(0),
  testFactoryInvokeGenericRaw(0),
  testImplicitConstructor(0),
  testRedirectingFactoryInvoke(0),
  testRedirectingFactoryInvokeGeneric(0),
  testRedirectingFactoryInvokeGenericDynamic(0),
  testRedirectingFactoryInvokeGenericRaw(0)]
*/
main() {
  testConstructorInvoke();
  testConstructorInvokeGeneric();
  testConstructorInvokeGenericRaw();
  testConstructorInvokeGenericDynamic();
  testFactoryInvoke();
  testFactoryInvokeGeneric();
  testFactoryInvokeGenericRaw();
  testFactoryInvokeGenericDynamic();
  testRedirectingFactoryInvoke();
  testRedirectingFactoryInvokeGeneric();
  testRedirectingFactoryInvokeGenericRaw();
  testRedirectingFactoryInvokeGenericDynamic();
  testConstRedirectingFactoryInvoke();
  testConstRedirectingFactoryInvokeGeneric();
  testConstRedirectingFactoryInvokeGenericRaw();
  testConstRedirectingFactoryInvokeGenericDynamic();
  testImplicitConstructor();
  testFactoryConstructor();
}

/*member: testConstructorInvoke:static=[Class.generative(0)]*/
testConstructorInvoke() {
  new Class.generative();
}

/*member: testConstructorInvokeGeneric:static=[
  GenericClass.generative(0),
  checkTypeBound(4)]*/
testConstructorInvokeGeneric() {
  new GenericClass<int, String>.generative();
}

/*member: testConstructorInvokeGenericRaw:static=[GenericClass.generative(0)]*/
testConstructorInvokeGenericRaw() {
  new GenericClass.generative();
}

/*member: testConstructorInvokeGenericDynamic:static=[GenericClass.generative(0)]*/
testConstructorInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.generative();
}

/*member: testFactoryInvoke:static=[Class.fact(0)]*/
testFactoryInvoke() {
  new Class.fact();
}

/*member: testFactoryInvokeGeneric:static=[
  GenericClass.fact(0),
  checkTypeBound(4)]*/
testFactoryInvokeGeneric() {
  new GenericClass<int, String>.fact();
}

/*member: testFactoryInvokeGenericRaw:static=[GenericClass.fact(0)]*/
testFactoryInvokeGenericRaw() {
  new GenericClass.fact();
}

/*member: testFactoryInvokeGenericDynamic:static=[GenericClass.fact(0)]*/
testFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.fact();
}

/*member: testRedirectingFactoryInvoke:static=[Class.generative(0)]*/
testRedirectingFactoryInvoke() {
  new Class.redirect();
}

/*member: testRedirectingFactoryInvokeGeneric:static=[
  GenericClass.generative(0),
  checkTypeBound(4)]*/
testRedirectingFactoryInvokeGeneric() {
  new GenericClass<int, String>.redirect();
}

/*member: testRedirectingFactoryInvokeGenericRaw:static=[GenericClass.generative(0)]*/
testRedirectingFactoryInvokeGenericRaw() {
  new GenericClass.redirect();
}

/*member: testRedirectingFactoryInvokeGenericDynamic:static=[GenericClass.generative(0)]*/
testRedirectingFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.redirect();
}

/*member: testConstRedirectingFactoryInvoke:type=[const:Class]*/
testConstRedirectingFactoryInvoke() {
  const Class.redirect();
}

/*member: testConstRedirectingFactoryInvokeGeneric:type=[const:GenericClass<int*,String*>]*/
testConstRedirectingFactoryInvokeGeneric() {
  const GenericClass<int, String>.redirect();
}

/*member: testConstRedirectingFactoryInvokeGenericRaw:type=[const:GenericClass<dynamic,dynamic>]*/
testConstRedirectingFactoryInvokeGenericRaw() {
  const GenericClass.redirect();
}

/*member: testConstRedirectingFactoryInvokeGenericDynamic:type=[const:GenericClass<dynamic,dynamic>]*/
testConstRedirectingFactoryInvokeGenericDynamic() {
  const GenericClass<dynamic, dynamic>.redirect();
}

/*member: ClassImplicitConstructor.:static=[Object.(0)]*/
class ClassImplicitConstructor {}

/*member: testImplicitConstructor:static=[ClassImplicitConstructor.(0)]*/
testImplicitConstructor() => new ClassImplicitConstructor();

class ClassFactoryConstructor {
  /*member: ClassFactoryConstructor.:type=[inst:JSNull]*/
  factory ClassFactoryConstructor() => null;
}

/*member: testFactoryConstructor:static=[ClassFactoryConstructor.(0)]*/
testFactoryConstructor() => new ClassFactoryConstructor();

class Class {
  /*member: Class.generative:static=[Object.(0)]*/
  const Class.generative();

  /*member: Class.fact:type=[inst:JSNull]*/
  factory Class.fact() => null;

  const factory Class.redirect() = Class.generative;
}

class GenericClass<X, Y> {
  /*member: GenericClass.generative:static=[Object.(0)]*/
  const GenericClass.generative();

  /*member: GenericClass.fact:
   static=[
    Rti._bind(1),
    Rti._eval(1),
    _arrayInstanceType(1),
    _asBool(1),
    _asBoolQ(1),
    _asBoolS(1),
    _asDouble(1),
    _asDoubleQ(1),
    _asDoubleS(1),
    _asInt(1),
    _asIntQ(1),
    _asIntS(1),
    _asNum(1),
    _asNumQ(1),
    _asNumS(1),
    _asObject(1),
    _asString(1),
    _asStringQ(1),
    _asStringS(1),
    _asTop(1),
    _generalAsCheckImplementation(1),
    _generalIsTestImplementation(1),
    _generalNullableAsCheckImplementation(1),
    _generalNullableIsTestImplementation(1),
    _installSpecializedAsCheck(1),
    _installSpecializedIsTest(1),
    _instanceType(1),
    _isBool(1),
    _isInt(1),
    _isNum(1),
    _isObject(1),
    _isString(1),
    _isTop(1),
    findType(1),
    instanceType(1)],
   type=[
    inst:Closure,
    inst:JSBool,
    inst:JSNull,
    param:Object*]
  */
  factory GenericClass.fact() => null;

  const factory GenericClass.redirect() = GenericClass<X, Y>.generative;
}
