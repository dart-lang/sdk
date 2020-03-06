// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library main;

import 'dart:html' show File;

import 'package:js/js.dart';

/*member: foo=:static=[Rti._bind(1),Rti._eval(1),_arrayInstanceType(1),_asBoolNullable(1),_asDoubleNullable(1),_asIntNullable(1),_asNumNullable(1),_asObject(1),_asStringNullable(1),_asTop(1),_checkBoolNullable(1),_checkDoubleNullable(1),_checkIntNullable(1),_checkNumNullable(1),_checkObject(1),_checkStringNullable(1),_generalAsCheckImplementation(1),_generalIsTestImplementation(1),_generalTypeCheckImplementation(1),_instanceType(1),_isBool(1),_isInt(1),_isNum(1),_isObject(1),_isString(1),_isTop(1),findType(1),instanceType(1)],type=[inst:Closure,inst:JSBool,native:ApplicationCacheErrorEvent,native:DomError,native:DomException,native:ErrorEvent,native:MediaError,native:NavigatorUserMediaError,native:OverconstrainedError,native:PositionError,native:SensorErrorEvent,native:SpeechRecognitionError,native:SqlError,param:Function]*/
@JS()
external set foo(Function f);

/*member: _doStuff:dynamic=[File.==,File.name],static=[Rti._bind(1),Rti._eval(1),_arrayInstanceType(1),_asBoolNullable(1),_asDoubleNullable(1),_asIntNullable(1),_asNumNullable(1),_asObject(1),_asStringNullable(1),_asTop(1),_checkBoolNullable(1),_checkDoubleNullable(1),_checkIntNullable(1),_checkNumNullable(1),_checkObject(1),_checkStringNullable(1),_generalAsCheckImplementation(1),_generalIsTestImplementation(1),_generalTypeCheckImplementation(1),_instanceType(1),_isBool(1),_isInt(1),_isNum(1),_isObject(1),_isString(1),_isTop(1),defineProperty(3),findType(1),instanceType(1),print(1)],type=[inst:Closure,inst:JSBool,inst:JSNull,inst:JSString,param:File,param:String]*/
void _doStuff(String name, File file) {
  if (file == null) {
    print('OK');
  }
  print(file.name);
}

/*member: main:
 static=[
 _doStuff,
 allowInterop<Function>(1),
 set:foo]
*/
void main() {
  foo = allowInterop(_doStuff);
}
