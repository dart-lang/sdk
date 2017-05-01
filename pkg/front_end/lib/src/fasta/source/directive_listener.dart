// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Listener used in combination with `TopLevelParser` to extract the URIs of
/// import, part, and export directives.
library front_end.src.fasta.source.directive_listener;

import '../fasta_codes.dart' show FastaMessage, codeExpectedBlockToSkip;
import '../parser/listener.dart';
import '../quote.dart';
import '../scanner/token.dart';

/// Listener that records the URIs from imports, exports, and part directives.
///
/// This is normally used in combination with the `TopLevelParser`, which skips
/// over the body of declarations like classes and function that are irrelevant
/// for directives. Note that on correct programs directives cannot occur after
/// any top-level declaration, but we recommend to continue parsing the entire
/// file in order to gracefully handle input errors.
class DirectiveListener extends Listener {
  /// Collects URIs that occur on any import directive.
  final Set<String> imports = new Set<String>();

  /// Collects URIs that occur on any export directive.
  final Set<String> exports = new Set<String>();

  /// Collects URIs that occur on any part directive.
  final Set<String> parts = new Set<String>();

  DirectiveListener();

  /// Set when entering the context of a directive, null when the parser is not
  /// looking at a directive.
  Set<String> _current = null;

  bool get _inDirective => _current != null;

  @override
  beginImport(_) {
    _current = imports;
  }

  @override
  beginExport(_) {
    _current = exports;
  }

  @override
  beginPart(_) {
    _current = parts;
  }

  @override
  endExport(export, semicolon) {
    _current = null;
  }

  @override
  endImport(import, deferred, asKeyword, semicolon) {
    _current = null;
  }

  @override
  endPart(part, semicolon) {
    _current = null;
  }

  @override
  void beginLiteralString(Token token) {
    if (_inDirective) {
      _current.add(unescapeString(token.lexeme));
    }
  }

  @override
  Token handleUnrecoverableError(Token token, FastaMessage message) {
    if (message.code == codeExpectedBlockToSkip) {
      Token recover = handleNativeClause(token);
      if (recover != null) return recover;
    }
    return super.handleUnrecoverableError(token, message);
  }

  /// Defines how native clauses are handled. By default, they are not handled
  /// and an error is thrown;
  Token handleNativeClause(Token token) => null;
}
