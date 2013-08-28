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
  static final supportsTypedData = true;

  /**
   * Returns true if SIMD types in dart:typed_data types are supported
   * on this browser.  If false, using these types will generate a runtime
   * error.
   */
  static final supportsSimd = true;

  /**
   * Upgrade all custom elements in the subtree which have not been upgraded.
   *
   * This is needed to cover timing scenarios which the custom element polyfill
   * does not cover.
   *
   * This is also a workaround for dartbug.com/12642 in Dartium.
   */
  static void upgradeCustomElements(Node node) {
    // no-op, provided for dart2js polyfill.
    if (node is Element) {
      (node as Element).queryAll('*');
    } else {
      node.nodes.forEach(upgradeCustomElements);
    }
  }
}
