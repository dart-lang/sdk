// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_element.src.custom_tag_name;

/**
 * Returns true if this is a valid custom element name. See:
 * <https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html#dfn-custom-element-name>
 */
bool isCustomTag(String name) {
  if (!name.contains('-')) return false;

  // These names have meaning in SVG or MathML, so they aren't allowed as custom
  // tags.
  var invalidNames = const {
    'annotation-xml': '',
    'color-profile': '',
    'font-face': '',
    'font-face-src': '',
    'font-face-uri': '',
    'font-face-format': '',
    'font-face-name': '',
    'missing-glyph': '',
  };
  return !invalidNames.containsKey(name);
}
