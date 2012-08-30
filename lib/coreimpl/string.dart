// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringImplementation {
  /**
   * Factory implementation of String.fromCharCodes:
   * Allocates a new String for the specified [charCodes].
   */
  factory String.fromCharCodes(List<int> charCodes) {
    return _fromCharCodes(charCodes);
  }

  external static String _fromCharCodes(List<int> charCodes);

  /**
   * Joins all the given strings to create a new string.
   */
  external static String join(List<String> strings, String separator);

  /**
   * Concatenates all the given strings to create a new string.
   */
  external static String concatAll(List<String> strings);

}
