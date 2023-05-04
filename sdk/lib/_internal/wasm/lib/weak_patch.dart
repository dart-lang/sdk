// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_helper' show isJSUndefined, JS;
import 'dart:_wasm';
import 'dart:ffi' show Pointer, Struct, Union;

void _checkValidWeakTarget(Object object) {
  if ((object is bool) ||
      (object is num) ||
      (object is String) ||
      (object is Record) ||
      (object is Pointer) ||
      (object is Struct) ||
      (object is Union)) {
    throw new ArgumentError.value(
        object,
        "A string, number, boolean, record, Pointer, Struct or Union "
        "can't be a weak target");
  }
}

@patch
class Expando<T> {
  WasmExternRef? _jsWeakMap;

  @patch
  Expando([String? name]) : name = name {
    _jsWeakMap = JS<WasmExternRef?>("() => new WeakMap()");
  }

  @patch
  T? operator [](Object object) {
    _checkValidWeakTarget(object);
    final result =
        JS<WasmExternRef?>("(map, o) => map.get(o)", _jsWeakMap, object);
    // Coerce to null if JavaScript returns undefined.
    if (isJSUndefined(result)) return null;
    return unsafeCast(result.internalize()?.toObject());
  }

  @patch
  void operator []=(Object object, T? value) {
    _checkValidWeakTarget(object);
    JS<void>(
        "(map, o, v) => map.set(o, v)", _jsWeakMap, object, value as Object?);
  }
}

@patch
class WeakReference<T extends Object> {
  @patch
  factory WeakReference(T object) {
    return _WeakReferenceWrapper<T>(object);
  }
}

class _WeakReferenceWrapper<T extends Object> implements WeakReference<T> {
  WasmExternRef? _jsWeakRef;

  _WeakReferenceWrapper(T object) {
    _checkValidWeakTarget(object);
    _jsWeakRef = JS<WasmExternRef?>("o => new WeakRef(o)", object as Object);
  }

  T? get target {
    final result = JS<WasmExternRef?>("r => r.deref()", _jsWeakRef);
    // Coerce to null if JavaScript returns undefined.
    if (isJSUndefined(result)) return null;
    return unsafeCast(result.internalize()?.toObject());
  }
}

@patch
class Finalizer<T> {
  @patch
  factory Finalizer(void Function(T) object) {
    return _FinalizationRegistryWrapper<T>(object);
  }
}

class _FinalizationRegistryWrapper<T> implements Finalizer<T> {
  WasmExternRef? _jsFinalizationRegistry;

  _FinalizationRegistryWrapper(void Function(T) callback) {
    // TODO(joshualitt): Use `allowInterop` instead of explicit trampoline.
    _jsFinalizationRegistry = JS<WasmExternRef?>(
        r"""c => new FinalizationRegistry(
            o => dartInstance.exports.$invokeCallback1(c, o))""",
        (dynamic o) => callback(unsafeCast(o)));
  }

  void attach(Object value, T token, {Object? detach}) {
    _checkValidWeakTarget(value);
    if (detach != null) {
      _checkValidWeakTarget(detach);
      JS<void>("(r, v, t, d) => r.register(v, t, d)", _jsFinalizationRegistry,
          value, token as Object, detach);
    } else {
      JS<void>("(r, v, t) => r.register(v, t)", _jsFinalizationRegistry, value,
          token as Object);
    }
  }

  void detach(Object detachToken) {
    JS<void>("(r, d) => r.unregister(d)", _jsFinalizationRegistry, detachToken);
  }
}
