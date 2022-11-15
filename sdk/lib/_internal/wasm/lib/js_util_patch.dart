// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util;

import "dart:_js_annotations" as js;
import "dart:_internal";
import "dart:_js_helper";
import "dart:async" show Completer, FutureOr;
import "dart:collection";
import "dart:typed_data";
import "dart:wasm";

@patch
dynamic jsify(Object? object) {
  HashMap<Object?, Object?> convertedObjects =
      HashMap<Object?, Object?>.identity();
  Object? convert(Object? o) {
    if (convertedObjects.containsKey(o)) {
      return convertedObjects[o];
    }

    if (o == null ||
        o is num ||
        o is bool ||
        o is Function ||
        o is JSValue ||
        o is String ||
        o is Int8List ||
        o is Uint8List ||
        o is Uint8ClampedList ||
        o is Int16List ||
        o is Uint16List ||
        o is Int32List ||
        o is Uint32List ||
        o is Float32List ||
        o is Float64List ||
        o is ByteBuffer ||
        o is ByteData) {
      return JSValue.box(jsifyRaw(o));
    }

    if (o is Map) {
      JSValue convertedMap = newObject<JSValue>();
      convertedObjects[o] = convertedMap;
      for (final key in o.keys) {
        JSValue? convertedKey = convert(key) as JSValue?;
        setPropertyRaw(convertedMap.toExternRef(), convertedKey?.toExternRef(),
            (convert(o[key]) as JSValue?)?.toExternRef());
      }
      return convertedMap;
    } else if (o is Iterable) {
      JSValue convertedIterable = _newArray();
      convertedObjects[o] = convertedIterable;
      for (Object? item in o) {
        callMethod(convertedIterable, 'push', [convert(item)]);
      }
      return convertedIterable;
    } else {
      // None of the objects left will require recursive conversions.
      return JSValue.box(jsifyRaw(o));
    }
  }

  return convert(object);
}

@patch
Object get globalThis => JSValue(globalThisRaw()!);

@patch
T newObject<T>() => JSValue(newObjectRaw()!) as T;

JSValue _newArray() => JSValue(newArrayRaw()!);

@patch
bool hasProperty(Object o, String name) =>
    hasPropertyRaw(jsifyRaw(o)!, name.toJS().toExternRef());

@patch
T getProperty<T>(Object o, String name) =>
    dartifyRaw(getPropertyRaw(jsifyRaw(o)!, name.toJS().toExternRef())) as T;

@patch
T setProperty<T>(Object o, String name, T? value) => dartifyRaw(setPropertyRaw(
    jsifyRaw(o)!, name.toJS().toExternRef(), jsifyRaw(value))) as T;

@patch
T callMethod<T>(Object o, String method, List<Object?> args) =>
    dartifyRaw(callMethodVarArgsRaw(jsifyRaw(o)!, method.toJS().toExternRef(),
        args.toJS().toExternRef())) as T;

@patch
bool instanceof(Object? o, Object type) =>
    instanceofRaw(jsifyRaw(o), jsifyRaw(type));

@patch
T callConstructor<T>(Object o, List<Object?> args) => dartifyRaw(
    callConstructorVarArgsRaw(jsifyRaw(o)!, args.toJS().toExternRef()))! as T;

@patch
T add<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T subtract<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T multiply<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T divide<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T exponentiate<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T modulo<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool equal<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool notEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictNotEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThanOrEqual<T>(Object? first, Object? second) =>
    throw 'unimplemented';

@patch
bool lessThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool lessThanOrEqual<T>(Object? first, Object? second) => throw 'unimplemented';

typedef _PromiseSuccessFunc = void Function(Object? value);
typedef _PromiseFailureFunc = void Function(Object? error);

@patch
Future<T> promiseToFuture<T>(Object jsPromise) {
  Completer<T> completer = Completer<T>();

  final success = js.allowInterop<_PromiseSuccessFunc>((r) {
    return completer.complete(r as FutureOr<T>?);
  });
  final error = js.allowInterop<_PromiseFailureFunc>((e) {
    // Note that `completeError` expects a non-nullable error regardless of
    // whether null-safety is enabled, so a `NullRejectionException` is always
    // provided if the error is `null` or `undefined`.
    // TODO(joshualitt): At this point `undefined` has been replaced with `null`
    // so we cannot tell them apart. In the future we should reify `undefined`
    // in Dart.
    if (e == null) {
      return completer.completeError(NullRejectionException._(false));
    }
    return completer.completeError(e);
  });

  promiseThen(jsifyRaw(jsPromise)!, jsifyRaw(success)!, jsifyRaw(error)!);
  return completer.future;
}

@patch
Object? objectGetPrototypeOf(Object? object) => throw 'unimplemented';

@patch
Object? get objectPrototype => throw 'unimplemented';

@patch
List<Object?> objectKeys(Object? object) =>
    dartifyRaw(objectKeysRaw(jsifyRaw(object))) as List<Object?>;

@patch
Object? dartify(Object? object) {
  HashMap<Object?, Object?> convertedObjects =
      HashMap<Object?, Object?>.identity();
  Object? convert(Object? o) {
    if (convertedObjects.containsKey(o)) {
      return convertedObjects[o];
    }

    // Because [List] needs to be shallowly converted across the interop
    // boundary, we have to double check for the case where a shallowly
    // converted [List] is passed back into [dartify].
    if (o is List) {
      List<Object?> converted = [];
      for (final item in o) {
        converted.add(convert(item));
      }
      return converted;
    }

    if (o is! JSValue) {
      return o;
    }

    WasmExternRef ref = o.toExternRef();
    if (isJSBoolean(ref) ||
        isJSNumber(ref) ||
        isJSString(ref) ||
        isJSUndefined(ref) ||
        isJSBoolean(ref) ||
        isJSNumber(ref) ||
        isJSString(ref) ||
        isJSInt8Array(ref) ||
        isJSUint8Array(ref) ||
        isJSUint8ClampedArray(ref) ||
        isJSInt16Array(ref) ||
        isJSUint16Array(ref) ||
        isJSInt32Array(ref) ||
        isJSUint32Array(ref) ||
        isJSFloat32Array(ref) ||
        isJSFloat64Array(ref) ||
        isJSArrayBuffer(ref) ||
        isJSDataView(ref)) {
      return dartifyRaw(ref);
    }

    // TODO(joshualitt) handle Date and Promise.

    if (isJSSimpleObject(ref)) {
      Map<Object?, Object?> dartMap = {};
      convertedObjects[o] = dartMap;
      // Keys will be a list of Dart [String]s.
      List<Object?> keys = objectKeys(o);
      for (int i = 0; i < keys.length; i++) {
        Object? key = keys[i];
        if (key != null) {
          dartMap[key] = convert(
              JSValue.box(getPropertyRaw(ref, (key as String).toExternRef())));
        }
      }
      return dartMap;
    } else if (isJSArray(ref)) {
      List<Object?> dartList = [];
      convertedObjects[o] = dartList;
      int length = getProperty<double>(o, 'length').toInt();
      for (int i = 0; i < length; i++) {
        dartList.add(convert(JSValue.box(objectReadIndex(ref, i))));
      }
      return dartList;
    } else {
      return dartifyRaw(ref);
    }
  }

  return convert(object);
}
