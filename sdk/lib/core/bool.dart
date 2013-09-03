// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The reserved words [:true:] and [:false:] denote objects that are the only
 * instances of this class.
 *
 * It is a compile-time error for a class to attempt to extend or implement
 * bool.
 */
class bool {
  factory bool._uninstantiable() {
    throw new UnsupportedError(
        "class bool cannot be instantiated");
  }

  /**
   * Returns [:"true":] if the receiver is [:true:], or [:"false":] if the
   * receiver is [:false:].
   */
  String toString() {
    return this ? "true" : "false";
  }
}
