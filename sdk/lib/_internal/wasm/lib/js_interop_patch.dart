// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' hide JS;
import 'dart:_js_helper' as js_helper;
import 'dart:_js_types' as js_types;
import 'dart:_wasm';
import 'dart:async' show Completer;
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// Some helpers for working with JS types internally. If we implement the JS
/// types as inline classes then these should go away.
/// TODO(joshualitt): Find a way to get rid of the explicit casts.
T _box<T>(WasmExternRef? ref) => JSValue(ref) as T;

// TODO(joshualitt): Eventually delete `dart:js_util` on Dart2Wasm and migrate
// any used logic to this file.
@patch
JSObject get globalJSObject => js_util.globalThis as JSObject;

/// Helper for working with the [JSAny?] top type in a backend agnostic way.
@patch
extension NullableUndefineableJSAnyExtension on JSAny? {
  // TODO(joshualitt): To support incremental migration of existing users to
  // reified `JSUndefined` and `JSNull`, we have to handle the case where
  // `this == null`. However, after migration we can remove these checks.
  @patch
  bool get isUndefined => this == null || isJSUndefined(this?.toExternRef);

  @patch
  bool get isNull => this == null || this!.toExternRef.isNull;

  @patch
  JSBoolean typeofEquals(JSString type) =>
      _box<JSBoolean>(js_helper.JS<WasmExternRef?>(
          '(o, t) => typeof o === t', this?.toExternRef, type.toExternRef));

  @patch
  Object? dartify() => js_util.dartify(this);
}

/// Utility extensions for [Object?].
@patch
extension NullableObjectUtilExtension on Object? {
  @patch
  JSAny? jsify() => js_util.jsify(this) as JSAny?;
}

/// Utility extensions for [JSObject].
@patch
extension JSObjectUtilExtension on JSObject {
  @patch
  JSBoolean instanceof(JSFunction constructor) =>
      _box<JSBoolean>(js_helper.JS<WasmExternRef?>(
          '(o, c) => o instanceof c', toExternRef, constructor.toExternRef));
}

/// [JSExportedDartFunction] <-> [Function]
@patch
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart => unwrapJSWrappedDartFunction(toExternRef);
}

@patch
extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => throw UnimplementedError();
}

/// [JSBoxedDartObject] <-> [Object]
@patch
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  @patch
  Object get toDart => jsObjectToDartObject(toExternRef);
}

@patch
extension ObjectToJSBoxedDartObject on Object {
  // TODO(srujzs): Remove.
  @patch
  JSBoxedDartObject get toJS =>
      _box<JSBoxedDartObject>(jsObjectFromDartObject(this));

  @patch
  JSBoxedDartObject get toJSBox {
    if (this is JSValue) {
      throw 'Attempting to box non-Dart object.';
    }
    return _box<JSBoxedDartObject>(jsObjectFromDartObject(this));
  }
}

/// [JSPromise] -> [Future<JSAny?>].
@patch
extension JSPromiseToFuture on JSPromise {
  @patch
  Future<JSAny?> get toDart {
    final completer = Completer<JSAny>();
    final success = (JSAny r) {
      return completer.complete(r);
    }.toJS;
    final error = (JSAny e) {
      // TODO(joshualitt): Investigate reifying `JSNull` and `JSUndefined` on
      // all backends and if it is feasible, or feasible for some limited use
      // cases, then we should pass [e] directly to `completeError`.
      // TODO(joshualitt): Use helpers to avoid conflating `null` and `JSNull` /
      // `JSUndefined`.
      if (e == null) {
        return completer.completeError(js_util.NullRejectionException(false));
      }
      return completer.completeError(e);
    }.toJS;
    promiseThen(toExternRef, success.toExternRef, error.toExternRef);
    return completer.future;
  }
}

/// [JSArrayBuffer] <-> [ByteBuffer]
@patch
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer get toDart => toDartByteBuffer(toExternRef);
}

@patch
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  JSArrayBuffer get toJS =>
      _box<JSArrayBuffer>(jsArrayBufferFromDartByteBuffer(this));
}

/// [JSDataView] <-> [ByteData]
@patch
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => toDartByteData(toExternRef);
}

@patch
extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS => _box<JSDataView>(
      jsDataViewFromDartByteData(this, lengthInBytes.toDouble()));
}

/// [JSInt8Array] <-> [Int8List]
@patch
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => toDartInt8List(toExternRef);
}

@patch
extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS => _box<JSInt8Array>(jsInt8ArrayFromDartInt8List(this));
}

/// [JSUint8Array] <-> [Uint8List]
@patch
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => toDartUint8List(toExternRef);
}

@patch
extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS =>
      _box<JSUint8Array>(jsUint8ArrayFromDartUint8List(this));
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
@patch
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart => toDartUint8ClampedList(toExternRef);
}

@patch
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS => _box<JSUint8ClampedArray>(
      jsUint8ClampedArrayFromDartUint8ClampedList(this));
}

/// [JSInt16Array] <-> [Int16List]
@patch
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => toDartInt16List(toExternRef);
}

@patch
extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS =>
      _box<JSInt16Array>(jsInt16ArrayFromDartInt16List(this));
}

/// [JSUint16Array] <-> [Uint16List]
@patch
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => toDartUint16List(toExternRef);
}

@patch
extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS =>
      _box<JSUint16Array>(jsUint16ArrayFromDartUint16List(this));
}

/// [JSInt32Array] <-> [Int32List]
@patch
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => toDartInt32List(toExternRef);
}

@patch
extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS =>
      _box<JSInt32Array>(jsInt32ArrayFromDartInt32List(this));
}

/// [JSUint32Array] <-> [Uint32List]
@patch
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => toDartUint32List(toExternRef);
}

@patch
extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS =>
      _box<JSUint32Array>(jsUint32ArrayFromDartUint32List(this));
}

/// [JSFloat32Array] <-> [Float32List]
@patch
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart => toDartFloat32List(toExternRef);
}

@patch
extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS =>
      _box<JSFloat32Array>(jsFloat32ArrayFromDartFloat32List(this));
}

/// [JSFloat64Array] <-> [Float64List]
@patch
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart => toDartFloat64List(toExternRef);
}

@patch
extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS =>
      _box<JSFloat64Array>(jsFloat64ArrayFromDartFloat64List(this));
}

/// [JSArray] <-> [List]
@patch
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> get toDart => toDartListJSAny(toExternRef);
}

@patch
extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray get toJS => toJSArray(this);
}

/// [JSNumber] -> [double] or [int].
@patch
extension JSNumberToNumber on JSNumber {
  // TODO(srujzs): Remove.
  @patch
  double get toDart => toDartDouble;

  @patch
  double get toDartDouble => toDartNumber(toExternRef);

  @patch
  int get toDartInt {
    final number = toDartNumber(toExternRef);
    final intVal = number.toInt();
    if (number == intVal) {
      return intVal;
    } else {
      throw 'Expected integer value, but was not integer.';
    }
  }
}

@patch
extension DoubleToJSNumber on double {
  @patch
  JSNumber get toJS => _box<JSNumber>(toJSNumber(this));
}

/// [JSBoolean] <-> [bool]
@patch
extension JSBooleanToBool on JSBoolean {
  @patch
  bool get toDart => toDartBool(toExternRef);
}

@patch
extension BoolToJSBoolean on bool {
  @patch
  JSBoolean get toJS => _box<JSBoolean>(toJSBoolean(this));
}

/// [JSString] <-> [String]
@patch
extension JSStringToString on JSString {
  @patch
  String get toDart => js_types.JSStringImpl(toExternRef);
}

@patch
extension StringToJSString on String {
  @patch
  JSString get toJS {
    final t = this;
    WasmExternRef? ref;
    if (t is js_types.JSStringImpl) {
      ref = t.toExternRef;
    } else {
      ref = jsStringFromDartString(this);
    }
    return _box<JSString>(ref);
  }
}
