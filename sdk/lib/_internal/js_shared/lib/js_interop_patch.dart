// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' as foreign_helper;
import 'dart:_interceptors' show JavaScriptObject;
import 'dart:_internal' show patch;
import 'dart:_js_types';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

@patch
@pragma('dart2js:prefer-inline')
JSObject get globalJSObject => js_util.globalThis as JSObject;

/// Helper for working with the [JSAny?] top type in a backend agnostic way.
/// TODO(joshualitt): Remove conflation of null and undefined after migration.
@patch
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
@patch
extension NullableObjectUtilExtension on Object? {
  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? jsify() => js_util.jsify(this) as JSAny?;
}

/// Utility extensions for [JSObject].
@patch
extension JSObjectUtilExtension on JSObject {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean instanceof(JSFunction constructor) =>
      foreign_helper.JS('bool', '# instanceof #', this, constructor);
}

/// [JSExportedDartFunction] <-> [Function]
@patch
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  // TODO(srujzs): We should unwrap rather than allow arbitrary JS functions
  // to be called in Dart.
  @patch
  @pragma('dart2js:prefer-inline')
  Function get toDart => this as Function;
}

@patch
extension FunctionToJSExportedDartFunction on Function {
  @patch
  @pragma('dart2js:prefer-inline')
  JSExportedDartFunction get toJS =>
      js_util.allowInterop(this) as JSExportedDartFunction;
}

const _jsBoxedDartObjectProperty = "'_\$jsBoxedDartObject'";

/// [JSBoxedDartObject] <-> [Object]
@patch
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  @patch
  @pragma('dart2js:prefer-inline')
  Object get toDart {
    if (this is JavaScriptObject) {
      final val = foreign_helper.JS(
          'Object|Null', '#[$_jsBoxedDartObjectProperty]', this);
      if (val == null) {
        throw 'Expected a wrapped Dart object, but got a JS object instead.';
      }
      return val as Object;
    }
    // TODO(srujzs): Currently we have to still support Dart objects being
    // returned from JS until `Object.toJS` is removed. Once that is removed,
    // and the runtime type of this type is changed, we can get rid of this and
    // the type check above.
    return this;
  }
}

@patch
extension ObjectToJSBoxedDartObject on Object {
  // TODO(srujzs): Remove.
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoxedDartObject get toJS => this as JSBoxedDartObject;

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoxedDartObject get toJSBox {
    if (this is JavaScriptObject) {
      throw 'Attempting to box non-Dart object.';
    }
    final box =
        foreign_helper.JS('=Object', '{$_jsBoxedDartObjectProperty: #}', this);
    return box as JSBoxedDartObject;
  }
}

/// [JSPromise] -> [Future<JSAny?>].
@patch
extension JSPromiseToFuture on JSPromise {
  @patch
  @pragma('dart2js:prefer-inline')
  Future<JSAny?> get toDart => js_util.promiseToFuture<JSAny?>(this);
}

/// [JSArrayBuffer] <-> [ByteBuffer]
@patch
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteBuffer get toDart => this as ByteBuffer;
}

@patch
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArrayBuffer get toJS => this as JSArrayBuffer;
}

/// [JSDataView] <-> [ByteData]
@patch
extension JSDataViewToByteData on JSDataView {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteData get toDart => this as ByteData;
}

@patch
extension ByteDataToJSDataView on ByteData {
  @patch
  @pragma('dart2js:prefer-inline')
  JSDataView get toJS => this as JSDataView;
}

/// [JSInt8Array] <-> [Int8List]
@patch
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int8List get toDart => this as Int8List;
}

@patch
extension Int8ListToJSInt8Array on Int8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt8Array get toJS => this as JSInt8Array;
}

/// [JSUint8Array] <-> [Uint8List]
@patch
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8List get toDart => this as Uint8List;
}

@patch
extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8Array get toJS => this as JSUint8Array;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
@patch
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8ClampedList get toDart => this as Uint8ClampedList;
}

@patch
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8ClampedArray get toJS => this as JSUint8ClampedArray;
}

/// [JSInt16Array] <-> [Int16List]
@patch
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int16List get toDart => this as Int16List;
}

@patch
extension Int16ListToJSInt16Array on Int16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt16Array get toJS => this as JSInt16Array;
}

/// [JSUint16Array] <-> [Uint16List]
@patch
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint16List get toDart => this as Uint16List;
}

@patch
extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint16Array get toJS => this as JSUint16Array;
}

/// [JSInt32Array] <-> [Int32List]
@patch
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int32List get toDart => this as Int32List;
}

@patch
extension Int32ListToJSInt32Array on Int32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt32Array get toJS => this as JSInt32Array;
}

/// [JSUint32Array] <-> [Uint32List]
@patch
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint32List get toDart => this as Uint32List;
}

@patch
extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint32Array get toJS => this as JSUint32Array;
}

/// [JSFloat32Array] <-> [Float32List]
@patch
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float32List get toDart => this as Float32List;
}

@patch
extension Float32ListToJSFloat32Array on Float32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat32Array get toJS => this as JSFloat32Array;
}

/// [JSFloat64Array] <-> [Float64List]
@patch
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float64List get toDart => this as Float64List;
}

@patch
extension Float64ListToJSFloat64Array on Float64List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat64Array get toJS => this as JSFloat64Array;
}

/// [JSArray] <-> [List]
@patch
extension JSArrayToList on JSArray {
  @patch
  @pragma('dart2js:prefer-inline')
  List<JSAny?> get toDart => this as List<JSAny?>;
}

@patch
extension ListToJSArray on List<JSAny?> {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArray get toJS => this as JSArray;
}

/// [JSNumber] -> [double] or [int].
@patch
extension JSNumberToNumber on JSNumber {
  // TODO(srujzs): Remove.
  @patch
  @pragma('dart2js:prefer-inline')
  double get toDart => this as double;

  @patch
  @pragma('dart2js:prefer-inline')
  double get toDartDouble => this as double;

  @patch
  @pragma('dart2js:prefer-inline')
  int get toDartInt => this as int;
}

/// [double] -> [JSNumber].
@patch
extension DoubleToJSNumber on double {
  @patch
  @pragma('dart2js:prefer-inline')
  JSNumber get toJS => this as JSNumber;
}

/// [JSBoolean] <-> [bool]
@patch
extension JSBooleanToBool on JSBoolean {
  @patch
  @pragma('dart2js:prefer-inline')
  bool get toDart => this as bool;
}

@patch
extension BoolToJSBoolean on bool {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean get toJS => this as JSBoolean;
}

/// [JSString] <-> [String]
@patch
extension JSStringToString on JSString {
  @patch
  @pragma('dart2js:prefer-inline')
  String get toDart => this as String;
}

@patch
extension StringToJSString on String {
  @patch
  @pragma('dart2js:prefer-inline')
  JSString get toJS => this as JSString;
}
