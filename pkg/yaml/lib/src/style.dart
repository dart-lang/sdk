// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.style;

/// An enum of source scalar styles.
class ScalarStyle {
  /// No source style was specified.
  ///
  /// This usually indicates a scalar constructed with [YamlScalar.wrap].
  static const ANY = const ScalarStyle._("ANY");

  /// The plain scalar style, unquoted and without a prefix.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#style/flow/plain.
  static const PLAIN = const ScalarStyle._("PLAIN");

  /// The literal scalar style, with a `|` prefix.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#id2795688.
  static const LITERAL = const ScalarStyle._("LITERAL");


  /// The folded scalar style, with a `>` prefix.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#id2796251.
  static const FOLDED = const ScalarStyle._("FOLDED");

  /// The single-quoted scalar style.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#style/flow/single-quoted.
  static const SINGLE_QUOTED = const ScalarStyle._("SINGLE_QUOTED");

  /// The double-quoted scalar style.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#style/flow/double-quoted.
  static const DOUBLE_QUOTED = const ScalarStyle._("DOUBLE_QUOTED");

  final String name;

  /// Whether this is a quoted style ([SINGLE_QUOTED] or [DOUBLE_QUOTED]).
  bool get isQuoted => this == SINGLE_QUOTED || this == DOUBLE_QUOTED;

  const ScalarStyle._(this.name);

  String toString() => name;
}

/// An enum of collection styles.
class CollectionStyle {
  /// No source style was specified.
  ///
  /// This usually indicates a collection constructed with [YamlList.wrap] or
  /// [YamlMap.wrap].
  static const ANY = const CollectionStyle._("ANY");

  /// The indentation-based block style.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#id2797293.
  static const BLOCK = const CollectionStyle._("BLOCK");

  /// The delimiter-based block style.
  ///
  /// See http://yaml.org/spec/1.2/spec.html#id2790088.
  static const FLOW = const CollectionStyle._("FLOW");

  final String name;

  const CollectionStyle._(this.name);

  String toString() => name;
}
