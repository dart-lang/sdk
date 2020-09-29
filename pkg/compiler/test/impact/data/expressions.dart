// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:static=[
  testAs(1),
  testAsGeneric(1),
  testAsGenericDynamic(1),
  testAsGenericRaw(1),
  testConditional(0),
  testIfNotNull(1),
  testIfNotNullSet(1),
  testIfNull(1),
  testIs(0),
  testIsGeneric(0),
  testIsGenericDynamic(0),
  testIsGenericRaw(0),
  testIsNot(0),
  testIsNotGeneric(0),
  testIsNotGenericDynamic(0),
  testIsNotGenericRaw(0),
  testIsTypedef(0),
  testIsTypedefDeep(0),
  testIsTypedefGeneric(0),
  testIsTypedefGenericDynamic(0),
  testIsTypedefGenericRaw(0),
  testNot(0),
  testPostDec(1),
  testPostInc(1),
  testPreDec(1),
  testPreInc(1),
  testSetIfNull(1),
  testThrow(0),
  testTypedIfNotNull(1),
  testUnaryMinus(0)
],type=[inst:JSNull]
 */
main() {
  testNot();
  testUnaryMinus();
  testConditional();
  testPostInc(null);
  testPostDec(null);
  testPreInc(null);
  testPreDec(null);
  testIs();
  testIsGeneric();
  testIsGenericRaw();
  testIsGenericDynamic();
  testIsNot();
  testIsNotGeneric();
  testIsNotGenericRaw();
  testIsNotGenericDynamic();
  testIsTypedef();
  testIsTypedefGeneric();
  testIsTypedefGenericRaw();
  testIsTypedefGenericDynamic();
  testIsTypedefDeep();
  testAs(null);
  testAsGeneric(null);
  testAsGenericRaw(null);
  testAsGenericDynamic(null);
  testThrow();
  testIfNotNull(null);
  testTypedIfNotNull(null);
  testIfNotNullSet(null);
  testIfNull(null);
  testSetIfNull(null);
}

/*member: testNot:type=[inst:JSBool]*/
testNot() => !false;

/*member: testUnaryMinus:type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]*/
testUnaryMinus() => -1;

/*member: testConditional:type=[inst:JSNull]*/
// ignore: DEAD_CODE
testConditional() => true ? null : '';

/*member: testPostInc:
 dynamic=[+],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPostInc(o) => o++;

/*member: testPostDec:
 dynamic=[-],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPostDec(o) => o--;

/*member: testPreInc:
 dynamic=[+],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPreInc(o) => ++o;

/*member: testPreDec:
 dynamic=[-],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPreDec(o) => --o;

/*member: testIs:type=[inst:JSBool]*/
testIs() => null is Class;

/*member: testIsGeneric:type=[inst:JSBool]*/
testIsGeneric() => null is GenericClass<int, String>;

/*member: testIsGenericRaw:type=[inst:JSBool]*/
testIsGenericRaw() => null is GenericClass;

/*member: testIsGenericDynamic:type=[inst:JSBool]*/
testIsGenericDynamic() => null is GenericClass<dynamic, dynamic>;

/*member: testIsNot:type=[inst:JSBool]*/
testIsNot() => null is! Class;

/*member: testIsNotGeneric:type=[inst:JSBool]*/
testIsNotGeneric() => null is! GenericClass<int, String>;

/*member: testIsNotGenericRaw:type=[inst:JSBool]*/
testIsNotGenericRaw() => null is! GenericClass;

/*member: testIsNotGenericDynamic:type=[inst:JSBool]*/
testIsNotGenericDynamic() => null is! GenericClass<dynamic, dynamic>;

/*member: testIsTypedef:type=[inst:JSBool]*/
testIsTypedef() => null is Typedef;

/*member: testIsTypedefGeneric:type=[inst:JSBool]*/
testIsTypedefGeneric() => null is GenericTypedef<int, String>;

/*member: testIsTypedefGenericRaw:type=[inst:JSBool]*/
testIsTypedefGenericRaw() => null is GenericTypedef;

/*member: testIsTypedefGenericDynamic:type=[inst:JSBool]*/
testIsTypedefGenericDynamic() => null is GenericTypedef<dynamic, dynamic>;

/*member: testIsTypedefDeep:type=[inst:JSBool]*/
testIsTypedefDeep() => null is List<GenericTypedef<int, GenericTypedef>>;

/*member: testAs:
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
  as:Class*,
  inst:Closure,
  inst:JSBool]
*/
// ignore: UNNECESSARY_CAST
testAs(dynamic o) => o as Class;

/*member: testAsGeneric:
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
  instanceType(1),
  setRuntimeTypeInfo(2)],
 type=[
  as:GenericClass<int*,String*>*,
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
// ignore: UNNECESSARY_CAST
testAsGeneric(dynamic o) => o as GenericClass<int, String>;

/*member: testAsGenericRaw:
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
  as:GenericClass<dynamic,dynamic>*,
  inst:Closure,
  inst:JSBool]
*/
// ignore: UNNECESSARY_CAST
testAsGenericRaw(dynamic o) => o as GenericClass;

/*member: testAsGenericDynamic:
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
  as:GenericClass<dynamic,dynamic>*,
  inst:Closure,
  inst:JSBool]
*/
// ignore: UNNECESSARY_CAST
testAsGenericDynamic(dynamic o) => o as GenericClass<dynamic, dynamic>;

/*member: testThrow:
 static=[throwExpression(1),wrapException(1)],
 type=[inst:JSString]*/
testThrow() => throw '';

/*member: testIfNotNull:dynamic=[Object.==,foo],type=[inst:JSNull]*/
testIfNotNull(o) => o?.foo;

/*member: testTypedIfNotNull:
 dynamic=[
  Class.==,
  Class.field],
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
  param:Class*]
*/
testTypedIfNotNull(Class o) => o?.field;

/*member: testIfNotNullSet:dynamic=[Object.==,foo=],type=[inst:JSBool,inst:JSNull]*/
testIfNotNullSet(o) => o?.foo = true;

/*member: testIfNull:dynamic=[Object.==],type=[inst:JSBool,inst:JSNull]*/
testIfNull(o) => o ?? true;

/*member: testSetIfNull:dynamic=[Object.==],type=[inst:JSBool,inst:JSNull]*/
testSetIfNull(o) => o ??= true;

class Class {
  var field;
}

class GenericClass<X, Y> {}

typedef Typedef();

typedef X GenericTypedef<X, Y>(Y y);
