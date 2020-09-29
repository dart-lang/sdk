// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library main;

import 'dart:html' show File;

import 'package:js/js.dart';

/*member: foo=:
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
  native:ApplicationCacheErrorEvent,
  native:DomError,
  native:DomException,
  native:ErrorEvent,
  native:File,
  native:MediaError,
  native:NavigatorUserMediaError,
  native:OverconstrainedError,
  native:PositionError,
  native:SensorErrorEvent,
  native:SpeechRecognitionError,
  native:SqlError,
  param:void Function(String*,File*)*]
*/
@JS()
external set foo(void Function(String, File) f);

/*member: _doStuff:
 dynamic=[
  File.==,
  File.name],
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
  defineProperty(3),
  findType(1),
  instanceType(1),
  print(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  inst:JSNull,
  inst:JSString,
  param:File*,
  param:String*]
*/
void _doStuff(String name, File file) {
  if (file == null) {
    print('OK');
  }
  print(file.name);
}

/*member: main:static=[
  _doStuff,
  allowInterop<void Function(String*,File*)*>(1),
  set:foo]*/
void main() {
  foo = allowInterop(_doStuff);
}
