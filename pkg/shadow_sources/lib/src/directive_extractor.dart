// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart source directive parser and token rewriting utilities.
library;

import 'package:_fe_analyzer_shared/src/parser/experimental_features.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/parser/quote.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

/// The kind of top-level directive.
enum DirectiveKind { import, export, part, partOf }

/// Information about a directive occurrence in a Dart source file.
class DirectiveOccurrence {
  final DirectiveKind kind;
  final String uri;
  final int offset;
  final int length;
  final String rawLexeme;

  DirectiveOccurrence({
    required this.kind,
    required this.uri,
    required this.offset,
    required this.length,
    required this.rawLexeme,
  });

  bool get isImport => kind == .import;
  bool get isExport => kind == .export;
  bool get isPart => kind == .part;
  bool get isPartOf => kind == .partOf;

  @override
  String toString() =>
      'DirectiveOccurrence($kind: $uri, offset: $offset, len: $length)';
}

/// Token listener to extract directive URIs with exact token offsets.
///
/// Inspired by pkg/front_end/lib/src/source/directive_listener.dart, this
/// listener preserves exact offsets and lengths of directive string literals
/// for rewriting.
class DirectiveTokenListener extends Listener {
  final List<DirectiveOccurrence> occurrences = [];
  bool _inDirective = false;
  DirectiveKind? _currentKind;
  bool _uriCaptured = false;
  bool _inConditionalUri = false;
  DirectiveOccurrence? _lastConditionalString;

  @override
  void beginImport(Token importKeyword) {
    _inDirective = true;
    _currentKind = .import;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void endImport(Token? importKeyword, Token? semicolon) {
    _inDirective = false;
    _currentKind = null;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void beginExport(Token token) {
    _inDirective = true;
    _currentKind = .export;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    _inDirective = false;
    _currentKind = null;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void beginPart(Token token) {
    _inDirective = true;
    _currentKind = .part;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    _inDirective = false;
    _currentKind = null;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void beginPartOf(Token token) {
    _inDirective = true;
    _currentKind = .partOf;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void endPartOf(
    Token partKeyword,
    Token ofKeyword,
    Token semicolon,
    bool hasName,
  ) {
    _inDirective = false;
    _currentKind = null;
    _uriCaptured = false;
    _inConditionalUri = false;
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    _inConditionalUri = true;
    _lastConditionalString = null;
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    if (_lastConditionalString != null) {
      occurrences.add(_lastConditionalString!);
      _lastConditionalString = null;
    }
    _inConditionalUri = false;
  }

  @override
  void beginLiteralString(Token token) {
    if (!_inDirective ||
        _currentKind == null ||
        token.isSynthetic ||
        token.length == 0) {
      return;
    }

    final lexeme = token.lexeme;
    final unescaped = unescapeString(lexeme, token, this);

    final occurrence = DirectiveOccurrence(
      kind: _currentKind!,
      uri: unescaped,
      offset: token.offset,
      length: token.length,
      rawLexeme: lexeme,
    );

    if (_inConditionalUri) {
      // In conditional URIs, the final literal string in the construct is the
      // target URI.
      _lastConditionalString = occurrence;
    } else if (!_uriCaptured) {
      occurrences.add(occurrence);
      _uriCaptured = true;
    }
  }
}

/// Extracts all directive occurrences from Dart source [content].
List<DirectiveOccurrence> extractDirectives(String content) {
  final listener = DirectiveTokenListener();
  final parser = TopLevelParser(
    listener,
    experimentalFeatures: const DefaultExperimentalFeatures(),
  );
  final tokens = scanString(content).tokens;
  parser.parseUnit(tokens);
  return listener.occurrences;
}

/// Rewrites a literal string token lexeme with [newUri].
///
/// Preserves the original quotation format and raw string prefix.
String rewriteLexeme(String rawLexeme, String newUri) {
  final isRaw = rawLexeme.startsWith('r') || rawLexeme.startsWith('R');
  final withoutRaw = isRaw ? rawLexeme.substring(1) : rawLexeme;
  final quote = withoutRaw.startsWith("'''") || withoutRaw.startsWith('"""')
      ? withoutRaw.substring(0, 3)
      : (withoutRaw.isNotEmpty ? withoutRaw.substring(0, 1) : "'");
  final prefix = isRaw ? rawLexeme.substring(0, 1) : '';
  return '$prefix$quote$newUri$quote';
}

/// Rewrites the token for [directive] in [content] with [newUri].
String rewriteDirective(
  String content,
  DirectiveOccurrence directive,
  Uri newUri,
) => content.replaceRange(
  directive.offset,
  directive.offset + directive.length,
  rewriteLexeme(directive.rawLexeme, newUri.toString()),
);
