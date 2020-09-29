// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:
 static=[
  testClosure(0),
  testClosureInvoke(0),
  testDynamicGet(1),
  testDynamicInvoke(1),
  testDynamicPrivateMethodInvoke(0),
  testDynamicSet(1),
  testInvokeIndex(1),
  testInvokeIndexSet(1),
  testLocalFunction(0),
  testLocalFunctionGet(0),
  testLocalFunctionInvoke(0),
  testLocalFunctionTyped(0),
  testLocalWithInitializer(0),
  testLocalWithInitializerTyped(0),
  testLocalWithoutInitializer(0),
  testStaticFunctionGet(0),
  testTopLevelField(0),
  testTopLevelFieldConst(0),
  testTopLevelFieldFinal(0),
  testTopLevelFieldGeneric1(0),
  testTopLevelFieldGeneric2(0),
  testTopLevelFieldGeneric3(0),
  testTopLevelFieldLazy(0),
  testTopLevelFieldTyped(0),
  testTopLevelFieldWrite(0),
  testTopLevelFunctionGet(0),
  testTopLevelFunctionTyped(0),
  testTopLevelGetterGet(0),
  testTopLevelGetterGetTyped(0),
  testTopLevelInvoke(0),
  testTopLevelInvokeTyped(0),
  testTopLevelSetterSet(0),
  testTopLevelSetterSetTyped(0)],
 type=[inst:JSNull]
*/
main() {
  testTopLevelInvoke();
  testTopLevelInvokeTyped();
  testTopLevelFunctionTyped();
  testTopLevelFunctionGet();
  testTopLevelGetterGet();
  testTopLevelGetterGetTyped();
  testTopLevelSetterSet();
  testTopLevelSetterSetTyped();
  testTopLevelField();
  testTopLevelFieldLazy();
  testTopLevelFieldConst();
  testTopLevelFieldFinal();
  testTopLevelFieldTyped();
  testTopLevelFieldGeneric1();
  testTopLevelFieldGeneric2();
  testTopLevelFieldGeneric3();
  testTopLevelFieldWrite();
  testStaticFunctionGet();
  testDynamicInvoke(null);
  testDynamicGet(null);
  testDynamicSet(null);
  testLocalWithoutInitializer();
  testLocalWithInitializer();
  testLocalWithInitializerTyped();
  testLocalFunction();
  testLocalFunctionTyped();
  testLocalFunctionInvoke();
  testLocalFunctionGet();
  testClosure();
  testClosureInvoke();
  testInvokeIndex(null);
  testInvokeIndexSet(null);
  testDynamicPrivateMethodInvoke();
}

/*member: topLevelFunction1:*/
topLevelFunction1(a) {}

/*member: topLevelFunction2:type=[inst:JSNull]*/
topLevelFunction2(a, [b, c]) {}

/*member: topLevelFunction3:type=[inst:JSNull]*/
topLevelFunction3(a, {b, c}) {}

/*member: testTopLevelInvoke:
 static=[
  topLevelFunction1(1),
  topLevelFunction2(1),
  topLevelFunction2(2),
  topLevelFunction2(3),
  topLevelFunction3(1),
  topLevelFunction3(1,b),
  topLevelFunction3(1,b,c),
  topLevelFunction3(1,b,c),
  topLevelFunction3(1,c)],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testTopLevelInvoke() {
  topLevelFunction1(0);
  topLevelFunction2(1);
  topLevelFunction2(2, 3);
  topLevelFunction2(4, 5, 6);
  topLevelFunction3(7);
  topLevelFunction3(8, b: 9);
  topLevelFunction3(10, c: 11);
  topLevelFunction3(12, b: 13, c: 14);
  topLevelFunction3(15, c: 16, b: 17);
}

/*member: topLevelFunction1Typed:
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
  param:int*]
*/
void topLevelFunction1Typed(int a) {}

/*member: topLevelFunction2Typed:
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
  param:String*,
  param:double*,
  param:num*]
*/
int topLevelFunction2Typed(String a, [num b, double c]) => null;

/*member: topLevelFunction3Typed:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:List<int*>*,
  param:Map<String*,bool*>*,
  param:bool*]
*/
double topLevelFunction3Typed(bool a, {List<int> b, Map<String, bool> c}) {
  return null;
}

/*member: testTopLevelInvokeTyped:
 static=[
  topLevelFunction1Typed(1),
  topLevelFunction2Typed(1),
  topLevelFunction2Typed(2),
  topLevelFunction2Typed(3),
  topLevelFunction3Typed(1),
  topLevelFunction3Typed(1,b),
  topLevelFunction3Typed(1,b,c),
  topLevelFunction3Typed(1,b,c),
  topLevelFunction3Typed(1,c)],
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<int*>,
  inst:Map<String*,bool*>]
*/
testTopLevelInvokeTyped() {
  topLevelFunction1Typed(0);
  topLevelFunction2Typed('1');
  topLevelFunction2Typed('2', 3);
  topLevelFunction2Typed('3', 5, 6.0);
  topLevelFunction3Typed(true);
  topLevelFunction3Typed(false, b: []);
  topLevelFunction3Typed(null, c: {});
  topLevelFunction3Typed(true, b: [13], c: {'14': true});
  topLevelFunction3Typed(false, c: {'16': false}, b: [17]);
}

/*member: topLevelFunctionTyped1:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num*)*]
*/
topLevelFunctionTyped1(void a(num b)) {}

/*member: topLevelFunctionTyped2:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num*,[String*])*]
*/
topLevelFunctionTyped2(void a(num b, [String c])) {}

/*member: topLevelFunctionTyped3:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num*,{String* c,int* d})*]
*/
topLevelFunctionTyped3(void a(num b, {String c, int d})) {}

/*member: topLevelFunctionTyped4:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num*,{int* c,String* d})*]
*/
topLevelFunctionTyped4(void a(num b, {String d, int c})) {}

/*member: testTopLevelFunctionTyped:
 static=[
  topLevelFunctionTyped1(1),
  topLevelFunctionTyped2(1),
  topLevelFunctionTyped3(1),
  topLevelFunctionTyped4(1)],
 type=[inst:JSNull]
*/
testTopLevelFunctionTyped() {
  topLevelFunctionTyped1(null);
  topLevelFunctionTyped2(null);
  topLevelFunctionTyped3(null);
  topLevelFunctionTyped4(null);
}

/*member: testTopLevelFunctionGet:static=[topLevelFunction1]*/
testTopLevelFunctionGet() => topLevelFunction1;

/*member: topLevelGetter:type=[inst:JSNull]*/
get topLevelGetter => null;

/*member: testTopLevelGetterGet:static=[topLevelGetter]*/
testTopLevelGetterGet() => topLevelGetter;

/*member: topLevelGetterTyped:type=[inst:JSNull]*/
int get topLevelGetterTyped => null;

/*member: testTopLevelGetterGetTyped:static=[topLevelGetterTyped]*/
testTopLevelGetterGetTyped() => topLevelGetterTyped;

/*member: topLevelSetter=:*/
set topLevelSetter(_) {}

/*member: testTopLevelSetterSet:static=[set:topLevelSetter],type=[inst:JSNull]*/
testTopLevelSetterSet() => topLevelSetter = null;

/*member: topLevelSetterTyped=:
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
  param:int*]
*/
void set topLevelSetterTyped(int value) {}

/*member: testTopLevelSetterSetTyped:static=[set:topLevelSetterTyped],type=[inst:JSNull]*/
testTopLevelSetterSetTyped() => topLevelSetterTyped = null;

/*member: topLevelField:type=[inst:JSNull]*/
var topLevelField;

/*member: testTopLevelField:static=[topLevelField]*/
testTopLevelField() => topLevelField;

/*member: topLevelFieldLazy:
 static=[
  throwCyclicInit(1),
  throwLateInitializationError(1),
  topLevelFunction1(1)],
 type=[inst:JSNull]
*/
var topLevelFieldLazy = topLevelFunction1(null);

/*member: testTopLevelFieldLazy:static=[topLevelFieldLazy]*/
testTopLevelFieldLazy() => topLevelFieldLazy;

const topLevelFieldConst = null;

/*member: testTopLevelFieldConst:type=[inst:JSNull]*/
testTopLevelFieldConst() => topLevelFieldConst;

/*member: topLevelFieldFinal:
 static=[
  throwCyclicInit(1),
  throwLateInitializationError(1),
  topLevelFunction1(1)],
 type=[inst:JSNull]
*/
final topLevelFieldFinal = topLevelFunction1(null);

/*member: testTopLevelFieldFinal:static=[topLevelFieldFinal]*/
testTopLevelFieldFinal() => topLevelFieldFinal;

/*member: topLevelFieldTyped:
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
  param:int*]
*/
int topLevelFieldTyped;

/*member: testTopLevelFieldTyped:static=[topLevelFieldTyped]*/
testTopLevelFieldTyped() => topLevelFieldTyped;

/*member: topLevelFieldGeneric1:
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
  param:GenericClass<dynamic,dynamic>*]
*/
GenericClass topLevelFieldGeneric1;

/*member: testTopLevelFieldGeneric1:static=[topLevelFieldGeneric1]*/
testTopLevelFieldGeneric1() => topLevelFieldGeneric1;

/*member: topLevelFieldGeneric2:
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
  param:GenericClass<dynamic,dynamic>*]
*/
GenericClass<dynamic, dynamic> topLevelFieldGeneric2;

/*member: testTopLevelFieldGeneric2:static=[topLevelFieldGeneric2]*/
testTopLevelFieldGeneric2() => topLevelFieldGeneric2;

/*member: topLevelFieldGeneric3:
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
  inst:Closure,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:GenericClass<int*,String*>*]
*/
GenericClass<int, String> topLevelFieldGeneric3;

/*member: testTopLevelFieldGeneric3:static=[topLevelFieldGeneric3]*/
testTopLevelFieldGeneric3() => topLevelFieldGeneric3;

/*member: testTopLevelFieldWrite:static=[set:topLevelField],type=[inst:JSNull]*/
testTopLevelFieldWrite() => topLevelField = null;

class StaticFunctionGetClass {
  /*member: StaticFunctionGetClass.foo:*/
  static foo() {}
}

/*member: testStaticFunctionGet:static=[StaticFunctionGetClass.foo]*/
testStaticFunctionGet() => StaticFunctionGetClass.foo;

/*member: testDynamicInvoke:
 dynamic=[
  call(1),
  call(1,b),
  call(1,b,c),
  call(1,b,c),
  call(1,c),
  call(2),
  call(3),
  f1(1),
  f2(1),
  f3(2),
  f4(3),
  f5(1),
  f6(1,b),
  f7(1,c),
  f8(1,b,c),
  f9(1,b,c)],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testDynamicInvoke(o) {
  o.f1(0);
  o.f2(1);
  o.f3(2, 3);
  o.f4(4, 5, 6);
  o.f5(7);
  o.f6(8, b: 9);
  o.f7(10, c: 11);
  o.f8(12, b: 13, c: 14);
  o.f9(15, c: 16, b: 17);
}

/*member: testDynamicGet:dynamic=[foo]*/
testDynamicGet(o) => o.foo;

/*member: testDynamicSet:
 dynamic=[foo=],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testDynamicSet(o) => o.foo = 42;

// TODO(johnniwinther): Remove 'inst:Null'.
/*member: testLocalWithoutInitializer:type=[inst:JSNull,inst:Null]*/
testLocalWithoutInitializer() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var l;
}

/*member: testLocalWithInitializer:
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testLocalWithInitializer() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var l = 42;
}

/*member: testLocalWithInitializerTyped:
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testLocalWithInitializerTyped() {
  // ignore: UNUSED_LOCAL_VARIABLE
  int l = 42;
}

/*member: testLocalFunction:
 static=[
  def:localFunction,
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalFunction() {
  // ignore: UNUSED_ELEMENT
  localFunction() {}
}

/*member: testLocalFunctionTyped:
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
  def:localFunction,
  findType(1),
  instanceType(1),
  setRuntimeTypeInfo(2)],
 type=[
  inst:Closure,
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:String*]
*/
testLocalFunctionTyped() {
  // ignore: UNUSED_ELEMENT
  int localFunction(String a) => null;
}

/*member: testLocalFunctionInvoke:
 dynamic=[call(0)],
 static=[
  def:localFunction,
  localFunction(0),
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalFunctionInvoke() {
  localFunction() {}
  localFunction();
}

/*member: testLocalFunctionGet:
 static=[
  def:localFunction,
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalFunctionGet() {
  localFunction() {}
  localFunction;
}

/*member: testClosure:
 static=[
  def:<anonymous>,
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testClosure() {
  () {};
}

/*member: testClosureInvoke:
 dynamic=[call(0)],
 static=[
  def:<anonymous>,
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testClosureInvoke() {
  () {}();
}

/*member: testInvokeIndex:
 dynamic=[[]],
 type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testInvokeIndex(o) => o[42];

/*member: testInvokeIndexSet:
 dynamic=[[]=],
 type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testInvokeIndexSet(o) => o[42] = null;

/*member: testDynamicPrivateMethodInvoke:
 dynamic=[_privateMethod(0),call(0)],
 type=[inst:JSNull]
*/
testDynamicPrivateMethodInvoke([o]) => o._privateMethod();

class GenericClass<X, Y> {}
