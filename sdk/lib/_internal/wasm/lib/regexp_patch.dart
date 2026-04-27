// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_helper' show JSSyntaxRegExp, quoteStringForRegExp;
import 'dart:_internal' show patch;

@patch
class RegExp {
  @patch
  factory RegExp(
    String source, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) => JSSyntaxRegExp(
    source,
    multiLine: multiLine,
    caseSensitive: caseSensitive,
    unicode: unicode,
    dotAll: dotAll,
  );

  @patch
  static String escape(String text) => quoteStringForRegExp(text);
}
