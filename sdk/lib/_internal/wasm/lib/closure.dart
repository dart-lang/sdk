// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// Base class for closure objects.
final class _Closure implements Function {
  @pragma("wasm:entry-point")
  WasmStructRef context;

  @pragma("wasm:entry-point")
  _Closure._(this.context);

  @override
  bool operator ==(Object other) {
    if (other is! Function) {
      return false;
    }
    return _equals(this, other);
  }

  external static bool _equals(Function a, Function b);

  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  external static _FunctionType _getClosureRuntimeType(_Closure closure);

  @override
  int get hashCode {
    if (_isInstantiationClosure) {
      return Object.hash(_instantiatedClosure, _instantiationClosureTypeHash());
    }

    if (_isInstanceTearOff) {
      return Object.hash(
          _instanceTearOffReceiver, _getClosureRuntimeType(this));
    }

    return Object._objectHashCode(this); // identity hash
  }

  // Support dynamic tear-off of `.call` on functions
  @pragma("wasm:entry-point")
  Function get call => this;

  @override
  String toString() => 'Closure: $runtimeType';

  // Helpers for implementing `hashCode`, `operator ==`.

  /// Whether the closure is an instantiation.
  external bool get _isInstantiationClosure;

  /// When the closure is an instantiation, get the instantiated closure.
  ///
  /// Traps when the closure is not an instantiation.
  external _Closure? get _instantiatedClosure;

  /// When the closure is an instantiation, returns the combined hash code of
  /// the captured types.
  ///
  /// Traps when the closure is not an instantiation.
  external int _instantiationClosureTypeHash();

  /// Whether the closure is an instance tear-off.
  ///
  /// Instance tear-offs will have receivers.
  external bool get _isInstanceTearOff;

  /// When the closure is an instance tear-off, returns the receiver.
  ///
  /// Traps when the closure is not an instance tear-off.
  external Object? get _instanceTearOffReceiver;
}
