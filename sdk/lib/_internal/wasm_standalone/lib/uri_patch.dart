// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_internal' show patch;
import 'dart:_string';
import 'dart:_wasm';

@patch
class Uri {
  @patch
  static Uri get base {
    final currentUri = JSStringImpl.fromRefUnchecked(baseUri());
    if (currentUri != null) {
      return Uri.parse(currentUri);
    }
    throw UnsupportedError("'Uri.base' is not supported");
  }
}

@patch
class _Uri {
  @patch
  static bool get _isWindows => _isWindowsCached;

  static final bool _isWindowsCached = isWindows().toBool();
}
