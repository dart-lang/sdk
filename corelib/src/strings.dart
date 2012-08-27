// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Strings {
  /**
   * Joins all the given strings to create a new string.
   */
  static String join(List<String> strings, String separator) {
    return StringImplementation.join(strings, separator);
  }

  /**
   * Concatenates all the given strings to create a new string.
   */
  static String concatAll(List<String> strings) {
    return StringImplementation.concatAll(strings);
  }
}
