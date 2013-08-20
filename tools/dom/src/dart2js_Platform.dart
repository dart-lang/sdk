// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class Platform {
  /**
   * Returns true if dart:typed_data types are supported on this
   * browser.  If false, using these types will generate a runtime
   * error.
   */
  static final supportsTypedData = JS('bool', '!!(window.ArrayBuffer)');

  /**
   * Returns true if SIMD types in dart:typed_data types are supported
   * on this browser.  If false, using these types will generate a runtime
   * error.
   */
  static final supportsSimd = false;

  /**
   * Upgrade all custom elements in the subtree which have not been upgraded.
   *
   * This is needed to cover timing scenarios which the custom element polyfill
   * does not cover.
   */
  static void upgradeCustomElements(Node node) {
    if (JS('bool', '(#.CustomElements && #.CustomElements.upgradeAll)',
        window, window)) {
      JS('', '#.CustomElements.upgradeAll(#)', window, node);
    }
  }
}
