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
    if (other is! _Closure) {
      return false;
    }
    return _equals(this, other);
  }

  external static bool _equals(_Closure a, _Closure b);

  // Simple hash code for now, we can optimize later
  @override
  int get hashCode => runtimeType.hashCode;

  // Support dynamic tear-off of `.call` on functions
  @pragma("wasm:entry-point")
  _Closure get call => this;

  @override
  String toString() => 'Closure: $runtimeType';
}
