// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// Base class for closure objects.
class _Function implements Function {
  @pragma("wasm:entry-point")
  WasmDataRef context;

  @pragma("wasm:entry-point")
  _Function._(this.context);

  @override
  bool operator ==(Object other) {
    if (other is! _Function) {
      return false;
    }
    return _equals(this, other);
  }

  external static bool _equals(_Function a, _Function b);

  // Simple hash code for now, we can optimize later
  @override
  int get hashCode => runtimeType.hashCode;
}
