// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

/**
 * The reserved word [:null:] denotes an object that is the sole instance of 
 * this class.
 * 
 * It is a compile-time error for a class to attempt to extend or implement
 * Null.
 */
class Null {
  factory Null._uninstantiable() {
    throw new UnsupportedError('class Null cannot be instantiated');
  }

  external int get hashCode;

  /** Returns the string `"null"`. */
  String toString() => "null";
}
