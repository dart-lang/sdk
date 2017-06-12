// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utilslib;

/**
 * General purpose string manipulation utilities.
 */
class StringUtils {
  /**
   * Returns either [str], or if [str] is null, the value of [defaultStr].
   */
  static String defaultString(String str, [String defaultStr = '']) {
    return str == null ? defaultStr : str;
  }

  /** Parse string to a double, and handle null intelligently */
  static double parseDouble(String str, [double ifNull = null]) {
    return (str == null) ? ifNull : double.parse(str);
  }

  /** Parse string to a int, and handle null intelligently */
  static int parseInt(String str, [int ifNull = null]) {
    return (str == null) ? ifNull : int.parse(str);
  }

  /** Parse bool to a double, and handle null intelligently */
  // TODO(jacobr): corelib should have a boolean parsing method
  static bool parseBool(String str, [bool ifNull = null]) {
    assert(str == null || str == 'true' || str == 'false');
    return (str == null) ? ifNull : (str == 'true');
  }
}
