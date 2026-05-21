// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_error_utils';
import 'dart:_internal' show patch;
import 'dart:_string';
import 'dart:_wasm';

@patch
class RegExp {
  @patch
  factory RegExp(
    String source, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    return EmbedderRegExp(source, multiLine, caseSensitive, unicode, dotAll);
  }

  @patch
  static String escape(String text) {
    return EmbedderStringImpl.fromRefUnchecked(
      regexpEscape(embedderStringFromDartString(text).wrappedExternRef),
    );
  }
}
