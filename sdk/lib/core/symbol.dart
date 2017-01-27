// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Opaque name used by mirrors, invocations and [Function.apply].
abstract class Symbol {
  /**
   * Constructs a new Symbol.
   *
   * The name must be a valid public Dart member name,
   * public constructor name, or library name, optionally qualified.
   *
   * A qualified name is a valid name preceded by a public identifier name
   * and a '`.`', e.g., `foo.bar.baz=` is a qualified version of `baz=`.
   * That means that the content of the [name] String must be either
   *
   * * a valid public Dart identifier
   *   (that is, an identifier not starting with "`_`"),
   * * such an identifier followed by "=" (a setter name),
   * * the name of a declarable operator
   *   (one of "`+`", "`-`", "`*`", "`/`", "`%`", "`~/`", "`&`", "`|`",
   *   "`^`", "`~`", "`<<`", "`>>`", "`<`", "`<=`", "`>`", "`>=`", "`==`",
   *   "`[]`", "`[]=`", or "`unary-`"),
   * * any of the above preceded by any number of qualifiers,
   *   where a qualifier is a non-private identifier followed by '`.`',
   * * or the empty string (the default name of a library with no library
   *   name declaration).
   *
   * The following text is non-normative:
   *
   * Creating non-const Symbol instances may result in larger output.  If
   * possible, use [MirrorsUsed] in "dart:mirrors" to specify which names might
   * be passed to this constructor.
   */
  const factory Symbol(String name) = internal.Symbol;

  /**
   * Returns a hash code compatible with [operator==].
   *
   * Equal symbols have the same hash code.
   */
  int get hashCode;

  /**
   * Symbols are equal to other symbols that correspond to the same member name.
   *
   * Qualified member names, like `#foo.bar` are equal only if they have the
   * same identifiers before the same final member name.
   */
  bool operator ==(other);
}
