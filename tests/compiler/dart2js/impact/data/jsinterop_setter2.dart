// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library main;

import 'dart:html' show File;

import 'package:js/js.dart';

/*member: foo=:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
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
  param:void Function(String,File)]
*/
@JS()
external set foo(void Function(String, File) f);

/*member: _doStuff:
 dynamic=[File.==,File.name],
 static=[defineProperty(3),print(1)],
 type=[inst:JSBool,inst:JSNull,inst:JSString,param:File,param:String]
*/
void _doStuff(String name, File file) {
  if (file == null) {
    print('OK');
  }
  print(file.name);
}

/*member: main:
 static=[
  _doStuff,
  allowInterop<void Function(String,File)>(1),
  set:foo]
*/
void main() {
  foo = allowInterop(_doStuff);
}
