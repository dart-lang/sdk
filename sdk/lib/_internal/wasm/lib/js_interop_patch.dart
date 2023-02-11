// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:typed_data';
import 'dart:wasm';

/// Some helpers for working with JS types internally. If we implement the JS
/// types as inline classes then these should go away.
/// TODO(joshualitt): Find a way to get rid of the explicit casts.
WasmExternRef _ref<T>(T o) => (o as JSValue).toExternRef();
T _box<T>(WasmExternRef? ref) => JSValue.box(ref) as T;

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart =>
      unwrapJSWrappedDartFunction(_ref<JSExportedDartFunction>(this));
}

extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => throw UnimplementedError();
}

/// [JSExportedDartObject], [JSOpaqueDartObject] <-> [Object]
extension JSExportedDartObjectToObject on JSExportedDartObject {
  @patch
  Object get toDart => jsObjectToDartObject(_ref<JSExportedDartObject>(this));
}

extension ObjectToJSExportedDartObject on Object {
  @patch
  JSExportedDartObject get toJS =>
      _box<JSExportedDartObject>(jsObjectFromDartObject(this));
}

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer get toDart => toDartByteBuffer(_ref<JSArrayBuffer>(this));
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  JSArrayBuffer get toJS =>
      _box<JSArrayBuffer>(jsArrayBufferFromDartByteBuffer(this));
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => toDartByteData(_ref<JSDataView>(this));
}

extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS => _box<JSDataView>(
      jsDataViewFromDartByteData(this, lengthInBytes.toDouble()));
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => toDartInt8List(_ref<JSInt8Array>(this));
}

extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS => _box<JSInt8Array>(jsInt8ArrayFromDartInt8List(this));
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => toDartUint8List(_ref<JSUint8Array>(this));
}

extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS =>
      _box<JSUint8Array>(jsUint8ArrayFromDartUint8List(this));
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart =>
      toDartUint8ClampedList(_ref<JSUint8ClampedArray>(this));
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS => _box<JSUint8ClampedArray>(
      jsUint8ClampedArrayFromDartUint8ClampedList(this));
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => toDartInt16List(_ref<JSInt16Array>(this));
}

extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS =>
      _box<JSInt16Array>(jsInt16ArrayFromDartInt16List(this));
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => toDartUint16List(_ref<JSUint16Array>(this));
}

extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS =>
      _box<JSUint16Array>(jsUint16ArrayFromDartUint16List(this));
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => toDartInt32List(_ref<JSInt32Array>(this));
}

extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS =>
      _box<JSInt32Array>(jsInt32ArrayFromDartInt32List(this));
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => toDartUint32List(_ref<JSUint32Array>(this));
}

extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS =>
      _box<JSUint32Array>(jsUint32ArrayFromDartUint32List(this));
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart => toDartFloat32List(_ref<JSFloat32Array>(this));
}

extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS =>
      _box<JSFloat32Array>(jsFloat32ArrayFromDartFloat32List(this));
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart => toDartFloat64List(_ref<JSFloat64Array>(this));
}

extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS =>
      _box<JSFloat64Array>(jsFloat64ArrayFromDartFloat64List(this));
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> get toDart => toDartListJSAny(_ref<JSArray>(this));
}

extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray get toJS => toJSArray(this);
}

/// [JSNumber] <-> [double]
extension JSNumberToDouble on JSNumber {
  @patch
  double get toDart => toDartNumber(_ref<JSNumber>(this));
}

extension DoubleToJSNumber on double {
  @patch
  JSNumber get toJS => _box<JSNumber>(toJSNumber(this));
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  @patch
  bool get toDart => toDartBool(_ref<JSBoolean>(this));
}

extension BoolToJSBoolean on bool {
  @patch
  JSBoolean get toJS => _box<JSBoolean>(toJSBoolean(this));
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  @patch
  String get toDart => jsStringToDartString(_ref<JSString>(this));
}

extension StringToJSString on String {
  @patch
  JSString get toJS => _box<JSString>(jsStringFromDartString(this));
}
