// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Listener used in combination with `TopLevelParser` to extract the URIs of
/// import, part, and export directives.
library front_end.src.fasta.source.directive_listener;

import '../fasta_codes.dart' show FastaMessage, codeExpectedBlockToSkip;
import '../parser/identifier_context.dart';
import '../parser/listener.dart';
import '../quote.dart';
import '../../scanner/token.dart' show Token;
import 'stack_listener.dart';

/// Listener that records imports, exports, and part directives.
///
/// This is normally used in combination with the `TopLevelParser`, which skips
/// over the body of declarations like classes and function that are irrelevant
/// for directives. Note that on correct programs directives cannot occur after
/// any top-level declaration, but we recommend to continue parsing the entire
/// file in order to gracefully handle input errors.
class DirectiveListener extends Listener {
  final Stack _stack = new Stack();

  /// Export directives with URIs and combinators.
  final List<ImportDirective> imports = <ImportDirective>[];

  /// Export directives with URIs and combinators.
  final List<ExportDirective> exports = <ExportDirective>[];

  /// Collects URIs that occur on any part directive.
  final Set<String> parts = new Set<String>();

  bool _inDirective = false;

  DirectiveListener();

  @override
  beginExport(_) {
    _inDirective = true;
  }

  @override
  beginImport(_) {
    _inDirective = true;
  }

  @override
  void beginLiteralString(Token token) {
    if (_inDirective) {
      _push(unescapeString(token.lexeme));
    }
  }

  @override
  beginPart(_) {
    _inDirective = true;
  }

  @override
  void endCombinators(int count) {
    List<String> names = _popList(count);
    _push(names);
  }

  @override
  endExport(export, semicolon) {
    List<NamespaceCombinator> combinators = _pop();
    String uri = _pop();
    exports.add(new ExportDirective(uri, combinators));
    _inDirective = false;
  }

  @override
  void endHide(Token hideKeyword) {
    List<String> names = _pop();
    _push(new NamespaceCombinator.hide(names));
  }

  @override
  void endIdentifierList(int count) {
    if (_inDirective) {
      _push(_popList(count) ?? <String>[]);
    }
  }

  @override
  endImport(import, deferred, asKeyword, semicolon) {
    List<NamespaceCombinator> combinators = _pop();
    String uri = _pop();
    imports.add(new ImportDirective(uri, combinators));
    _inDirective = false;
  }

  @override
  endPart(part, semicolon) {
    String uri = _pop();
    parts.add(uri);
    _inDirective = false;
  }

  @override
  void endShow(Token showKeyword) {
    List<String> names = _pop();
    _push(new NamespaceCombinator.show(names));
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    if (_inDirective && context == IdentifierContext.combinator) {
      _push(token.lexeme);
    }
  }

  /// Defines how native clauses are handled. By default, they are not handled
  /// and an error is thrown;
  Token handleNativeClause(Token token) => null;

  @override
  Token handleUnrecoverableError(Token token, FastaMessage message) {
    if (message.code == codeExpectedBlockToSkip) {
      Token recover = handleNativeClause(token);
      if (recover != null) return recover;
    }
    return super.handleUnrecoverableError(token, message);
  }

  T _pop<T>() {
    var value = _stack.pop() as T;
    return value;
  }

  List<T> _popList<T>(int n) {
    return _stack.popList(n);
  }

  void _push<T>(T value) {
    _stack.push(value);
  }
}

class ExportDirective {
  final String uri;
  final List<NamespaceCombinator> combinators;

  ExportDirective(this.uri, this.combinators);
}

class ImportDirective {
  final String uri;
  final List<NamespaceCombinator> combinators;

  ImportDirective(this.uri, this.combinators);
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
