// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.util;

/**
 * Utilities for {@link String}.
 */
public class StringUtils {
  /**
   * The empty String <code>""</code>.
   */
  public static final String EMPTY = "";

  /**
   * @return the the substring before the first occurrence of a separator.
   */
  public static String substringBefore(String str, String separator) {
    int index = str.indexOf(separator);
    if (index == -1) {
      return str;
    }
    return str.substring(0, index);
  }

  /**
   * @return the substring after the first occurrence of a separator.
   */
  public static String substringAfter(String str, String separator) {
    int index = str.indexOf(separator);
    if (index == -1) {
      return EMPTY;
    }
    return str.substring(index + separator.length());
  }
}
