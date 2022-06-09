// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base class for closure objects.
class _Function implements Function {
  @pragma("wasm:entry-point")
  WasmDataRef context;

  @pragma("wasm:entry-point")
  _Function._(this.context);
}
