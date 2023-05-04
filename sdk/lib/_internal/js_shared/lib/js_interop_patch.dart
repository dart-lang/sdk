// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_js_types';
import 'dart:js_util';
import 'dart:typed_data';

/// Helper for working with the [JSAny?] top type in a backend agnostic way.
/// TODO(joshualitt): Remove conflation of null and undefined after migration.
extension NullableUndefineableJSAnyExtension on JSAny? {
  @patch
  bool get isUndefined => this == null || typeofEquals(this, 'undefined');

  @patch
  bool get isNull => this == null || JS('bool', '# === null', this);
}

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart => this;
}

extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => allowInterop(this);
}

/// [JSExportedDartObject] <-> [Object]
extension JSExportedDartObjectToObject on JSExportedDartObject {
  @patch
  Object get toDart => this;
}

extension ObjectToJSExportedDartObject on Object {
  @patch
  JSExportedDartObject get toJS => this;
}

/// [JSPromise] -> [Future<JSAny?>].
extension JSPromiseToFuture on JSPromise {
  @patch
  Future<JSAny?> get toDart => promiseToFuture<JSAny?>(this);
}

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer get toDart => this;
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  JSArrayBuffer get toJS => this;
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => this;
}

extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS => this;
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => this;
}

extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS => this;
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => this;
}

extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS => this;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart => this;
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS => this;
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => this;
}

extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS => this;
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => this;
}

extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS => this;
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => this;
}

extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS => this;
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => this;
}

extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS => this;
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart => this;
}

extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS => this;
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart => this;
}

extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS => this;
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> get toDart => this as List<JSAny?>;
}

extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray get toJS => this;
}

/// [JSNumber] <-> [double]
extension JSNumberToDouble on JSNumber {
  @patch
  double get toDart => this;
}

extension DoubleToJSNumber on double {
  @patch
  JSNumber get toJS => this;
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  @patch
  bool get toDart => this;
}

extension BoolToJSBoolean on bool {
  @patch
  JSBoolean get toJS => this;
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  @patch
  String get toDart => this;
}

extension StringToJSString on String {
  @patch
  JSString get toJS => this;
}
