// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Class of the `null` value.
 *
 * The only instance of the [Null] class is the `null` object.
 *
 * It is an error for a class to extend or implement Null.
 */
class Null {
  factory Null._uninstantiable() {
    throw new UnsupportedError('class Null cannot be instantiated');
  }

  /** Returns the string `"null"`. */
  String toString() => "null";
}
