// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:_wasm';

@patch
class double {
  @patch
  static double parse(String source) {
    double? result = tryParse(source);
    if (result == null) {
      throw FormatException('Invalid double $source');
    }
    return result;
  }

  @patch
  static double? tryParse(String source) {
    final parseResult = doubleTryParse(
      jsStringFromDartString(source).wrappedExternRef,
    );
    if (parseResult.isNull) {
      return null;
    } else {
      return tryParseResultGetDouble(parseResult).toDouble();
    }
  }
}
