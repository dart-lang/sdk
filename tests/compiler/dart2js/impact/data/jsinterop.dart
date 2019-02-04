// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library jsinterop;

import 'package:js/js.dart';

/*element: main:static=[testJsInteropClass(0),testJsInteropMethod(0),testOptionalGenericFunctionTypeArgument(0)]*/
main() {
  testOptionalGenericFunctionTypeArgument();
  testJsInteropMethod();
  testJsInteropClass();
}

/*strong.element: testJsInteropMethod:*/
@JS()
external int testJsInteropMethod();

@JS()
class JsInteropClass {
  /*element: JsInteropClass.:static=[JavaScriptObject.(0)]*/
  external JsInteropClass();

  /*strong.element: JsInteropClass.method:
   type=[
    native:ApplicationCacheErrorEvent,
    native:DomError,
    native:DomException,
    native:ErrorEvent,
    native:GenericClass<dynamic>,
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

/*strong.element: testJsInteropClass:
 dynamic=[JavaScriptObject.method(0)],
 static=[JsInteropClass.(0)]
*/
testJsInteropClass() => new JsInteropClass().method();

typedef void Callback<T>(T value);

/*element: GenericClass.:static=[JavaScriptObject.(0)]*/
@JS()
class GenericClass<T> {
  /*strong.element: GenericClass.method:
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
    inst:JSNull,
    inst:JSUnmodifiableArray<dynamic>,
    param:void Function(GenericClass.T)]
  */
  external GenericClass method([Callback<T> callback]);
}

/*strong.element: testOptionalGenericFunctionTypeArgument:
 dynamic=[JavaScriptObject.method(0)],
 static=[GenericClass.(0)]
*/
testOptionalGenericFunctionTypeArgument() => new GenericClass().method();
