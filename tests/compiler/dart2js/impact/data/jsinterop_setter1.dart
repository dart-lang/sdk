// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library main;

import 'dart:html' show File;

import 'package:js/js.dart';

/*member: foo=:
 type=[
  inst:JSBool,
  native:ApplicationCacheErrorEvent,
  native:DomError,
  native:DomException,
  native:ErrorEvent,
  native:MediaError,
  native:NavigatorUserMediaError,
  native:OverconstrainedError,
  native:PositionError,
  native:SensorErrorEvent,
  native:SpeechRecognitionError,
  native:SqlError,
  param:Function]
 */
@JS()
external set foo(Function f);

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
 allowInterop<Function>(1),
 set:foo]
*/
void main() {
  foo = allowInterop(_doStuff);
}
