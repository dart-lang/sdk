// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_internal' show patch;
import 'dart:_string';
import 'dart:_wasm';

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  @pragma('wasm:never-inline')
  static StackTrace get current {
    final hostStackTrace = stackTraceGetCurrent();
    return _EmbedderStackTrace(hostStackTrace);
  }
}

final class _EmbedderStackTrace implements StackTrace {
  WasmExternRef? _embedderStackTrace = WasmExternRef.nullRef;

  _EmbedderStackTrace(WasmExternRef? obj) {
    _embedderStackTrace = obj;
  }

  @override
  String toString() {
    return JSStringImpl.fromRefUnchecked(
      stackTraceToString(_embedderStackTrace),
    );
  }
}
