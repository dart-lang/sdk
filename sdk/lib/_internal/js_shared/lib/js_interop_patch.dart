// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_types';
import 'dart:js';
import 'dart:typed_data';

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  T toDart<T extends Function>() => this as T;
}

extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction toJS<T extends Function>() =>
      allowInterop<T>(this as T);
}

/// [JSExportedDartObject] <-> [Object]
extension JSExportedDartObjectToObject on JSExportedDartObject {
  @patch
  T toDart<T>() => this as T;
}

extension ObjectToJSExportedDartObject on Object {
  @patch
  JSExportedDartObject toJS() => this;
}

/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer toDart() => this;
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  JSArrayBuffer toJS() => this;
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData toDart() => this;
}

extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView toJS() => this;
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List toDart() => this;
}

extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array toJS() => this;
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List toDart() => this;
}

extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array toJS() => this;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList toDart() => this;
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray toJS() => this;
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List toDart() => this;
}

extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array toJS() => this;
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List toDart() => this;
}

extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array toJS() => this;
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List toDart() => this;
}

extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array toJS() => this;
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List toDart() => this;
}

extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array toJS() => this;
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List toDart() => this;
}

extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array toJS() => this;
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List toDart() => this;
}

extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array toJS() => this;
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> toDart() => this as List<JSAny?>;
}

extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray toJS() => this;
}

/// [JSNumber] <-> [double]
extension JSNumberToDouble on JSNumber {
  @patch
  double toDart() => this;
}

extension DoubleToJSNumber on double {
  @patch
  JSNumber toJS() => this;
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  @patch
  bool toDart() => this;
}

extension BoolToJSBoolean on bool {
  @patch
  JSBoolean toJS() => this;
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  @patch
  String toDart() => this;
}

extension StringToJSString on String {
  @patch
  JSString toJS() => this;
}
