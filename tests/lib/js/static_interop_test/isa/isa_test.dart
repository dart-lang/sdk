// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test `dart:js_interop`'s `isA` method.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

const isJSCompiler =
    const bool.fromEnvironment('dart.library._ddc_only') ||
    const bool.fromEnvironment('dart.tool.dart2js');

@JS()
external void eval(String code);

extension type ObjectLiteral._(JSObject _) implements JSObject {
  external ObjectLiteral({int a});

  @JS('toString')
  external JSFunction get toStr;
}

extension type CustomJSAny(JSAny _) implements JSAny {}

extension type Date._(JSObject _) implements JSObject {
  external Date();
}

@JS('Date')
@staticInterop
class StaticInteropDate {}

extension type CustomTypedArray(JSTypedArray _) implements JSObject {}

@JS('SubtypeArray')
extension type ArraySubtype._(JSArray _) implements JSObject {
  external ArraySubtype();
}

extension type WrapJSBoxedDartObject(JSBoxedDartObject _)
    implements JSBoxedDartObject {}

extension type WrapJSExportedDartFunction(JSExportedDartFunction _)
    implements JSExportedDartFunction {}

@JS('WrapJSBoxedDartObject.prototype')
external JSObject get wrapJSBoxedDartObjectPrototype;

@JS('WrapJSExportedDartFunction.prototype')
external JSObject get wrapJSExportedDartFunctionPrototype;

@JS('Object.setPrototypeOf')
external void setPrototypeOf(JSObject obj, JSObject prototype);

@JS('Object.create')
external JSObject objectCreate(JSObject? proto);

@JS()
external JSBigInt BigInt(String val);

@JS()
external JSSymbol Symbol(String val);

@JS()
external JSPromise jsPromise;

@JS()
external ExternalDartReference edr;

@JS()
external JSAny? nullable;

void testIsJSTypedArray(JSTypedArray any) {
  Expect.isTrue(any.isA<JSTypedArray>());
  Expect.isTrue(any.isA<JSTypedArray?>());
  Expect.isTrue((any as Object).isA<JSTypedArray>());
  Expect.isTrue((any as Object?).isA<JSTypedArray?>());
  testIsJSObject(any);
}

void testIsJSObject(JSObject any) {
  Expect.isTrue(any.isA<JSObject>());
  Expect.isTrue(any.isA<JSObject?>());
  Expect.isTrue((any as Object).isA<JSObject>());
  Expect.isTrue((any as Object?).isA<JSObject?>());
  testIsJSAny(any);
}

void testIsJSAny(JSAny any) {
  Expect.isTrue(any.isA<JSAny>());
  Expect.isTrue(any.isA<JSAny?>());
}

void testObjectIsJSAny(Object any, {required bool expectation}) {
  Expect.equals(expectation, any.isA<JSAny>());
  Expect.equals(expectation, any.isA<JSAny?>());
}

void testNull() {
  // Null.
  JSAny? nil = null;
  Expect.isTrue(nil.isA<JSString?>());
  Expect.isTrue(nil.isA<JSObject?>());
  Expect.isTrue(nil.isA<JSAny?>());
  Expect.isTrue(nil.isA<JSBoxedDartObject?>());
  Expect.isTrue(nil.isA<JSExportedDartFunction?>());
  Expect.isFalse(nil.isA<JSString>());
  Expect.isFalse(nil.isA<JSObject>());
  Expect.isFalse(nil.isA<JSAny>());
  Expect.isFalse(nil.isA<JSBoxedDartObject>());
  Expect.isFalse(nil.isA<JSExportedDartFunction>());
  Object? nilObj = null;
  Expect.isTrue(nilObj.isA<JSString?>());
  Expect.isTrue(nilObj.isA<JSObject?>());
  Expect.isTrue(nilObj.isA<JSAny?>());
  Expect.isTrue(nilObj.isA<JSBoxedDartObject?>());
  Expect.isTrue(nilObj.isA<JSExportedDartFunction?>());
  Expect.isFalse(nilObj.isA<JSString>());
  Expect.isFalse(nilObj.isA<JSObject>());
  Expect.isFalse(nilObj.isA<JSAny>());
  Expect.isFalse(nilObj.isA<JSBoxedDartObject>());
  Expect.isFalse(nilObj.isA<JSExportedDartFunction>());
  // JS nullish values should behave no differently.
  eval('''
    globalThis.nullable = null;
  ''');
  Expect.isTrue(nullable.isA<JSString?>());
  Expect.isTrue(nullable.isA<JSObject?>());
  Expect.isTrue(nullable.isA<JSAny?>());
  Expect.isTrue(nullable.isA<JSBoxedDartObject?>());
  Expect.isTrue(nullable.isA<JSExportedDartFunction?>());
  Expect.isFalse(nullable.isA<JSString>());
  Expect.isFalse(nullable.isA<JSObject>());
  Expect.isFalse(nullable.isA<JSAny>());
  Expect.isFalse(nullable.isA<JSBoxedDartObject>());
  Expect.isFalse(nullable.isA<JSExportedDartFunction>());
  eval('''
    globalThis.nullable = undefined;
  ''');
  Expect.isTrue(nullable.isA<JSString?>());
  Expect.isTrue(nullable.isA<JSObject?>());
  Expect.isTrue(nullable.isA<JSAny?>());
  Expect.isTrue(nullable.isA<JSBoxedDartObject?>());
  Expect.isTrue(nullable.isA<JSExportedDartFunction?>());
  Expect.isFalse(nullable.isA<JSString>());
  Expect.isFalse(nullable.isA<JSObject>());
  Expect.isFalse(nullable.isA<JSAny>());
  Expect.isFalse(nullable.isA<JSBoxedDartObject>());
  Expect.isFalse(nullable.isA<JSExportedDartFunction>());
}

void testPrimitives() {
  // Strings.
  final jsString = ''.toJS;
  Expect.isTrue(jsString.isA<JSString>());
  Expect.isTrue(jsString.isA<JSString?>());
  testIsJSAny(jsString);
  Expect.isFalse(jsString.isA<JSSymbol>());

  Object jsStringObj = jsString;
  Expect.isTrue(jsStringObj.isA<JSString>());
  Expect.isTrue(jsStringObj.isA<JSString?>());
  testObjectIsJSAny(jsStringObj, expectation: true);
  Expect.isFalse(jsStringObj.isA<JSObject>());

  final string = '';
  Expect.equals(isJSCompiler, string.isA<JSString>());
  Expect.equals(isJSCompiler, string.isA<JSString?>());
  testObjectIsJSAny(string, expectation: isJSCompiler);
  Expect.isFalse(string.isA<JSObject>());

  // Numbers.
  final jsNum = 0.toJS;
  Expect.isTrue(jsNum.isA<JSNumber>());
  Expect.isTrue(jsNum.isA<JSNumber?>());
  testIsJSAny(jsNum);
  Expect.isFalse(jsNum.isA<JSString>());

  Object? jsNumObj = 0.toJS;
  Expect.isTrue(jsNumObj.isA<JSNumber>());
  testObjectIsJSAny(jsNumObj, expectation: true);
  Expect.isFalse(jsNumObj.isA<JSSymbol>());

  final number = 0;
  Expect.equals(isJSCompiler, number.isA<JSNumber>());
  Expect.equals(isJSCompiler, number.isA<JSNumber?>());
  testObjectIsJSAny(number, expectation: isJSCompiler);
  Expect.isFalse(number.isA<JSSymbol>());

  // Booleans.
  final jsBool = true.toJS;
  Expect.isTrue(jsBool.isA<JSBoolean>());
  Expect.isTrue(jsBool.isA<JSBoolean?>());
  testIsJSAny(jsBool);
  Expect.isFalse(jsBool.isA<JSNumber>());

  Object jsBoolObj = jsBool;
  Expect.isTrue(jsBoolObj.isA<JSBoolean>());
  testObjectIsJSAny(jsBoolObj, expectation: true);
  Expect.isFalse(jsBoolObj.isA<JSString>());

  final boolean = false;
  Expect.equals(isJSCompiler, boolean.isA<JSBoolean>());
  Expect.equals(isJSCompiler, boolean.isA<JSBoolean?>());
  testObjectIsJSAny(boolean, expectation: isJSCompiler);
  Expect.isFalse(boolean.isA<JSString>());

  // BigInts.
  final jsBigInt = BigInt('0');
  Expect.isTrue(jsBigInt.isA<JSBigInt>());
  Expect.isTrue(jsBigInt.isA<JSBigInt?>());
  testIsJSAny(jsBigInt);
  Expect.isFalse(jsBigInt.isA<JSBoolean>());

  Object? jsBigIntObj = jsBigInt;
  Expect.isTrue(jsBigIntObj.isA<JSBigInt>());
  testObjectIsJSAny(jsBigIntObj, expectation: true);
  Expect.isFalse(jsBigIntObj.isA<JSString>());

  // Symbols.
  final jsSymbol = JSSymbol('symbol');
  Expect.isTrue(jsSymbol.isA<JSSymbol>());
  Expect.isTrue(jsSymbol.isA<JSSymbol?>());
  testIsJSAny(jsSymbol);
  Expect.isFalse(jsSymbol.isA<JSBigInt>());

  Object jsSymbolObj = jsSymbol;
  Expect.isTrue(jsSymbolObj.isA<JSSymbol>());
  testObjectIsJSAny(jsSymbolObj, expectation: true);
  Expect.isFalse(jsSymbolObj.isA<JSObject>());
}

void testJSObjects() {
  // Literals.
  final jsObject = ObjectLiteral(a: 0);
  testIsJSObject(jsObject);
  Expect.isFalse(jsObject.isA<JSBoolean>());
  Expect.isFalse((jsObject as Object?).isA<JSTypedArray>());

  // Object with no prototype.
  final jsObjectNoProto = objectCreate(null);
  testIsJSObject(jsObjectNoProto);
  Expect.isFalse(jsObjectNoProto.isA<JSInt8Array>());

  // JSBoxedDartObject.
  final jsBox = ''.toJSBox;
  Expect.isTrue(jsBox.isA<JSBoxedDartObject>());
  testIsJSObject(jsBox);
  Expect.isFalse(jsBox.isA<JSString>());

  Object? jsBoxObj = jsBox;
  Expect.isTrue(jsBoxObj.isA<JSBoxedDartObject>());
  Expect.isFalse(jsBoxObj.isA<JSFunction>());

  // While `JSBoxedDartObject`s are just `Object`s, we do additional checking to
  // make sure `isA` checks this actually is a `JSBoxedDartObject`.
  Expect.isFalse(jsObject.isA<JSBoxedDartObject>());
  Expect.isFalse(JSArray().isA<JSBoxedDartObject>());
  Expect.isFalse((jsObject as Object?).isA<JSBoxedDartObject>());
  Expect.isFalse(''.isA<JSBoxedDartObject>());
  // Check that property access on primitives isn't invalid.
  Expect.isFalse(0.toJS.isA<JSBoxedDartObject>());
  Expect.isFalse(true.toJS.isA<JSBoxedDartObject>());
  Expect.isFalse(''.toJS.isA<JSBoxedDartObject>());
  Expect.isFalse(BigInt('0').isA<JSBoxedDartObject>());
  Expect.isFalse(JSSymbol('symbol').isA<JSBoxedDartObject>());

  // JSArray.
  final jsArray = <JSAny?>[].toJS;
  Expect.isTrue(jsArray.isA<JSArray>());
  Expect.isTrue(jsArray.isA<JSArray?>());
  // Can't differentiate generics.
  Expect.isTrue(jsArray.isA<JSArray<JSNumber>>());
  testIsJSObject(jsArray);
  Expect.isFalse(jsArray.isA<JSFunction>());

  Object jsArrayObj = JSArray();
  Expect.isTrue(jsArrayObj.isA<JSArray>());
  Expect.isTrue(jsArrayObj.isA<JSArray<JSFunction>>());
  Expect.isFalse(jsArrayObj.isA<JSPromise>());

  // JSPromise.
  eval('''
    globalThis.jsPromise = new Promise((resolve, reject) => {
      resolve('done');
    });
  ''');
  Expect.isTrue(jsPromise.isA<JSPromise>());
  Expect.isTrue(jsPromise.isA<JSPromise?>());
  // Can't differentiate generics.
  Expect.isTrue(jsPromise.isA<JSPromise<JSNumber>>());
  testIsJSObject(jsPromise);
  Expect.isFalse(jsPromise.isA<JSTypedArray>());

  Object? jsPromiseObj = Future.delayed(Duration.zero).toJS;
  Expect.isTrue(jsPromiseObj.isA<JSPromise>());
  Expect.isTrue(jsPromiseObj.isA<JSPromise<JSString>>());
  Expect.isFalse(jsPromise.isA<JSFunction>());

  // JSFunction.
  final jsFunction = jsObject.toStr;
  Expect.isTrue(jsFunction.isA<JSFunction>());
  Expect.isTrue(jsFunction.isA<JSFunction?>());
  testIsJSObject(jsFunction);
  Expect.isFalse(jsFunction.isA<JSNumber>());
  Expect.isFalse(jsFunction.isA<JSExportedDartFunction>());

  Object jsFunctionObj = jsFunction;
  Expect.isTrue(jsFunctionObj.isA<JSFunction>());
  Expect.isFalse(jsFunctionObj.isA<JSBoxedDartObject>());
  Expect.isFalse(jsFunctionObj.isA<JSExportedDartFunction>());

  // JSExportedDartFunction.
  final jsExportedDartFunction = () {}.toJS;
  Expect.isTrue(jsExportedDartFunction.isA<JSExportedDartFunction>());
  Expect.isTrue(jsExportedDartFunction.isA<JSExportedDartFunction?>());
  Expect.isTrue(jsExportedDartFunction.isA<JSFunction>());
  testIsJSObject(jsExportedDartFunction);
  Expect.isFalse(jsExportedDartFunction.isA<JSSymbol>());

  Object? jsExportedDartFunctionObj = jsExportedDartFunction;
  Expect.isTrue(jsExportedDartFunctionObj.isA<JSExportedDartFunction>());
  Expect.isTrue(jsExportedDartFunctionObj.isA<JSFunction>());
  Expect.isFalse(jsExportedDartFunctionObj.isA<JSString>());
}

void testTypedData() {
  // JSArrayBuffer.
  final jsArrayBuffer = Uint8List(1).buffer.toJS;
  Expect.isTrue(jsArrayBuffer.isA<JSArrayBuffer>());
  Expect.isTrue(jsArrayBuffer.isA<JSArrayBuffer?>());
  Expect.isFalse(jsArrayBuffer.isA<JSTypedArray>());
  testIsJSObject(jsArrayBuffer);
  Expect.isFalse(jsArrayBuffer.isA<JSArray>());

  Object jsArrayBufferObject = JSArrayBuffer(1);
  Expect.isTrue(jsArrayBufferObject.isA<JSArrayBuffer>());
  Expect.isFalse(jsArrayBufferObject.isA<JSTypedArray>());
  Expect.isFalse(jsArrayBufferObject.isA<JSUint8Array>());

  // JSDataView.
  final jsDataView = ByteData(1).toJS;
  Expect.isTrue(jsDataView.isA<JSDataView>());
  Expect.isTrue(jsDataView.isA<JSDataView?>());
  Expect.isFalse(jsDataView.isA<JSTypedArray>());
  testIsJSObject(jsDataView);
  Expect.isFalse(jsDataView.isA<JSArrayBuffer>());

  Object jsDataViewObj = JSDataView(JSArrayBuffer(1));
  Expect.isTrue(jsDataViewObj.isA<JSDataView>());
  Expect.isFalse(jsDataViewObj.isA<JSTypedArray>());
  Expect.isFalse(jsDataViewObj.isA<JSUint32Array>());

  // JSUint8Array.
  final jsUint8Array = Uint8List(1).toJS;
  Expect.isTrue(jsUint8Array.isA<JSUint8Array>());
  Expect.isTrue(jsUint8Array.isA<JSUint8Array?>());
  testIsJSTypedArray(jsUint8Array);
  Expect.isFalse(jsUint8Array.isA<JSDataView>());

  Object jsUint8ArrayObj = JSUint8Array();
  Expect.isTrue(jsUint8ArrayObj.isA<JSUint8Array>());
  Expect.isFalse(jsUint8ArrayObj.isA<JSFunction>());

  // JSUint16Array.
  final jsUint16Array = Uint16List(1).toJS;
  Expect.isTrue(jsUint16Array.isA<JSUint16Array>());
  Expect.isTrue(jsUint16Array.isA<JSUint16Array?>());
  testIsJSTypedArray(jsUint16Array);
  Expect.isFalse(jsUint16Array.isA<JSUint8Array>());

  Object? jsUint16ArrayObj = JSUint16Array();
  Expect.isTrue(jsUint16ArrayObj.isA<JSUint16Array>());
  Expect.isFalse(jsUint16ArrayObj.isA<JSUint32Array>());

  // JSUint32Array.
  final jsUint32Array = Uint32List(1).toJS;
  Expect.isTrue(jsUint32Array.isA<JSUint32Array>());
  Expect.isTrue(jsUint32Array.isA<JSUint32Array?>());
  testIsJSTypedArray(jsUint32Array);
  Expect.isFalse(jsUint32Array.isA<JSUint16Array>());

  Object? jsUint32ArrayObj = JSUint32Array();
  Expect.isTrue(jsUint32ArrayObj.isA<JSUint32Array>());
  Expect.isFalse(jsUint32ArrayObj.isA<JSUint8Array>());

  // JSUint8ClampedArray.
  final jsUint8ClampedArray = Uint8ClampedList(1).toJS;
  Expect.isTrue(jsUint8ClampedArray.isA<JSUint8ClampedArray>());
  Expect.isTrue(jsUint8ClampedArray.isA<JSUint8ClampedArray?>());
  testIsJSTypedArray(jsUint8ClampedArray);
  Expect.isFalse(jsUint8ClampedArray.isA<JSUint32Array>());

  Object jsUint8ClampedArrayObj = JSUint8ClampedArray();
  Expect.isTrue(jsUint8ClampedArrayObj.isA<JSUint8ClampedArray>());
  Expect.isFalse(jsUint8ClampedArrayObj.isA<JSInt8Array>());

  // JSInt8Array.
  final jsInt8Array = Int8List(1).toJS;
  Expect.isTrue(jsInt8Array.isA<JSInt8Array>());
  Expect.isTrue(jsInt8Array.isA<JSInt8Array?>());
  testIsJSTypedArray(jsInt8Array);
  Expect.isFalse(jsInt8Array.isA<JSUint8ClampedArray>());

  Object? jsInt8ArrayObject = JSInt8Array();
  Expect.isTrue(jsInt8ArrayObject.isA<JSInt8Array>());
  Expect.isFalse(jsInt8ArrayObject.isA<JSUint16Array>());

  // JSInt16Array.
  final jsInt16Array = Int16List(1).toJS;
  Expect.isTrue(jsInt16Array.isA<JSInt16Array>());
  Expect.isTrue(jsInt16Array.isA<JSInt16Array?>());
  testIsJSTypedArray(jsInt16Array);
  Expect.isFalse(jsInt16Array.isA<JSInt8Array>());

  Object jsInt16ArrayObj = JSInt16Array();
  Expect.isTrue(jsInt16ArrayObj.isA<JSInt16Array>());
  Expect.isFalse(jsInt16ArrayObj.isA<JSUint8ClampedArray>());

  // JSInt32Array.
  final jsInt32Array = Int32List(1).toJS;
  Expect.isTrue(jsInt32Array.isA<JSInt32Array>());
  Expect.isTrue(jsInt32Array.isA<JSInt32Array?>());
  testIsJSTypedArray(jsInt32Array);
  Expect.isFalse(jsInt32Array.isA<JSInt16Array>());

  Object? jsInt32ArrayObj = JSInt32Array();
  Expect.isTrue(jsInt32ArrayObj.isA<JSInt32Array>());
  Expect.isFalse(jsInt32ArrayObj.isA<JSFloat32Array>());

  // JSFloat32Array.
  final jsFloat32Array = Float32List(1).toJS;
  Expect.isTrue(jsFloat32Array.isA<JSFloat32Array>());
  Expect.isTrue(jsFloat32Array.isA<JSFloat32Array?>());
  testIsJSTypedArray(jsFloat32Array);
  Expect.isFalse(jsFloat32Array.isA<JSInt32Array>());

  Object jsFloat32ArrayObj = JSFloat32Array();
  Expect.isTrue(jsFloat32ArrayObj.isA<JSFloat32Array>());
  Expect.isFalse(jsFloat32ArrayObj.isA<JSUint16Array>());

  // JSFloat64Array.
  final jsFloat64Array = Float64List(1).toJS;
  Expect.isTrue(jsFloat64Array.isA<JSFloat64Array>());
  Expect.isTrue(jsFloat64Array.isA<JSFloat64Array?>());
  testIsJSTypedArray(jsFloat64Array);
  Expect.isFalse(jsFloat64Array.isA<JSFloat32Array>());

  Object? jsFloat64ArrayObj = JSFloat64Array();
  Expect.isTrue(jsFloat64ArrayObj.isA<JSFloat64Array>());
  Expect.isFalse(jsFloat64ArrayObj.isA<JSInt16Array>());
}

void testUserTypes() {
  // User types. If they wrap a subtype of `JSObject` or wrap `JSAny`, we will
  // use the declaration name with any renaming.

  // Test a wrapper around `JSAny`.
  final customJsAny = CustomJSAny(JSArray());
  final jsArray = JSArray();
  JSAny? nil = null;
  Expect.isFalse(customJsAny.isA<CustomJSAny>());
  Expect.isFalse(customJsAny.isA<CustomJSAny?>());
  Expect.isFalse(jsArray.isA<CustomJSAny>());
  Expect.isFalse(jsArray.isA<CustomJSAny?>());
  Expect.isTrue(null.isA<CustomJSAny?>());
  Expect.isFalse(nil.isA<CustomJSAny>());
  Expect.isTrue(customJsAny.isA<JSArray>());
  Expect.isTrue(customJsAny.isA<JSArray?>());

  Object? customAnyObj = customJsAny;
  Object jsArrayObj = jsArray;
  Object? nilObj = null;
  Expect.isFalse(customAnyObj.isA<CustomJSAny>());
  Expect.isFalse(jsArrayObj.isA<CustomJSAny>());
  Expect.isTrue(nilObj.isA<CustomJSAny?>());
  Expect.isFalse(nilObj.isA<CustomJSAny>());
  Expect.isTrue(customAnyObj.isA<JSArray>());

  // Test a real type in the browser.
  final date = Date();
  final jsObject = JSObject();
  Expect.isTrue(date.isA<Date>());
  Expect.isTrue(date.isA<Date?>());
  Expect.isFalse(jsObject.isA<Date>());
  Expect.isFalse(jsObject.isA<Date?>());
  Expect.isTrue(nil.isA<Date?>());
  Expect.isFalse(nil.isA<Date>());
  Expect.isTrue(date.isA<JSObject>());
  Expect.isTrue(date.isA<JSObject?>());

  Object? dateObj = date;
  Object jsObjectObj = jsObject;
  Expect.isTrue(dateObj.isA<Date>());
  Expect.isFalse(jsObjectObj.isA<Date>());
  Expect.isTrue(dateObj.isA<JSObject>());

  final staticInteropDate = date as StaticInteropDate;
  Expect.isTrue(staticInteropDate.isA<Date>());

  // Test a wrapper around `JSTypedArray`.
  final jsUint8Array = JSUint8Array();
  final customTypedArray = CustomTypedArray(jsUint8Array);
  Expect.isFalse(customTypedArray.isA<CustomTypedArray>());
  Expect.isFalse(customTypedArray.isA<CustomTypedArray?>());
  Expect.isFalse(jsUint8Array.isA<CustomTypedArray>());
  Expect.isFalse(jsUint8Array.isA<CustomTypedArray?>());
  Expect.isTrue(nil.isA<CustomTypedArray?>());
  Expect.isFalse(nil.isA<CustomTypedArray>());
  Expect.isTrue(customTypedArray.isA<JSTypedArray>());
  Expect.isTrue(customTypedArray.isA<JSTypedArray?>());

  Object? jsUint8ArrayObj = jsUint8Array;
  Object customTypedArrayObj = customTypedArray;
  Expect.isFalse(customTypedArrayObj.isA<CustomTypedArray>());
  Expect.isFalse(jsUint8ArrayObj.isA<CustomTypedArray>());
  Expect.isTrue(customTypedArrayObj.isA<JSTypedArray>());

  // Test `JSBoxedDartObject` before and after we modify its prototype.
  eval('''
    class WrapJSBoxedDartObject {}
    globalThis.WrapJSBoxedDartObject = WrapJSBoxedDartObject;
  ''');
  final wrapJsBox = WrapJSBoxedDartObject(''.toJSBox);
  Expect.isFalse(wrapJsBox.isA<WrapJSBoxedDartObject>());
  Expect.isFalse(wrapJsBox.isA<WrapJSBoxedDartObject?>());
  Expect.isTrue(nil.isA<WrapJSBoxedDartObject?>());
  Expect.isFalse(nil.isA<WrapJSBoxedDartObject>());

  Object? wrapJsBoxObj = wrapJsBox;
  Expect.isFalse(wrapJsBoxObj.isA<WrapJSBoxedDartObject>());

  setPrototypeOf(wrapJsBox, wrapJSBoxedDartObjectPrototype);
  Expect.isTrue(wrapJsBox.isA<WrapJSBoxedDartObject>());
  Expect.isTrue(wrapJsBox.isA<WrapJSBoxedDartObject?>());
  Expect.isTrue(wrapJsBoxObj.isA<WrapJSBoxedDartObject>());

  // Test that a type wrapping `JSExportedDartFunction` should have a different
  // type-check.
  eval('''
    class WrapJSExportedDartFunction {}
    globalThis.WrapJSExportedDartFunction = WrapJSExportedDartFunction;
  ''');
  final wrapJsEdf = WrapJSExportedDartFunction(() {}.toJS);
  Expect.isFalse(wrapJsEdf.isA<WrapJSExportedDartFunction>());
  setPrototypeOf(wrapJsEdf, wrapJSExportedDartFunctionPrototype);
  Expect.isTrue(wrapJsEdf.isA<WrapJSExportedDartFunction>());
  Expect.isTrue(nil.isA<WrapJSExportedDartFunction?>());
  Expect.isFalse(nil.isA<WrapJSExportedDartFunction>());

  Object? wrapJsEdfObj = wrapJsEdf;
  Expect.isTrue(wrapJsEdfObj.isA<WrapJSExportedDartFunction>());

  // Test subtyping a type in the browser.
  eval('''
    class SubtypeArray extends Array {}
    globalThis.SubtypeArray = SubtypeArray;
  ''');
  final arraySubtype = ArraySubtype();
  Expect.isTrue(arraySubtype.isA<ArraySubtype>());
  Expect.isTrue(arraySubtype.isA<ArraySubtype?>());
  Expect.isFalse(jsArray.isA<ArraySubtype>());
  Expect.isFalse(jsArray.isA<ArraySubtype?>());
  Expect.isTrue(nil.isA<ArraySubtype?>());
  Expect.isFalse(nil.isA<ArraySubtype>());
  Expect.isTrue(arraySubtype.isA<JSArray>());
  Expect.isTrue(arraySubtype.isA<JSArray?>());

  Object arraySubtypeObj = arraySubtype;
  Expect.isTrue(arraySubtypeObj.isA<ArraySubtype>());
  Expect.isFalse(jsArrayObj.isA<ArraySubtype>());
  Expect.isTrue(arraySubtypeObj.isA<JSArray>());
}

void testExternalDartReference() {
  final strExternalReference = ''.toExternalReference;
  Expect.equals(isJSCompiler, strExternalReference.isA<JSString>());
  Expect.equals(isJSCompiler, strExternalReference.isA<JSString?>());
  testObjectIsJSAny(strExternalReference as Object, expectation: isJSCompiler);
  Expect.isFalse(strExternalReference.isA<JSObject>());

  final arrayExternalReference = [].toExternalReference;
  Expect.equals(isJSCompiler, arrayExternalReference.isA<JSArray>());
  Expect.equals(isJSCompiler, arrayExternalReference.isA<JSArray?>());
  Expect.equals(isJSCompiler, arrayExternalReference.isA<JSObject>());
  Expect.equals(isJSCompiler, arrayExternalReference.isA<JSObject?>());
  testObjectIsJSAny(
    arrayExternalReference as Object,
    expectation: isJSCompiler,
  );

  // Round-trip through JS so any boxing needs to recalculate whether this is a
  // JS value.
  edr = () {}.toExternalReference;
  Expect.isFalse(edr.isA<JSObject>());
  Expect.isFalse(edr.isA<JSObject?>());
  Expect.isFalse(edr.isA<JSAny>());
  Expect.isFalse(edr.isA<JSAny?>());

  final dartObjectExternalReference = () {}.toExternalReference;
  Expect.isFalse(dartObjectExternalReference.isA<JSObject>());
  Expect.isFalse(dartObjectExternalReference.isA<JSObject?>());
  Expect.isFalse(dartObjectExternalReference.isA<JSAny>());
  Expect.isFalse(dartObjectExternalReference.isA<JSAny?>());
  // This is cheating the type system, but we want to verify `isA` still returns
  // the right values even if the user does a wrong cast.
  JSAny wrongJSAny = dartObjectExternalReference as JSAny;
  Expect.isFalse(wrongJSAny.isA<JSObject>());
  Expect.isFalse(wrongJSAny.isA<JSObject?>());
  Expect.isFalse(wrongJSAny.isA<JSAny>());
  Expect.isFalse(wrongJSAny.isA<JSAny?>());
  // Erroneous cast but other way around and with a round-trip.
  final wrongEdr = JSObject() as ExternalDartReference;
  Expect.isTrue(wrongEdr.isA<JSObject>());
  Expect.isTrue(wrongEdr.isA<JSObject?>());
  Expect.isTrue(wrongEdr.isA<JSAny>());
  Expect.isTrue(wrongEdr.isA<JSAny?>());
  edr = wrongEdr;
  Expect.isTrue(edr.isA<JSObject>());
  Expect.isTrue(edr.isA<JSObject?>());
  Expect.isTrue(edr.isA<JSAny>());
  Expect.isTrue(edr.isA<JSAny?>());

  ExternalDartReference? nilRef = null;
  Expect.isFalse(nilRef.isA<JSAny>());
  Expect.isTrue(nilRef.isA<JSAny?>());
  Expect.isTrue(nilRef.isA<JSObject?>());
}

void testEvaluateOnce() {
  // Make sure we recursively visit the receiver node but only evaluate it once.
  var count = 0;
  final jsObject = JSObject();
  Expect.isTrue(
    (() {
      Expect.isTrue(jsObject.isA<JSObject>());
      count++;
      return jsObject;
    })().isA<JSObject>(),
  );
  Expect.equals(count, 1);

  Object jsObjectObj = jsObject;
  Expect.isTrue(
    (() {
      Expect.isTrue(jsObjectObj.isA<JSObject>());
      count++;
      return jsObjectObj;
    })().isA<JSObject>(),
  );
  Expect.equals(count, 2);
}

void main() {
  testNull();
  testPrimitives();
  testJSObjects();
  testTypedData();
  testUserTypes();
  testExternalDartReference();
  testEvaluateOnce();
}
