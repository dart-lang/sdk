// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:_wasm';
import 'dart:async' show Completer;
import 'dart:js_interop';
import 'dart:js_util' show NullRejectionException;
import 'dart:typed_data';

/// Some helpers for working with JS types internally. If we implement the JS
/// types as inline classes then these should go away.
/// TODO(joshualitt): Find a way to get rid of the explicit casts.
T _box<T>(WasmExternRef? ref) => JSValue(ref) as T;

/// Helper for working with the [JSAny?] top type in a backend agnostic way.
extension NullableUndefineableJSAnyExtension on JSAny? {
  // TODO(joshualitt): To support incremental migration of existing users to
  // reified `JSUndefined` and `JSNull`, we have to handle the case where
  // `this == null`. However, after migration we can remove these checks.
  @patch
  bool get isUndefined => this == null || isJSUndefined(this?.toExternRef);

  @patch
  bool get isNull => this == null || this!.toExternRef.isNull;
}

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart => unwrapJSWrappedDartFunction(toExternRef);
}

extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => throw UnimplementedError();
}

/// [JSExportedDartObject], [JSOpaqueDartObject] <-> [Object]
extension JSExportedDartObjectToObject on JSExportedDartObject {
  @patch
  Object get toDart => jsObjectToDartObject(toExternRef);
}

extension ObjectToJSExportedDartObject on Object {
  @patch
  JSExportedDartObject get toJS =>
      _box<JSExportedDartObject>(jsObjectFromDartObject(this));
}

/// [JSPromise] -> [Future<JSAny?>].
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
        return completer.completeError(NullRejectionException(false));
      }
      return completer.completeError(e);
    }.toJS;
    promiseThen(toExternRef, success.toExternRef, error.toExternRef);
    return completer.future;
  }
}

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer get toDart => toDartByteBuffer(toExternRef);
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  JSArrayBuffer get toJS =>
      _box<JSArrayBuffer>(jsArrayBufferFromDartByteBuffer(this));
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => toDartByteData(toExternRef);
}

extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS => _box<JSDataView>(
      jsDataViewFromDartByteData(this, lengthInBytes.toDouble()));
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => toDartInt8List(toExternRef);
}

extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS => _box<JSInt8Array>(jsInt8ArrayFromDartInt8List(this));
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => toDartUint8List(toExternRef);
}

extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS =>
      _box<JSUint8Array>(jsUint8ArrayFromDartUint8List(this));
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart => toDartUint8ClampedList(toExternRef);
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS => _box<JSUint8ClampedArray>(
      jsUint8ClampedArrayFromDartUint8ClampedList(this));
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => toDartInt16List(toExternRef);
}

extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS =>
      _box<JSInt16Array>(jsInt16ArrayFromDartInt16List(this));
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => toDartUint16List(toExternRef);
}

extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS =>
      _box<JSUint16Array>(jsUint16ArrayFromDartUint16List(this));
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => toDartInt32List(toExternRef);
}

extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS =>
      _box<JSInt32Array>(jsInt32ArrayFromDartInt32List(this));
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => toDartUint32List(toExternRef);
}

extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS =>
      _box<JSUint32Array>(jsUint32ArrayFromDartUint32List(this));
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart => toDartFloat32List(toExternRef);
}

extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS =>
      _box<JSFloat32Array>(jsFloat32ArrayFromDartFloat32List(this));
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart => toDartFloat64List(toExternRef);
}

extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS =>
      _box<JSFloat64Array>(jsFloat64ArrayFromDartFloat64List(this));
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> get toDart => toDartListJSAny(toExternRef);
}

extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray get toJS => toJSArray(this);
}

/// [JSNumber] <-> [double]
extension JSNumberToDouble on JSNumber {
  @patch
  double get toDart => toDartNumber(toExternRef);
}

extension DoubleToJSNumber on double {
  @patch
  JSNumber get toJS => _box<JSNumber>(toJSNumber(this));
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  @patch
  bool get toDart => toDartBool(toExternRef);
}

extension BoolToJSBoolean on bool {
  @patch
  JSBoolean get toJS => _box<JSBoolean>(toJSBoolean(this));
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  @patch
  String get toDart => jsStringToDartString(toExternRef);
}

extension StringToJSString on String {
  @patch
  JSString get toJS => _box<JSString>(jsStringFromDartString(this));
}
