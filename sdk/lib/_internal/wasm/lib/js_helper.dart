// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpers for working with JS.
library dart._js_helper;

import 'dart:_internal';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:wasm';

part 'regexp_helper.dart';

/// [JSValue] is the root of the JS interop object hierarchy.
class JSValue {
  final WasmExternRef _ref;

  JSValue(this._ref);

  // Currently we always explictly box JS ref's in [JSValue] objects. In the
  // future, we will want to leave these values unboxed when possible, even when
  // they are nullable.
  static JSValue? box(WasmExternRef? ref) =>
      isDartNull(ref) ? null : JSValue(ref!);

  @override
  bool operator ==(Object that) =>
      that is JSValue && areEqualInJS(_ref, that._ref);

  @override
  String toString() => stringify(_ref);

  // Overrides to avoid using [ObjectToJS].
  WasmExternRef toExternRef() => _ref;
  JSValue toJS() => this;
}

extension DoubleToJS on double {
  WasmExternRef toExternRef() => toJSNumber(this)!;
  JSValue toJS() => JSValue(toExternRef());
}

extension StringToJS on String {
  WasmExternRef toExternRef() => jsStringFromDartString(this)!;
  JSValue toJS() => JSValue(toExternRef());
}

extension ListOfObjectToJS on List<Object?> {
  WasmExternRef toExternRef() => jsArrayFromDartList(this)!;
  JSValue toJS() => JSValue(toExternRef());
}

extension ObjectToJS on Object {
  WasmExternRef toExternRef() => jsObjectFromDartObject(this);
  JSValue toJS() => JSValue(toExternRef());
}

// For now both `null` and `undefined` in JS map to `null` in Dart.
bool isDartNull(WasmExternRef? ref) => ref == null || isJSUndefined(ref);

/// A [JSArray] is a wrapper for a native JSArray.
class JSArray extends JSValue {
  JSArray(WasmExternRef ref) : super(ref);

  static JSArray? box(WasmExternRef? ref) =>
      isDartNull(ref) ? null : JSArray(ref!);

  JSValue? pop() => JSValue.box(
      callMethodVarArgsRaw(_ref, 'pop'.toExternRef(), [].toExternRef()));
  JSValue? operator [](int index) =>
      JSValue.box(getPropertyRaw(_ref, intToJSNumber(index)));
  void operator []=(int index, JSValue? value) =>
      setPropertyRaw(_ref, intToJSNumber(index), value?.toExternRef());
  int get length =>
      toDartNumber(getPropertyRaw(_ref, 'length'.toExternRef())!).floor();
}

/// A [JSObject] is a wrapper for any JS object literal.
class JSObject extends JSValue {
  JSObject(WasmExternRef ref) : super(ref);

  static JSObject? box(WasmExternRef? ref) =>
      isDartNull(ref) ? null : JSObject(ref!);

  JSValue? operator [](String key) =>
      JSValue.box(getPropertyRaw(_ref, key.toExternRef()));
  void operator []=(String key, JSValue? value) =>
      setPropertyRaw(_ref, key.toExternRef(), value?.toExternRef());
}

class JSArrayIteratorAdapter<T> extends Iterator<T> {
  final JSArray array;
  int index = -1;

  JSArrayIteratorAdapter(this.array);

  @override
  bool moveNext() {
    index++;
    if (index > array.length) {
      throw 'Iterator out of bounds';
    }
    return index < array.length;
  }

  @override
  T get current => dartifyRaw(array[index]?.toExternRef()) as T;
}

/// [JSArrayIterableAdapter] lazily adapts a [JSArray] to Dart's [Iterable]
/// interface.
class JSArrayIterableAdapter<T> extends EfficientLengthIterable<T> {
  final JSArray array;

  JSArrayIterableAdapter(this.array);

  @override
  Iterator<T> get iterator => JSArrayIteratorAdapter<T>(array);

  @override
  int get length => array.length;
}

// Convert to double to avoid converting to [BigInt] in the case of int64.
WasmExternRef intToJSNumber(int i) => toJSNumber(i.toDouble())!;

WasmExternRef? getConstructorString(String constructor) =>
    getPropertyRaw(globalThisRaw(), constructor.toExternRef());

Object jsObjectToDartObject(WasmExternRef? ref) =>
    unsafeCastOpaque<Object>(ref.internalize());

WasmExternRef jsObjectFromDartObject(Object object) =>
    unsafeCastOpaque<WasmAnyRef>(object).externalize();

@pragma("wasm:import", "dart2wasm.isJSUndefined")
external bool isJSUndefined(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSBoolean")
external bool isJSBoolean(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSNumber")
external bool isJSNumber(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSBigInt")
external bool isJSBigInt(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSString")
external bool isJSString(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSSymbol")
external bool isJSSymbol(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSFunction")
external bool isJSFunction(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSInt8Array")
external bool isJSInt8Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSUint8Array")
external bool isJSUint8Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSUint8ClampedArray")
external bool isJSUint8ClampedArray(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSInt16Array")
external bool isJSInt16Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSUint16Array")
external bool isJSUint16Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSInt32Array")
external bool isJSInt32Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSUint32Array")
external bool isJSUint32Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSFloat32Array")
external bool isJSFloat32Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSFloat64Array")
external bool isJSFloat64Array(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSArrayBuffer")
external bool isJSArrayBuffer(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSDataView")
external bool isJSDataView(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.isJSArray")
external bool isJSArray(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSWrappedDartFunction")
external bool isJSWrappedDartFunction(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSObject")
external bool isJSObject(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSSimpleObject")
external bool isJSSimpleObject(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.isJSRegExp")
external bool isJSRegExp(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.areEqualInJS")
external bool areEqualInJS(WasmExternRef? l, WasmExternRef? r);

// The JS runtime will run helpful conversion routines between refs and bool /
// double. In the longer term hopefully we can find a way to avoid the round
// trip.
@pragma("wasm:import", "dart2wasm.roundtrip")
external double toDartNumber(WasmExternRef? ref);

@pragma("wasm:import", "dart2wasm.roundtrip")
external WasmExternRef? toJSNumber(double d);

@pragma("wasm:import", "dart2wasm.roundtrip")
external bool toDartBool(WasmExternRef? ref);

@pragma("wasm:import", "dart2wasm.toJSBoolean")
external WasmExternRef? toJSBoolean(bool b);

@pragma("wasm:import", "dart2wasm.objectLength")
external double objectLength(WasmExternRef? ref);

@pragma("wasm:import", "dart2wasm.objectReadIndex")
external WasmExternRef? objectReadIndex(WasmExternRef? ref, int index);

@pragma("wasm:import", "dart2wasm.unwrapJSWrappedDartFunction")
external Object? unwrapJSWrappedDartFunction(WasmExternRef? f);

@pragma("wasm:import", "dart2wasm.int8ArrayFromDartInt8List")
external WasmExternRef? jsInt8ArrayFromDartInt8List(Int8List list);

@pragma("wasm:import", "dart2wasm.uint8ArrayFromDartUint8List")
external WasmExternRef? jsUint8ArrayFromDartUint8List(Uint8List list);

@pragma("wasm:import", "dart2wasm.uint8ClampedArrayFromDartUint8ClampedList")
external WasmExternRef? jsUint8ClampedArrayFromDartUint8ClampedList(
    Uint8ClampedList list);

@pragma("wasm:import", "dart2wasm.int16ArrayFromDartInt16List")
external WasmExternRef? jsInt16ArrayFromDartInt16List(Int16List list);

@pragma("wasm:import", "dart2wasm.uint16ArrayFromDartUint16List")
external WasmExternRef? jsUint16ArrayFromDartUint16List(Uint16List list);

@pragma("wasm:import", "dart2wasm.int32ArrayFromDartInt32List")
external WasmExternRef? jsInt32ArrayFromDartInt32List(Int32List list);

@pragma("wasm:import", "dart2wasm.uint32ArrayFromDartUint32List")
external WasmExternRef? jsUint32ArrayFromDartUint32List(Uint32List list);

@pragma("wasm:import", "dart2wasm.float32ArrayFromDartFloat32List")
external WasmExternRef? jsFloat32ArrayFromDartFloat32List(Float32List list);

@pragma("wasm:import", "dart2wasm.float64ArrayFromDartFloat64List")
external WasmExternRef? jsFloat64ArrayFromDartFloat64List(Float64List list);

@pragma("wasm:import", "dart2wasm.dataViewFromDartByteData")
external WasmExternRef? jsDataViewFromDartByteData(
    ByteData data, double byteLength);

@pragma("wasm:import", "dart2wasm.arrayFromDartList")
external WasmExternRef? jsArrayFromDartList(List<Object?> list);

@pragma("wasm:import", "dart2wasm.stringFromDartString")
external WasmExternRef? jsStringFromDartString(String string);

@pragma("wasm:import", "dart2wasm.stringToDartString")
external String jsStringToDartString(WasmExternRef? string);

@pragma("wasm:import", "dart2wasm.eval")
external void evalRaw(WasmExternRef? code);

@pragma("wasm:import", "dart2wasm.newObject")
external WasmExternRef? newObjectRaw();

@pragma("wasm:import", "dart2wasm.newArray")
external WasmExternRef? newArrayRaw();

@pragma("wasm:import", "dart2wasm.globalThis")
external WasmExternRef? globalThisRaw();

@pragma("wasm:import", "dart2wasm.callConstructorVarArgs")
external WasmExternRef? callConstructorVarArgsRaw(
    WasmExternRef? o, WasmExternRef? args);

@pragma("wasm:import", "dart2wasm.safeCallConstructorVarArgs")
external WasmExternRef? safeCallConstructorVarArgsRaw(
    WasmExternRef? o, WasmExternRef? args);

@pragma("wasm:import", "dart2wasm.hasProperty")
external bool hasPropertyRaw(WasmExternRef? o, WasmExternRef? name);

@pragma("wasm:import", "dart2wasm.getProperty")
external WasmExternRef? getPropertyRaw(WasmExternRef? o, WasmExternRef? name);

@pragma("wasm:import", "dart2wasm.setProperty")
external WasmExternRef? setPropertyRaw(
    WasmExternRef? o, WasmExternRef? name, WasmExternRef? value);

@pragma("wasm:import", "dart2wasm.callMethodVarArgs")
external WasmExternRef? callMethodVarArgsRaw(
    WasmExternRef? o, WasmExternRef? method, WasmExternRef? args);

@pragma("wasm:import", "dart2wasm.stringify")
external String stringify(WasmExternRef? object);

@pragma("wasm:import", "dart2wasm.objectKeys")
external WasmExternRef? objectKeysRaw(WasmExternRef? o);

@pragma("wasm:import", "dart2wasm.promiseThen")
external void promiseThen(WasmExternRef? promise, WasmExternRef? successFunc,
    WasmExternRef? failureFunc);

@pragma("wasm:import", "dart2wasm.instanceofTrampoline")
external bool instanceofRaw(WasmExternRef? object, WasmExternRef? type);

// Currently, `allowInterop` returns a Function type. This is unfortunate for
// Dart2wasm because it means arbitrary Dart functions can flow to JS util
// calls. Our only solutions is to cache every function called with
// `allowInterop` and to replace them with the wrapped variant when they flow
// to JS.
// NOTE: We are not currently replacing functions returned from JS.
Map<Function, JSValue> functionToJSWrapper = {};

WasmExternRef? jsArrayBufferFromDartByteBuffer(ByteBuffer buffer) {
  ByteData byteData = ByteData.view(buffer);
  WasmExternRef? dataView =
      jsDataViewFromDartByteData(byteData, byteData.lengthInBytes.toDouble());
  return getPropertyRaw(dataView, 'buffer'.toExternRef());
}

WasmExternRef? jsifyRaw(Object? object) {
  if (object == null) {
    return null;
  } else if (object is bool) {
    return toJSBoolean(object);
  } else if (object is Function) {
    assert(functionToJSWrapper.containsKey(object),
        'Must call `allowInterop` on functions before they flow to JS');
    return functionToJSWrapper[object]?.toExternRef();
  } else if (object is JSValue) {
    return object.toExternRef();
  } else if (object is String) {
    return jsStringFromDartString(object);
  } else if (object is Int8List) {
    return jsInt8ArrayFromDartInt8List(object);
  } else if (object is Uint8List) {
    return jsUint8ArrayFromDartUint8List(object);
  } else if (object is Uint8ClampedList) {
    return jsUint8ClampedArrayFromDartUint8ClampedList(object);
  } else if (object is Int16List) {
    return jsInt16ArrayFromDartInt16List(object);
  } else if (object is Uint16List) {
    return jsUint16ArrayFromDartUint16List(object);
  } else if (object is Int32List) {
    return jsInt32ArrayFromDartInt32List(object);
  } else if (object is Uint32List) {
    return jsUint32ArrayFromDartUint32List(object);
  } else if (object is Float32List) {
    return jsFloat32ArrayFromDartFloat32List(object);
  } else if (object is Float64List) {
    return jsFloat64ArrayFromDartFloat64List(object);
  } else if (object is ByteBuffer) {
    return jsArrayBufferFromDartByteBuffer(object);
  } else if (object is ByteData) {
    return jsDataViewFromDartByteData(object, object.lengthInBytes.toDouble());
  } else if (object is List<Object?>) {
    return jsArrayFromDartList(object);
  } else if (object is num) {
    return toJSNumber(object.toDouble());
  } else {
    return jsObjectFromDartObject(object);
  }
}

bool isWasmGCStruct(WasmExternRef ref) => ref.internalize().isObject;

/// TODO(joshualitt): We shouldn't need this, but otherwise we seem to get a
/// cast error for certain oddball types(I think undefined, but need to dig
/// deeper).
@pragma("wasm:export", "\$dartifyRaw")
Object? dartifyExported(WasmExternRef? ref) => dartifyRaw(ref);

Object? dartifyRaw(WasmExternRef? ref) {
  if (ref == null) {
    return null;
  } else if (isJSUndefined(ref)) {
    // TODO(joshualitt): Introduce a `JSUndefined` type.
    return null;
  } else if (isJSBoolean(ref)) {
    return toDartBool(ref);
  } else if (isJSNumber(ref)) {
    return toDartNumber(ref);
  } else if (isJSString(ref)) {
    return jsStringToDartString(ref);
  } else if (isJSInt8Array(ref)) {
    return toDartInt8List(ref);
  } else if (isJSUint8Array(ref)) {
    return toDartUint8List(ref);
  } else if (isJSUint8ClampedArray(ref)) {
    return toDartUint8ClampedList(ref);
  } else if (isJSInt16Array(ref)) {
    return toDartInt16List(ref);
  } else if (isJSUint16Array(ref)) {
    return toDartUint16List(ref);
  } else if (isJSInt32Array(ref)) {
    return toDartInt32List(ref);
  } else if (isJSUint32Array(ref)) {
    return toDartUint32List(ref);
  } else if (isJSFloat32Array(ref)) {
    return toDartFloat32List(ref);
  } else if (isJSFloat64Array(ref)) {
    return toDartFloat64List(ref);
  } else if (isJSArrayBuffer(ref)) {
    return toDartByteBuffer(ref);
  } else if (isJSDataView(ref)) {
    return toDartByteData(ref);
  } else if (isJSArray(ref)) {
    return toDartList(ref);
  } else if (isJSWrappedDartFunction(ref)) {
    return unwrapJSWrappedDartFunction(ref);
  } else if (isWasmGCStruct(ref)) {
    return jsObjectToDartObject(ref);
  } else {
    return JSValue(ref);
  }
}

Int8List toDartInt8List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Int8List(size))
        as Int8List;

Uint8List toDartUint8List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Uint8List(size))
        as Uint8List;

Uint8ClampedList toDartUint8ClampedList(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Uint8ClampedList(size))
        as Uint8ClampedList;

Int16List toDartInt16List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Int16List(size))
        as Int16List;

Uint16List toDartUint16List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Uint16List(size))
        as Uint16List;

Int32List toDartInt32List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Int32List(size))
        as Int32List;

Uint32List toDartUint32List(WasmExternRef? ref) =>
    jsIntTypedArrayToDartIntTypedData(ref, (size) => Uint32List(size))
        as Uint32List;

Float32List toDartFloat32List(WasmExternRef? ref) =>
    jsFloatTypedArrayToDartFloatTypedData(ref, (size) => Float32List(size))
        as Float32List;

Float64List toDartFloat64List(WasmExternRef? ref) =>
    jsFloatTypedArrayToDartFloatTypedData(ref, (size) => Float64List(size))
        as Float64List;

ByteBuffer toDartByteBuffer(WasmExternRef? ref) =>
    toDartByteData(callConstructorVarArgsRaw(
            getConstructorString('DataView'), [JSValue.box(ref)].toExternRef()))
        .buffer;

ByteData toDartByteData(WasmExternRef? ref) {
  int length =
      toDartNumber(getPropertyRaw(ref, 'byteLength'.toExternRef())).toInt();
  ByteData data = ByteData(length);
  for (int i = 0; i < length; i++) {
    data.setUint8(
        i,
        toDartNumber(callMethodVarArgsRaw(
                ref, 'getUint8'.toExternRef(), [i].toExternRef()))
            .toInt());
  }
  return data;
}

List<double> jsFloatTypedArrayToDartFloatTypedData(
    WasmExternRef? ref, List<double> makeTypedData(int size)) {
  int length = objectLength(ref).toInt();
  List<double> list = makeTypedData(length);
  for (int i = 0; i < length; i++) {
    list[i] = toDartNumber(objectReadIndex(ref, i));
  }
  return list;
}

List<int> jsIntTypedArrayToDartIntTypedData(
    WasmExternRef? ref, List<int> makeTypedData(int size)) {
  int length = objectLength(ref).toInt();
  List<int> list = makeTypedData(length);
  for (int i = 0; i < length; i++) {
    list[i] = toDartNumber(objectReadIndex(ref, i)).toInt();
  }
  return list;
}

List<Object?> toDartList(WasmExternRef? ref) => List<Object?>.generate(
    objectLength(ref).round(), (int n) => dartifyRaw(objectReadIndex(ref, n)));

@pragma("wasm:import", "dart2wasm.wrapDartFunction")
external WasmExternRef? _wrapDartFunctionRaw(WasmExternRef? dartFunction,
    WasmExternRef? trampolineName, WasmExternRef? argCount);

F _wrapDartFunction<F extends Function>(
    F f, String trampolineName, int argCount) {
  if (functionToJSWrapper.containsKey(f)) {
    return f;
  }
  JSValue wrappedFunction = JSValue(_wrapDartFunctionRaw(
      f.toJS().toExternRef(),
      trampolineName.toJS().toExternRef(),
      argCount.toDouble().toJS().toExternRef())!);
  functionToJSWrapper[f] = wrappedFunction;
  return f;
}

/// Returns the JS constructor object for a given [String].
WasmExternRef? getConstructorRaw(String name) =>
    getPropertyRaw(globalThisRaw(), name.toExternRef());

/// Equivalent to `Object.keys(object)`.
JSArray objectKeys(JSValue object) => JSArray(callMethodVarArgsRaw(
    getConstructorRaw('Object'),
    'keys'.toExternRef(),
    [object].toExternRef())!);

/// Methods used by the wasm runtime.
@pragma("wasm:export", "\$listLength")
double _listLength(List list) => list.length.toDouble();

@pragma("wasm:export", "\$listRead")
WasmExternRef? _listRead(List<Object?> list, double index) =>
    jsifyRaw(list[index.toInt()]);

@pragma("wasm:export", "\$byteDataGetUint8")
double _byteDataGetUint8(ByteData byteData, double index) =>
    byteData.getUint8(index.toInt()).toDouble();
