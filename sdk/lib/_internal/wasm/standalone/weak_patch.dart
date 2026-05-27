// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_internal' show patch, unsafeCast, checkValidWeakTarget;
import 'dart:_wasm';
import 'dart:async';

@patch
class Expando<T extends Object> {
  WasmExternRef? _expando = WasmExternRef.nullRef;

  @patch
  Expando([String? name]) : name = name {
    _expando = expandoCreate();
  }

  @patch
  T? operator [](Object object) {
    checkValidWeakTarget(object, 'object');
    return unsafeCast(
      expandoGet(
        _expando,
        WasmAnyRef.fromObject(object),
        WasmI64.fromInt(identityHashCode(object)),
      )?.toObject(),
    );
  }

  @patch
  void operator []=(Object object, T? value) {
    checkValidWeakTarget(object, 'object');
    expandoSet(
      _expando,
      WasmAnyRef.fromObject(object),
      WasmI64.fromInt(identityHashCode(object)),
      value == null ? null : WasmAnyRef.fromObject(value),
    );
  }
}

@patch
class WeakReference<T extends Object> {
  @patch
  factory WeakReference(T target) {
    checkValidWeakTarget(target, 'target');
    return _EmbedderWeakReference<T>(target);
  }
}

final class _EmbedderWeakReference<T extends Object>
    implements WeakReference<T> {
  WasmExternRef? _ref = WasmExternRef.nullRef;

  _EmbedderWeakReference(T target) {
    _ref = weakRefCreate(WasmAnyRef.fromObject(target));
  }

  @override
  T? get target {
    return unsafeCast(weakRefGet(_ref)?.toObject());
  }
}

@patch
class Finalizer<T> {
  @patch
  factory Finalizer(void Function(T) callback) {
    return _EmbedderFinalizer<T>(callback);
  }
}

final class _EmbedderFinalizer<T> implements Finalizer<T> {
  final void Function(T) _callback;
  WasmExternRef? _finalizer = WasmExternRef.nullRef;

  _EmbedderFinalizer(void Function(T) callback)
    : _callback = Zone.current.bindUnaryCallback(callback) {
    _finalizer = finalizerCreate(
      WasmFunction.fromFunction(_entrypoint),
      WasmAnyRef.fromObject(this),
    );
  }

  @override
  void attach(Object value, T finalizationToken, {Object? detach}) {
    checkValidWeakTarget(value, 'value');
    if (detach != null) checkValidWeakTarget(detach, 'detach');

    finalizerAttach(
      _finalizer,
      WasmAnyRef.fromObject(value),
      finalizationToken == null
          ? null
          : WasmAnyRef.fromObject(finalizationToken),
      detach == null ? null : WasmAnyRef.fromObject(detach),
    );
  }

  @override
  void detach(Object detach) {
    checkValidWeakTarget(detach, 'detach');
    finalizerDetach(_finalizer, WasmAnyRef.fromObject(detach));
  }

  static WasmVoid _entrypoint(WasmAnyRef finalizer, WasmAnyRef? token) {
    final dartFinalizer = unsafeCast<_EmbedderFinalizer>(finalizer.toObject());
    dartFinalizer._callback(token?.toObject());
    return WasmVoid();
  }
}
