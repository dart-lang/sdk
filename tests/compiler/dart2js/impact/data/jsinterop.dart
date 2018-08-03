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

/*element: testJsInteropClass:dynamic=[method(0)],static=[JsInteropClass.(0)]*/
testJsInteropClass() => new JsInteropClass().method();

typedef void Callback<T>(T value);

/*element: GenericClass.:static=[JavaScriptObject.(0)]*/
@JS()
class GenericClass<T> {
  /*kernel.element: GenericClass.method:
   type=[
    check:GenericClass<dynamic>,
    check:void Function(GenericClass.T),
    inst:JSNull]
  */
  /*strong.element: GenericClass.method:
   static=[
    checkSubtype,
    getRuntimeTypeArgument,
    getRuntimeTypeArgumentIntercepted,
    getRuntimeTypeInfo,
    getTypeArgumentByIndex,
    setRuntimeTypeInfo],
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

/*element: testOptionalGenericFunctionTypeArgument:dynamic=[method(0)],static=[GenericClass.(0)]*/
testOptionalGenericFunctionTypeArgument() => new GenericClass().method();
