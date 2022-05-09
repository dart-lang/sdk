// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base class for closure objects.
@pragma("wasm:entry-point")
class _Function {
  @pragma("wasm:entry-point")
  WasmDataRef context;

  _Function._(this.context);
}
