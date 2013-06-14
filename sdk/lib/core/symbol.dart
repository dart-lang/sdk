// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Opaque name used by mirrors, invocations and [Function.apply].
class Symbol {
  /**
   * Constructs a new Symbol.
   *
   * An [ArgumentError] is thrown if [name] starts with an underscore, or if
   * [name] is not a [String].  An [ArgumentError] is thrown if [name] is not
   * an empty string and is not a valid qualified identifier optionally
   * followed by [:'=':].
   *
   * The following text is non-normative:
   *
   * Creating non-const Symbol instances may result in larger output.  If
   * possible, use [MirrorsUsed] in "dart:mirrors" to specify which names might
   * be passed to this constructor.
   */
  const factory Symbol(String name) = _collection_dev.Symbol;
}
