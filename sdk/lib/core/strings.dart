// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_core;

abstract class Strings {
  /**
   * Joins all the given strings to create a new string.
   */
  external static String join(List<String> strings, String separator);

  /**
   * Concatenates all the given strings to create a new string.
   */
  external static String concatAll(List<String> strings);
}
