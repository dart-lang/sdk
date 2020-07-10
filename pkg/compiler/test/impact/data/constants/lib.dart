// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

const dynamic nullLiteralField = null;

const dynamic boolLiteralField = true;

const dynamic intLiteralField = 42;

const dynamic doubleLiteralField = 0.5;

const dynamic stringLiteralField = "foo";

const dynamic symbolLiteralField = #foo;

const dynamic listLiteralField = [true, false];

const dynamic mapLiteralField = {true: false};

const dynamic stringMapLiteralField = {'foo': false};

const dynamic setLiteralField = {true, false};

class SuperClass {
  /*member: SuperClass.field1:type=[inst:JSNull]*/
  final field1;

  const SuperClass(this.field1);
}

class Class extends SuperClass {
  /*member: Class.field2:type=[inst:JSNull]*/
  final field2;

  const Class(field1, this.field2) : super(field1);

  static staticMethodField() {}
}

const instanceConstantField = const Class(true, false);

const typeLiteralField = String;

/*member: id:
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
  param:Object*,
  param:id.T*]
*/
T id<T>(T t) => t;

const int Function(int) _instantiation = id;

const dynamic instantiationField = _instantiation;

topLevelMethod() {}

const dynamic topLevelTearOffField = topLevelMethod;

const dynamic staticTearOffField = Class.staticMethodField;
