// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' as foreign_helper;
import 'dart:_internal' show patch;
import 'dart:_js_types';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

@patch
@pragma('dart2js:prefer-inline')
JSObject get globalJSObject => js_util.globalThis as JSObject;

/// Helper for working with the [JSAny?] top type in a backend agnostic way.
/// TODO(joshualitt): Remove conflation of null and undefined after migration.
extension NullableUndefineableJSAnyExtension on JSAny? {
  @patch
  @pragma('dart2js:prefer-inline')
  bool get isUndefined =>
      this == null || js_util.typeofEquals(this, 'undefined');

  @patch
  @pragma('dart2js:prefer-inline')
  bool get isNull =>
      this == null || foreign_helper.JS('bool', '# === null', this);

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean typeofEquals(JSString typeString) =>
      foreign_helper.JS('bool', 'typeof # === #', this, typeString);

  @patch
  @pragma('dart2js:prefer-inline')
  Object? dartify() => js_util.dartify(this);
}

/// Utility extensions for [Object?].
extension NullableObjectUtilExtension on Object? {
  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? jsify() => js_util.jsify(this) as JSAny?;
}

/// Utility extensions for [JSObject].
extension JSObjectUtilExtension on JSObject {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean instanceof(JSFunction constructor) =>
      foreign_helper.JS('bool', '# instanceof #', this, constructor);
}

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  @pragma('dart2js:prefer-inline')
  Function get toDart => this as Function;
}

extension FunctionToJSExportedDartFunction on Function {
  @patch
  @pragma('dart2js:prefer-inline')
  JSExportedDartFunction get toJS =>
      js_util.allowInterop(this) as JSExportedDartFunction;
}

/// [JSExportedDartObject] <-> [Object]
extension JSExportedDartObjectToObject on JSExportedDartObject {
  @patch
  @pragma('dart2js:prefer-inline')
  Object get toDart => this;
}

extension ObjectToJSExportedDartObject on Object {
  @patch
  @pragma('dart2js:prefer-inline')
  JSExportedDartObject get toJS => this as JSExportedDartObject;
}

/// [JSPromise] -> [Future<JSAny?>].
extension JSPromiseToFuture on JSPromise {
  @patch
  @pragma('dart2js:prefer-inline')
  Future<JSAny?> get toDart => js_util.promiseToFuture<JSAny?>(this);
}

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteBuffer get toDart => this as ByteBuffer;
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArrayBuffer get toJS => this as JSArrayBuffer;
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteData get toDart => this as ByteData;
}

extension ByteDataToJSDataView on ByteData {
  @patch
  @pragma('dart2js:prefer-inline')
  JSDataView get toJS => this as JSDataView;
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int8List get toDart => this as Int8List;
}

extension Int8ListToJSInt8Array on Int8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt8Array get toJS => this as JSInt8Array;
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8List get toDart => this as Uint8List;
}

extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8Array get toJS => this as JSUint8Array;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8ClampedList get toDart => this as Uint8ClampedList;
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8ClampedArray get toJS => this as JSUint8ClampedArray;
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int16List get toDart => this as Int16List;
}

extension Int16ListToJSInt16Array on Int16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt16Array get toJS => this as JSInt16Array;
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint16List get toDart => this as Uint16List;
}

extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint16Array get toJS => this as JSUint16Array;
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int32List get toDart => this as Int32List;
}

extension Int32ListToJSInt32Array on Int32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt32Array get toJS => this as JSInt32Array;
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint32List get toDart => this as Uint32List;
}

extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint32Array get toJS => this as JSUint32Array;
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float32List get toDart => this as Float32List;
}

extension Float32ListToJSFloat32Array on Float32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat32Array get toJS => this as JSFloat32Array;
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float64List get toDart => this as Float64List;
}

extension Float64ListToJSFloat64Array on Float64List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat64Array get toJS => this as JSFloat64Array;
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  @patch
  @pragma('dart2js:prefer-inline')
  List<JSAny?> get toDart => this as List<JSAny?>;
}

extension ListToJSArray on List<JSAny?> {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArray get toJS => this as JSArray;
}

/// [JSNumber] <-> [double]
extension JSNumberToDouble on JSNumber {
  @patch
  @pragma('dart2js:prefer-inline')
  double get toDart => this as double;
}

extension DoubleToJSNumber on double {
  @patch
  @pragma('dart2js:prefer-inline')
  JSNumber get toJS => this as JSNumber;
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  @patch
  @pragma('dart2js:prefer-inline')
  bool get toDart => this as bool;
}

extension BoolToJSBoolean on bool {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean get toJS => this as JSBoolean;
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  @patch
  @pragma('dart2js:prefer-inline')
  String get toDart => this as String;
}

extension StringToJSString on String {
  @patch
  @pragma('dart2js:prefer-inline')
  JSString get toJS => this as JSString;
}
