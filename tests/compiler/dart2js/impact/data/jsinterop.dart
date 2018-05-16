// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library jsinterop;

import 'package:js/js.dart';

/*element: main:static=[testJsInteropClass(0),testJsInteropMethod(0)]*/
main() {
  testJsInteropMethod();
  testJsInteropClass();
}

/*kernel.element: testJsInteropMethod:type=[check:int]*/
/*strong.element: testJsInteropMethod:*/
@JS()
external int testJsInteropMethod();

@JS()
class JsInteropClass {
  /*element: JsInteropClass.:static=[JavaScriptObject.(0)]*/
  external JsInteropClass();

  /*kernel.element: JsInteropClass.method:
   type=[
    check:double,
    native:ApplicationCacheErrorEvent,
    native:DomError,
    native:DomException,
    native:ErrorEvent,
    native:JsInteropClass,
    native:MediaError,
    native:NavigatorUserMediaError,
    native:OverconstrainedError,
    native:PositionError,
    native:SensorErrorEvent,
    native:SpeechRecognitionError,
    native:SqlError]
  */
  /*strong.element: JsInteropClass.method:
   type=[
    native:ApplicationCacheErrorEvent,
    native:DomError,
    native:DomException,
    native:ErrorEvent,
    native:JsInteropClass,
    native:MediaError,
    native:NavigatorUserMediaError,
    native:OverconstrainedError,
    native:PositionError,
    native:SensorErrorEvent,
    native:SpeechRecognitionError,
    native:SqlError]
  */
  @JS()
  external double method();
}

/*element: testJsInteropClass:dynamic=[method(0)],static=[JsInteropClass.(0)]*/
testJsInteropClass() => new JsInteropClass().method();
