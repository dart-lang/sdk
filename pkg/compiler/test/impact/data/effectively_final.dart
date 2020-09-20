// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:
 static=[
  effectivelyFinalList(0),
  effectivelyFinalPromoted(0),
  effectivelyFinalPromotedInvalid(0),
  notEffectivelyFinalList(0)]
*/
main() {
  effectivelyFinalList();
  notEffectivelyFinalList();
  effectivelyFinalPromoted();
  effectivelyFinalPromotedInvalid();
}

/*member: effectivelyFinalList:
 dynamic=[
  List.add(1),
  List.length,
  List.length=,
  int.+],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<dynamic>]
*/
effectivelyFinalList() {
  dynamic c = [];
  c.add(null);
  c.length + 1;
  c.length = 1;
}

/*member: notEffectivelyFinalList:
 dynamic=[
  +,
  add(1),
  call(1),
  length,
  length=],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<dynamic>]
*/
notEffectivelyFinalList() {
  dynamic c = [];
  c.add(null);
  c.length + 1;
  c.length = 1;
  c = null;
}

/*member: _method1:type=[inst:JSNull]*/
num _method1() => null;

/*member: effectivelyFinalPromoted:
 dynamic=[
  int.+,
  num.+],
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
  _method1(0),
  findType(1),
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  is:int*]
*/
effectivelyFinalPromoted() {
  dynamic c = _method1();
  c + 0;
  if (c is int) {
    c + 1;
  }
}

/*member: _method2:type=[inst:JSNull]*/
String _method2() => null;

/*member: effectivelyFinalPromotedInvalid:
 dynamic=[
  String.+,
  int.+],
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
  _method2(0),
  findType(1),
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32,
  is:int*]
*/
effectivelyFinalPromotedInvalid() {
  dynamic c = _method2();
  c + '';
  if (c is int) {
    c + 1;
  }
}
