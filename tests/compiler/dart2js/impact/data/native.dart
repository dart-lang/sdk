// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' as foreign show JS;
// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';
import 'dart:html_common';

/*element: main:static=[testJSCall(0),
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

/*kernel.element: testJSCall:
 static=[JS(3)],
 type=[inst:JSNull,inst:JSString,native:bool,native:int]
*/
/*strong.element: testJSCall:
 static=[JS<dynamic>(3)],
 type=[inst:JSNull,inst:JSString,native:bool,native:int]
*/
testJSCall() => foreign.JS(
    'int|bool|NativeUint8List|Rectangle|IdbFactory|SqlDatabase|TypedData|ContextAttributes',
    '#',
    null);

/*element: testNativeMethod:*/
@JSName('foo')
@SupportedBrowser(SupportedBrowser.CHROME)
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethod() native;

/*element: testNativeMethodCreates:
 type=[native:JSArray<JSArray.E>,native:Null,native:int]
*/
@Creates('int|Null|JSArray')
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethodCreates() native;

// This will trigger native instantiation and therefore include type use
// `native:X` for all native types. This is truncated to `type=[*]` to avoid
// dependency on the particular types. If `testNativeMethodReturns` was not
// called `testNativeMethodCreates` would instead trigger the native
// instantiations, so the blame is a bit arbitrary.
/*element: testNativeMethodReturns:type=[*]*/
@Returns('String|Null|JSArray')
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
testNativeMethodReturns() native;

@Native("NativeClass")
class NativeClass {
  /*kernel.element: NativeClass.field:
   type=[
    check:Object,
    inst:JSNull,
    native:JSExtendableArray<JSExtendableArray.E>,
    native:Object,
    native:String,
    native:bool,
    native:double,
    native:int]
  */
  /*strong.element: NativeClass.field:
   type=[
    inst:JSBool,
    inst:JSNull,
    native:JSExtendableArray<JSExtendableArray.E>,
    native:Object,
    native:String,
    native:bool,
    native:double,
    native:int,
    param:Object]
  */
  @annotation_Creates_SerializedScriptValue
  final Object field;

  factory NativeClass._() {
    throw new UnsupportedError("Not supported");
  }
}

/*kernel.element: testNativeField:
 dynamic=[field],
 type=[check:NativeClass]
*/
/*strong.element: testNativeField:
 dynamic=[field],
 static=[defineProperty],
 type=[inst:JSBool,param:NativeClass]
*/
testNativeField(NativeClass c) => c.field;
