// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.src.build.constants;

/// These names have meaning in SVG or MathML, so they aren't allowed as custom
/// tags. See [isCustomTagName].
const invalidTagNames = const {
  'annotation-xml': '',
  'color-profile': '',
  'font-face': '',
  'font-face-src': '',
  'font-face-uri': '',
  'font-face-format': '',
  'font-face-name': '',
  'missing-glyph': '',
};

const POLYMER_EXPERIMENTAL_HTML = 'packages/polymer/polymer_experimental.html';
