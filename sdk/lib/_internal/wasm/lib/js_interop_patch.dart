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

// This should match the global context we use in our static interop lowerings.
@patch
JSObject get globalContext => js_util.globalThis as JSObject;

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
  Function get toDart {
    final ref = toExternRef;
    if (!js_helper.isJSWrappedDartFunction(ref)) {
      throw 'Expected JS wrapped function, but got type '
          '${js_helper.typeof(ref)}.';
    }
    return unwrapJSWrappedDartFunction(ref);
  }
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
  ByteBuffer get toDart => js_types.JSArrayBufferImpl(toExternRef);
}

@patch
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  // Note: While this general style of 'test for JS backed subtype' is quite
  // common, we still specialize each case to avoid a genric `is` check.
  @patch
  JSArrayBuffer get toJS {
    final t = this;
    return _box<JSArrayBuffer>(t is js_types.JSArrayBufferImpl
        ? t.toExternRef
        : jsArrayBufferFromDartByteBuffer(t));
  }
}

/// [JSDataView] <-> [ByteData]
@patch
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => js_types.JSDataViewImpl(toExternRef);
}

@patch
extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS {
    final t = this;
    return _box<JSDataView>(t is js_types.JSDataViewImpl
        ? t.toExternRef
        : jsDataViewFromDartByteData(t, lengthInBytes.toDouble()));
  }
}

/// [JSInt8Array] <-> [Int8List]
@patch
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => js_types.JSInt8ArrayImpl(toExternRef);
}

@patch
extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS {
    final t = this;
    return _box<JSInt8Array>(t is js_types.JSInt8ArrayImpl
        ? t.toExternRef
        : jsInt8ArrayFromDartInt8List(t));
  }
}

/// [JSUint8Array] <-> [Uint8List]
@patch
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => js_types.JSUint8ArrayImpl(toExternRef);
}

@patch
extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS {
    final t = this;
    return _box<JSUint8Array>(t is js_types.JSUint8ArrayImpl
        ? t.toExternRef
        : jsUint8ArrayFromDartUint8List(t));
  }
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
@patch
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart => js_types.JSUint8ClampedArrayImpl(toExternRef);
}

@patch
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS {
    final t = this;
    return _box<JSUint8ClampedArray>(t is js_types.JSUint8ClampedArrayImpl
        ? t.toExternRef
        : jsUint8ClampedArrayFromDartUint8ClampedList(t));
  }
}

/// [JSInt16Array] <-> [Int16List]
@patch
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => js_types.JSInt16ArrayImpl(toExternRef);
}

@patch
extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS {
    final t = this;
    return _box<JSInt16Array>(t is js_types.JSInt16ArrayImpl
        ? t.toExternRef
        : jsInt16ArrayFromDartInt16List(t));
  }
}

/// [JSUint16Array] <-> [Uint16List]
@patch
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => js_types.JSUint16ArrayImpl(toExternRef);
}

@patch
extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS {
    final t = this;
    return _box<JSUint16Array>(t is js_types.JSUint16ArrayImpl
        ? t.toExternRef
        : jsUint16ArrayFromDartUint16List(t));
  }
}

/// [JSInt32Array] <-> [Int32List]
@patch
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => js_types.JSInt32ArrayImpl(toExternRef);
}

@patch
extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS {
    final t = this;
    return _box<JSInt32Array>(t is js_types.JSInt32ArrayImpl
        ? t.toExternRef
        : jsInt32ArrayFromDartInt32List(t));
  }
}

/// [JSUint32Array] <-> [Uint32List]
@patch
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => js_types.JSUint32ArrayImpl(toExternRef);
}

@patch
extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS {
    final t = this;
    return _box<JSUint32Array>(t is js_types.JSUint32ArrayImpl
        ? t.toExternRef
        : jsUint32ArrayFromDartUint32List(t));
  }
}

/// [JSFloat32Array] <-> [Float32List]
@patch
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart => js_types.JSFloat32ArrayImpl(toExternRef);
}

@patch
extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS {
    final t = this;
    return _box<JSFloat32Array>(t is js_types.JSFloat32ArrayImpl
        ? t.toExternRef
        : jsFloat32ArrayFromDartFloat32List(t));
  }
}

/// [JSFloat64Array] <-> [Float64List]
@patch
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart => js_types.JSFloat64ArrayImpl(toExternRef);
}

@patch
extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS {
    final t = this;
    return _box<JSFloat64Array>(t is js_types.JSFloat64ArrayImpl
        ? t.toExternRef
        : jsFloat64ArrayFromDartFloat64List(t));
  }
}

/// [JSArray] <-> [List]
@patch
extension JSArrayToList on JSArray {
  @patch
  List<JSAny?> get toDart => js_types.JSArrayImpl(toExternRef);
}

@patch
extension ListToJSArray on List<JSAny?> {
  @patch
  JSArray get toJS {
    final t = this;
    return t is js_types.JSArrayImpl
        ? JSValue.boxT<JSArray>(t.toExternRef)
        : toJSArray(this);
  }
}

/// [JSNumber] -> [double] or [int].
@patch
extension JSNumberToNumber on JSNumber {
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
    return _box<JSString>(
        t is js_types.JSStringImpl ? t.toExternRef : jsStringFromDartString(t));
  }
}
