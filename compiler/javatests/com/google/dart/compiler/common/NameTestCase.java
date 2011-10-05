// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import junit.framework.TestCase;

abstract class NameTestCase extends TestCase {
  protected static final char[] _AM = "am".toCharArray();
  protected static char[] _EMPTY = "".toCharArray();

  /**
   * Google favorite: "ÃŽÃ±Å£Ã©rÃ±Ã¥Å£Ã®Ã¶Ã±Ã¥Ä¼Ã®Å¾Ã¥Å£Ã®á»Ã±". Using modified
   * UTF-8 encoding, this 20 character string is 40 bytes long. So it must be
   * shrunk by appending a byte array. This string contains characters that
   * expand to 1, 2, and 3 bytes, thus covering all the cases in modified UTF-8.
   */
  protected static char[] _HIGHCHARS = ("\u00ce\u00f1\u0163\u00e9r"
      + "\u00f1\u00e5\u0163\u00ee\u00f6\u00f1\u00e5\u013c\u00ee\u017e"
      + "\u00e5\u0163\u00ee\u1edd\u00f1").toCharArray();

  protected static char[] _NAME = "name".toCharArray();

  protected static final char[][] INPUTS = {_AM, _EMPTY, _HIGHCHARS, _NAME};
  protected static final int NUM_INPUTS = INPUTS.length;

  protected static void assertNotEquals(Object expected, Object actual) {
    if ((expected == null) != (actual == null)) {
      return;
    }
    if (expected != null && !expected.equals(actual)) {
      return;
    }
    fail("expected not equals:<" + expected + "> was:<" + actual + ">");
  }
}
