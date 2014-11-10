// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.token;

import 'package:source_span/source_span.dart';

import 'style.dart';

/// A token emitted by a [Scanner].
class Token {
  /// The token type.
  final TokenType type;

  /// The span associated with the token.
  final FileSpan span;

  Token(this.type, this.span);

  String toString() => type.toString();
}

/// A token representing a `%YAML` directive.
class VersionDirectiveToken implements Token {
  get type => TokenType.VERSION_DIRECTIVE;
  final FileSpan span;

  /// The declared major version of the document.
  final int major;

  /// The declared minor version of the document.
  final int minor;

  VersionDirectiveToken(this.span, this.major, this.minor);

  String toString() => "VERSION_DIRECTIVE $major.$minor";
}

/// A token representing a `%TAG` directive.
class TagDirectiveToken implements Token {
  get type => TokenType.TAG_DIRECTIVE;
  final FileSpan span;

  /// The tag handle used in the document.
  final String handle;

  /// The tag prefix that the handle maps to.
  final String prefix;

  TagDirectiveToken(this.span, this.handle, this.prefix);

  String toString() => "TAG_DIRECTIVE $handle $prefix";
}

/// A token representing an anchor (`&foo`).
class AnchorToken implements Token {
  get type => TokenType.ANCHOR;
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AnchorToken(this.span, this.name);

  String toString() => "ANCHOR $name";
}

/// A token representing an alias (`*foo`).
class AliasToken implements Token {
  get type => TokenType.ALIAS;
  final FileSpan span;

  /// The name of the anchor.
  final String name;

  AliasToken(this.span, this.name);

  String toString() => "ALIAS $name";
}

/// A token representing a tag (`!foo`).
class TagToken implements Token {
  get type => TokenType.TAG;
  final FileSpan span;

  /// The tag handle.
  final String handle;

  /// The tag suffix, or `null`.
  final String suffix;

  TagToken(this.span, this.handle, this.suffix);

  String toString() => "TAG $handle $suffix";
}

/// A tkoen representing a scalar value.
class ScalarToken implements Token {
  get type => TokenType.SCALAR;
  final FileSpan span;

  /// The contents of the scalar.
  final String value;

  /// The style of the scalar in the original source.
  final ScalarStyle style;

  ScalarToken(this.span, this.value, this.style);

  String toString() => "SCALAR $style \"$value\"";
}

/// An enum of types of [Token] object.
class TokenType {
  static const STREAM_START = const TokenType._("STREAM_START");
  static const STREAM_END = const TokenType._("STREAM_END");

  static const VERSION_DIRECTIVE = const TokenType._("VERSION_DIRECTIVE");
  static const TAG_DIRECTIVE = const TokenType._("TAG_DIRECTIVE");
  static const DOCUMENT_START = const TokenType._("DOCUMENT_START");
  static const DOCUMENT_END = const TokenType._("DOCUMENT_END");

  static const BLOCK_SEQUENCE_START = const TokenType._("BLOCK_SEQUENCE_START");
  static const BLOCK_MAPPING_START = const TokenType._("BLOCK_MAPPING_START");
  static const BLOCK_END = const TokenType._("BLOCK_END");

  static const FLOW_SEQUENCE_START = const TokenType._("FLOW_SEQUENCE_START");
  static const FLOW_SEQUENCE_END = const TokenType._("FLOW_SEQUENCE_END");
  static const FLOW_MAPPING_START = const TokenType._("FLOW_MAPPING_START");
  static const FLOW_MAPPING_END = const TokenType._("FLOW_MAPPING_END");

  static const BLOCK_ENTRY = const TokenType._("BLOCK_ENTRY");
  static const FLOW_ENTRY = const TokenType._("FLOW_ENTRY");
  static const KEY = const TokenType._("KEY");
  static const VALUE = const TokenType._("VALUE");

  static const ALIAS = const TokenType._("ALIAS");
  static const ANCHOR = const TokenType._("ANCHOR");
  static const TAG = const TokenType._("TAG");
  static const SCALAR = const TokenType._("SCALAR");

  final String name;

  const TokenType._(this.name);

  String toString() => name;
}
