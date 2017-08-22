// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Listener used in combination with `TopLevelParser` to extract the URIs of
/// import, part, and export directives.
library front_end.src.fasta.source.directive_listener;

import '../../scanner/token.dart' show Token;
import '../fasta_codes.dart' show Message, codeExpectedBlockToSkip;
import '../parser/identifier_context.dart';
import '../parser/listener.dart';
import '../quote.dart';

/// Listener that records imports, exports, and part directives.
///
/// This is normally used in combination with the `TopLevelParser`, which skips
/// over the body of declarations like classes and function that are irrelevant
/// for directives. Note that on correct programs directives cannot occur after
/// any top-level declaration, but we recommend to continue parsing the entire
/// file in order to gracefully handle input errors.
class DirectiveListener extends Listener {
  /// Import directives with URIs and combinators.
  final List<NamespaceDirective> imports = <NamespaceDirective>[];

  /// Export directives with URIs and combinators.
  final List<NamespaceDirective> exports = <NamespaceDirective>[];

  /// Collects URIs that occur on any part directive.
  final Set<String> parts = new Set<String>();

  bool _inPart = false;
  String _uri;
  List<NamespaceCombinator> _combinators;
  List<String> _combinatorNames;

  DirectiveListener();

  @override
  beginExport(Token export) {
    _combinators = <NamespaceCombinator>[];
  }

  @override
  void beginHide(Token hide) {
    _combinatorNames = <String>[];
  }

  @override
  beginImport(Token import) {
    _combinators = <NamespaceCombinator>[];
  }

  @override
  void beginLiteralString(Token token) {
    if (_combinators != null || _inPart) {
      _uri = unescapeString(token.lexeme);
    }
  }

  @override
  beginPart(Token part) {
    _inPart = true;
  }

  @override
  void beginShow(Token show) {
    _combinatorNames = <String>[];
  }

  @override
  endExport(Token export, Token semicolon) {
    exports.add(new NamespaceDirective.export(_uri, _combinators));
    _uri = null;
    _combinators = null;
  }

  @override
  void endHide(Token hide) {
    _combinators.add(new NamespaceCombinator.hide(_combinatorNames));
    _combinatorNames = null;
  }

  @override
  endImport(Token import, Token deferred, Token asKeyword, Token semicolon) {
    imports.add(new NamespaceDirective.import(_uri, _combinators));
    _uri = null;
    _combinators = null;
  }

  @override
  endPart(Token part, Token semicolon) {
    parts.add(_uri);
    _uri = null;
    _inPart = false;
  }

  @override
  void endShow(Token show) {
    _combinators.add(new NamespaceCombinator.show(_combinatorNames));
    _combinatorNames = null;
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (_combinatorNames != null && context == IdentifierContext.combinator) {
      _combinatorNames.add(token.lexeme);
    }
  }

  /// Defines how native clauses are handled. By default, they are not handled
  /// and an error is thrown;
  Token handleNativeClauseError(Token token) => null;

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    if (message.code == codeExpectedBlockToSkip) {
      Token recover = handleNativeClauseError(token);
      if (recover != null) return recover;
    }
    return super.handleUnrecoverableError(token, message);
  }
}

class NamespaceCombinator {
  final bool isShow;
  final Set<String> names;

  NamespaceCombinator.hide(List<String> names)
      : isShow = false,
        names = names.toSet();

  NamespaceCombinator.show(List<String> names)
      : isShow = true,
        names = names.toSet();
}

class NamespaceDirective {
  final bool isImport;
  final String uri;
  final List<NamespaceCombinator> combinators;

  NamespaceDirective.export(this.uri, this.combinators) : isImport = false;

  NamespaceDirective.import(this.uri, this.combinators) : isImport = true;
}
