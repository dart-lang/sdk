// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library jsinterop;

import 'package:js/js.dart';

/*member: main:
 static=[
  testJsInteropClass(0),
  testJsInteropMethod(0),
  testOptionalGenericFunctionTypeArgument(0)]
*/
main() {
  testOptionalGenericFunctionTypeArgument();
  testJsInteropMethod();
  testJsInteropClass();
}

/*member: testJsInteropMethod:*/
@JS()
external int testJsInteropMethod();

@JS()
class JsInteropClass {
  /*member: JsInteropClass.:static=[JavaScriptObject.(0)]*/
  external JsInteropClass();

  /*member: JsInteropClass.method:
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

/*member: testJsInteropClass:
 dynamic=[JavaScriptObject.method(0)],
 static=[JsInteropClass.(0)]
*/
testJsInteropClass() => new JsInteropClass().method();

typedef void Callback<T>(T value);

/*member: GenericClass.:static=[JavaScriptObject.(0)]*/
@JS()
class GenericClass<T> {
  /*member: GenericClass.method:
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
    inst:JSNull,
    inst:JSUnmodifiableArray<dynamic>,
    param:void Function(GenericClass.T*)*]
  */
  external GenericClass method([Callback<T> callback]);
}

/*member: testOptionalGenericFunctionTypeArgument:
 dynamic=[JavaScriptObject.method(0)],
 static=[GenericClass.(0)]
*/
testOptionalGenericFunctionTypeArgument() => new GenericClass().method();
