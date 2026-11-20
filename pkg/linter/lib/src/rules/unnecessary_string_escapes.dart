// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Remove unnecessary backslashes in strings.';

class UnnecessaryStringEscapes extends AnalysisRule {
  new() : super(name: LintNames.unnecessary_string_escapes, description: _desc);

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryStringEscapes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor(final AnalysisRule rule) extends SimpleAstVisitor<void> {
  /// Escape characters valid for either quote delimiter.
  static const allowedEscapedChars = [
    r'$',
    r'\',
    'n',
    'r',
    'f',
    'b',
    't',
    'v',
    'x',
    'u',
  ];

  void visitLexeme(
    Token token, {
    required bool isSingleQuoted,
    required bool isMultiline,
    required int contentsOffset,
    required int contentsEnd,
  }) {
    var text = token.lexeme;
    var start = contentsOffset - token.offset;
    var end = contentsEnd - token.offset;
    var quote = isSingleQuoted ? "'" : '"';
    // Skip both characters of each escape so an escaped backslash is consumed.
    for (
      var i = text.indexOf(r'\');
      i >= 0 && i + 1 < end;
      i = text.indexOf(r'\', i + 2)
    ) {
      var character = text[i + 1];
      if (character == quote) {
        if (!isMultiline ||
            _needsQuoteEscape(
              text,
              quote,
              i,
              contentStart: start,
              contentEnd: end,
            )) {
          continue;
        }
      } else if (allowedEscapedChars.contains(character)) {
        continue;
      }
      rule.reportAtOffset(token.offset + i, 1);
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw) return;

    visitLexeme(
      node.literal,
      isSingleQuoted: node.isSingleQuoted,
      isMultiline: node.isMultiline,
      contentsOffset: node.contentsOffset,
      contentsEnd: node.contentsEnd,
    );
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    for (var element in node.elements.whereType<InterpolationString>()) {
      visitLexeme(
        element.contents,
        isSingleQuoted: node.isSingleQuoted,
        isMultiline: node.isMultiline,
        contentsOffset: element.contentsOffset,
        contentsEnd: element.contentsEnd,
      );
    }
  }

  static bool _needsQuoteEscape(
    String text,
    String quote,
    int escape, {
    required int contentStart,
    required int contentEnd,
  }) {
    // A quote immediately before the closing delimiter must stay escaped.
    if (escape + 2 == contentEnd && contentEnd < text.length) return true;

    // Three consecutive matching quotes could close the multiline string.
    // Count both escaped and unescaped neighbors of this quote.
    var count = 1;
    for (var i = escape - 1; i >= contentStart && text[i] == quote; i--) {
      if (++count == 3) return true;
      if (i > contentStart && text[i - 1] == r'\') i--;
    }
    for (var i = escape + 2; i < contentEnd; i++) {
      if (text[i] == r'\') i++;
      if (i >= contentEnd || text[i] != quote) break;
      if (++count == 3) return true;
    }
    return false;
  }
}
