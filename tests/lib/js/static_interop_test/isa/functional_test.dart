// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test `dart:js_interop`'s `isA` method.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

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

extension type CustomTypedArray(JSTypedArray _) implements JSObject {}

@JS('SubtypeArray')
extension type ArraySubtype._(JSArray _) implements JSObject {
  external ArraySubtype();
}

@JS()
external JSBigInt BigInt(String val);

@JS()
external JSSymbol Symbol(String val);

void testIsJSTypedArray(JSTypedArray any) {
  Expect.isTrue(any.isA<JSTypedArray>());
  Expect.isTrue(any.isA<JSTypedArray?>());
  testIsJSObject(any);
}

void testIsJSObject(JSObject any) {
  Expect.isTrue(any.isA<JSObject>());
  Expect.isTrue(any.isA<JSObject?>());
  testIsJSAny(any);
}

void testIsJSAny(JSAny any) {
  Expect.isTrue(any.isA<JSAny>());
  Expect.isTrue(any.isA<JSAny?>());
}

void main() {
  // Null.
  JSAny? nil = null;
  Expect.isTrue(nil.isA<JSString?>());
  Expect.isTrue(nil.isA<JSObject?>());
  Expect.isTrue(nil.isA<JSAny?>());
  Expect.isFalse(nil.isA<JSString>());
  Expect.isFalse(nil.isA<JSObject>());
  Expect.isFalse(nil.isA<JSAny>());

  // Test inheritance chain, nullability, and one false case.

  // Primitives.
  final jsString = ''.toJS;
  Expect.isTrue(jsString.isA<JSString>());
  Expect.isTrue(jsString.isA<JSString?>());
  testIsJSAny(jsString);
  Expect.isFalse(jsString.isA<JSSymbol>());

  final jsNum = 0.toJS;
  Expect.isTrue(jsNum.isA<JSNumber>());
  Expect.isTrue(jsNum.isA<JSNumber?>());
  testIsJSAny(jsNum);
  Expect.isFalse(jsNum.isA<JSString>());

  final jsBool = true.toJS;
  Expect.isTrue(jsBool.isA<JSBoolean>());
  Expect.isTrue(jsBool.isA<JSBoolean?>());
  testIsJSAny(jsBool);
  Expect.isFalse(jsBool.isA<JSNumber>());

  final jsBigInt = BigInt('0');
  Expect.isTrue(jsBigInt.isA<JSBigInt>());
  Expect.isTrue(jsBigInt.isA<JSBigInt?>());
  testIsJSAny(jsBigInt);
  Expect.isFalse(jsBigInt.isA<JSBoolean>());

  final jsSymbol = Symbol('symbol');
  Expect.isTrue(jsSymbol.isA<JSSymbol>());
  Expect.isTrue(jsSymbol.isA<JSSymbol?>());
  testIsJSAny(jsSymbol);
  Expect.isFalse(jsSymbol.isA<JSBigInt>());

  // Objects.
  final jsObject = ObjectLiteral(a: 0);
  testIsJSObject(jsObject);
  Expect.isFalse(jsObject.isA<JSBoolean>());
  // Note that this is true even though it's a supertype - we can't
  // differentiate between the two types. This is okay because users will get a
  // consistent error when trying to internalize it.
  Expect.isTrue(jsObject.isA<JSBoxedDartObject>());

  final jsBox = ''.toJSBox;
  Expect.isTrue(jsBox.isA<JSBoxedDartObject>());
  Expect.isTrue(jsBox.isA<JSBoxedDartObject?>());
  testIsJSObject(jsBox);
  Expect.isFalse(jsBox.isA<JSString>());

  final jsArray = <JSAny?>[].toJS;
  Expect.isTrue(jsArray.isA<JSArray>());
  Expect.isTrue(jsArray.isA<JSArray?>());
  // Can't differentiate generics.
  Expect.isTrue(jsArray.isA<JSArray<JSNumber>>());
  testIsJSObject(jsArray);
  Expect.isFalse(jsArray.isA<JSFunction>());

  final jsPromise = Future.delayed(Duration.zero).toJS;
  Expect.isTrue(jsPromise.isA<JSPromise>());
  Expect.isTrue(jsPromise.isA<JSPromise?>());
  // Can't differentiate generics.
  Expect.isTrue(jsPromise.isA<JSPromise<JSNumber>>());
  testIsJSObject(jsPromise);
  Expect.isFalse(jsPromise.isA<JSTypedArray>());

  final jsFunction = jsObject.toStr;
  Expect.isTrue(jsFunction.isA<JSFunction?>());
  Expect.isTrue(jsFunction.isA<JSFunction>());
  testIsJSObject(jsFunction);
  Expect.isFalse(jsFunction.isA<JSNumber>());
  // Note that this is true even though it's a supertype - we can't
  // differentiate between the two types. This is okay because users will get a
  // consistent error when trying to internalize it.
  Expect.isTrue(jsFunction.isA<JSExportedDartFunction>());

  final jsExportedDartFunction = () {}.toJS;
  Expect.isTrue(jsExportedDartFunction.isA<JSExportedDartFunction>());
  Expect.isTrue(jsExportedDartFunction.isA<JSExportedDartFunction?>());
  Expect.isTrue(jsExportedDartFunction.isA<JSFunction>());
  testIsJSObject(jsExportedDartFunction);
  Expect.isFalse(jsExportedDartFunction.isA<JSSymbol>());

  // Typed data.
  final jsArrayBuffer = Uint8List(1).buffer.toJS;
  Expect.isTrue(jsArrayBuffer.isA<JSArrayBuffer>());
  Expect.isTrue(jsArrayBuffer.isA<JSArrayBuffer?>());
  Expect.isFalse(jsArrayBuffer.isA<JSTypedArray>());
  testIsJSObject(jsArrayBuffer);
  Expect.isFalse(jsArrayBuffer.isA<JSArray>());

  final jsDataView = ByteData(1).toJS;
  Expect.isTrue(jsDataView.isA<JSDataView>());
  Expect.isTrue(jsDataView.isA<JSDataView?>());
  Expect.isFalse(jsDataView.isA<JSTypedArray>());
  testIsJSObject(jsDataView);
  Expect.isFalse(jsDataView.isA<JSArrayBuffer>());

  final jsUint8Array = Uint8List(1).toJS;
  Expect.isTrue(jsUint8Array.isA<JSUint8Array>());
  Expect.isTrue(jsUint8Array.isA<JSUint8Array?>());
  testIsJSTypedArray(jsUint8Array);
  Expect.isFalse(jsUint8Array.isA<JSDataView>());

  final jsUint16Array = Uint16List(1).toJS;
  Expect.isTrue(jsUint16Array.isA<JSUint16Array>());
  Expect.isTrue(jsUint16Array.isA<JSUint16Array?>());
  testIsJSTypedArray(jsUint16Array);
  Expect.isFalse(jsUint16Array.isA<JSUint8Array>());

  final jsUint32Array = Uint32List(1).toJS;
  Expect.isTrue(jsUint32Array.isA<JSUint32Array>());
  Expect.isTrue(jsUint32Array.isA<JSUint32Array?>());
  testIsJSTypedArray(jsUint32Array);
  Expect.isFalse(jsUint32Array.isA<JSUint16Array>());

  final jsUint8ClampedArray = Uint8ClampedList(1).toJS;
  Expect.isTrue(jsUint8ClampedArray.isA<JSUint8ClampedArray>());
  Expect.isTrue(jsUint8ClampedArray.isA<JSUint8ClampedArray?>());
  testIsJSTypedArray(jsUint8ClampedArray);
  Expect.isFalse(jsUint8ClampedArray.isA<JSUint32Array>());

  final jsInt8Array = Int8List(1).toJS;
  Expect.isTrue(jsInt8Array.isA<JSInt8Array>());
  Expect.isTrue(jsInt8Array.isA<JSInt8Array?>());
  testIsJSTypedArray(jsInt8Array);
  Expect.isFalse(jsInt8Array.isA<JSUint8ClampedArray>());

  final jsInt16Array = Int16List(1).toJS;
  Expect.isTrue(jsInt16Array.isA<JSInt16Array>());
  Expect.isTrue(jsInt16Array.isA<JSInt16Array?>());
  testIsJSTypedArray(jsInt16Array);
  Expect.isFalse(jsInt16Array.isA<JSInt8Array>());

  final jsInt32Array = Int32List(1).toJS;
  Expect.isTrue(jsInt32Array.isA<JSInt32Array>());
  Expect.isTrue(jsInt32Array.isA<JSInt32Array?>());
  testIsJSTypedArray(jsInt32Array);
  Expect.isFalse(jsInt32Array.isA<JSInt16Array>());

  final jsFloat32Array = Float32List(1).toJS;
  Expect.isTrue(jsFloat32Array.isA<JSFloat32Array>());
  Expect.isTrue(jsFloat32Array.isA<JSFloat32Array?>());
  testIsJSTypedArray(jsFloat32Array);
  Expect.isFalse(jsFloat32Array.isA<JSInt32Array>());

  final jsFloat64Array = Float64List(1).toJS;
  Expect.isTrue(jsFloat64Array.isA<JSFloat64Array>());
  Expect.isTrue(jsFloat64Array.isA<JSFloat64Array?>());
  testIsJSTypedArray(jsFloat64Array);
  Expect.isFalse(jsFloat64Array.isA<JSFloat32Array>());

  // User types. If they are a subtype of `JSObject`, we will use the
  // declaration name with any renaming. If not, we will use the core type.
  eval('''
    class SubtypeArray extends Array {}
    globalThis.SubtypeArray = SubtypeArray;
  ''');

  final customJsAny = CustomJSAny(jsArray);
  Expect.isFalse(customJsAny.isA<CustomJSAny>());
  Expect.isFalse(customJsAny.isA<CustomJSAny?>());
  Expect.isFalse(jsArray.isA<CustomJSAny>());
  Expect.isFalse(jsArray.isA<CustomJSAny?>());
  Expect.isTrue(nil.isA<CustomJSAny?>());
  Expect.isFalse(nil.isA<CustomJSAny>());
  Expect.isTrue(customJsAny.isA<JSArray>());
  Expect.isTrue(customJsAny.isA<JSArray?>());

  final date = Date();
  Expect.isTrue(date.isA<Date>());
  Expect.isTrue(date.isA<Date?>());
  Expect.isFalse(jsObject.isA<Date>());
  Expect.isFalse(jsObject.isA<Date?>());
  Expect.isTrue(nil.isA<Date?>());
  Expect.isFalse(nil.isA<Date>());
  Expect.isTrue(date.isA<JSObject>());
  Expect.isTrue(date.isA<JSObject?>());

  final customTypedArray = CustomTypedArray(jsUint8Array);
  Expect.isFalse(customTypedArray.isA<CustomTypedArray>());
  Expect.isFalse(customTypedArray.isA<CustomTypedArray?>());
  Expect.isFalse(jsUint8Array.isA<CustomTypedArray>());
  Expect.isFalse(jsUint8Array.isA<CustomTypedArray?>());
  Expect.isTrue(nil.isA<CustomTypedArray?>());
  Expect.isFalse(nil.isA<CustomTypedArray>());
  Expect.isTrue(customTypedArray.isA<JSTypedArray>());
  Expect.isTrue(customTypedArray.isA<JSTypedArray?>());

  final arraySubtype = ArraySubtype();
  Expect.isTrue(arraySubtype.isA<ArraySubtype>());
  Expect.isTrue(arraySubtype.isA<ArraySubtype?>());
  Expect.isFalse(jsArray.isA<ArraySubtype>());
  Expect.isFalse(jsArray.isA<ArraySubtype?>());
  Expect.isTrue(nil.isA<ArraySubtype?>());
  Expect.isFalse(nil.isA<ArraySubtype>());
  Expect.isTrue(arraySubtype.isA<JSArray>());
  Expect.isTrue(arraySubtype.isA<JSArray?>());

  // Make sure we recurse and don't reevaluate the receiver.
  var count = 0;
  Expect.isTrue((() {
    Expect.isTrue(jsObject.isA<JSObject>());
    count++;
    return jsObject;
  })()
      .isA<JSObject>());
  Expect.equals(count, 1);
}
