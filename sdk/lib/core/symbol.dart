// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Opaque name used by mirrors, invocations and [Function.apply].
class Symbol {
  /**
   * Constructs a new Symbol.
   *
   * An [ArgumentError] is thrown if [name] starts with an underscore,
   * or if [name] is not a [String].  An [ArgumentError] is thrown if
   * [name] is not an empty string and is not a valid qualified
   * identifier optionally followed by [:'=':].
   */
  const factory Symbol(String name) = _collection_dev.Symbol;
}
