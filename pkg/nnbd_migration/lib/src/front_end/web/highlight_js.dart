// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js';

final HighlightJs hljs = HighlightJs._();

/// A small wrapper around the JavaScript highlight.js APIs.
class HighlightJs {
  static JsObject get _hljs => context['hljs'] as JsObject;

  HighlightJs._();

  void highlightBlock(Element block) {
    _hljs.callMethod('highlightBlock', [block]);
  }
}
