// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:static=[explicitAs(1),implicitAs(1),promoted(1)],type=[inst:JSNull]*/
main() {
  explicitAs(null);
  implicitAs(null);
  promoted(null);
}

/*member: explicitAs:
 dynamic=[String.length],
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
  param:String*]
*/
explicitAs(String i) {
  i.length;
  // ignore: unnecessary_cast
  return i as String;
}

/*member: implicitAs:
 dynamic=[String.length],
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
  param:String*]
*/
String implicitAs(String i) {
  dynamic j = i;
  i.length;
  j.length;
  return j;
}

/*member: promoted:
 dynamic=[String.length],
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
  is:String*]
*/
String promoted(dynamic i) {
  if (i is! String) return null;
  i.length;
  return i;
}
