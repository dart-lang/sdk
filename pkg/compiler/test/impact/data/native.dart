// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' as foreign show JS;
// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';
import 'dart:html_common';

/*member: main:static=[testJSCall(0),
  testNativeField(1),
  testNativeMethod(0),
  testNativeMethodCreates(0),
  testNativeMethodReturns(0)],
  type=[inst:JSNull]*/
main() {
  testJSCall();
  testNativeMethod();
  testNativeField(null);
  testNativeMethodCreates();
  testNativeMethodReturns();
}

/*member: testJSCall:
 static=[JS<dynamic>(3)],
 type=[inst:JSNull,inst:JSString,native:bool,native:int]
*/
testJSCall() => foreign.JS(
    'int|bool|NativeUint8List|Rectangle|IdbFactory|SqlDatabase|TypedData|ContextAttributes',
    '#',
    null);

/*member: testNativeMethod:*/
@JSName('foo')
@SupportedBrowser(SupportedBrowser.CHROME)
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethod() native;

/*member: testNativeMethodCreates:
 type=[native:JSArray<JSArray.E>,native:Null,native:int]
*/
@Creates('int|Null|JSArray')
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethodCreates() native;

// This will trigger native instantiation and therefore include type use
// `native:X` for all native types. This is truncated to `type=[%]` to avoid
// dependency on the particular types. If `testNativeMethodReturns` was not
// called `testNativeMethodCreates` would instead trigger the native
// instantiations, so the blame is a bit arbitrary.
/*member: testNativeMethodReturns:type=[%]*/
@Returns('String|Null|JSArray')
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethodReturns() native;

@Native("NativeClass")
class NativeClass {
  /*member: NativeClass.field:
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
    native:JSExtendableArray<JSExtendableArray.E>,
    native:Object,
    native:String,
    native:bool,
    native:double,
    native:int,
    param:Object*]
  */
  @annotation_Creates_SerializedScriptValue
  final Object field;

  factory NativeClass._() {
    throw new UnsupportedError("Not supported");
  }
}

/*member: testNativeField:
 dynamic=[NativeClass.field],
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
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  param:NativeClass*]
*/
testNativeField(NativeClass c) => c.field;
