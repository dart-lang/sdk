// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("json");
#native("json.js");

/**
 * Dart interface to JavaScript objects and JSON.
 * (The native method implementations are in json.js.)
 */

class JSON {
  /**
   * Takes a string in JSON notation and returns the value it
   * represents.  The resulting value is one of the following:
   *   null
   *   a bool
   *   a double
   *   a String
   *   an Array of values (recursively)
   *   a Map from property names to values (recursively)
   */
  static Object parse(String jsonString) native;

  /**
   * Takes a value and returns a string in JSON notation
   * representing its value, or returns null if the value is not representable
   * in JSON.  A representable value is one of the following:
   *   null
   *   a bool
   *   a double
   *   a String
   *   an Array of values (recursively)
   *   a Map from property names to values (recursively)
   */
  static String stringify(Object value) native;
}
