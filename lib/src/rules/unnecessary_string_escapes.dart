// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:meta/meta.dart';

import '../analyzer.dart';

const _desc = r'Remove unnecessary backslashes in strings.';

const _details = r'''

Remove unnecessary backslashes in strings.

**BAD:**
```
'this string contains 2 \"double quotes\" ';
"this string contains 2 \'single quotes\' ";
```

**GOOD:**
```
'this string contains 2 "double quotes" ';
"this string contains 2 'single quotes' ";
```

''';

class UnnecessaryStringEscapes extends LintRule implements NodeLintRule {
  UnnecessaryStringEscapes()
      : super(
            name: 'unnecessary_string_escapes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

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
        // TODO(a14n): should be the following line but the values look buggy
        // contentsOffset: element.contentsOffset,
        // contentsEnd: element.contentsEnd,
        contentsOffset: element.offset +
            (element != node.elements.first ? 0 : node.isMultiline ? 3 : 1),
        contentsEnd: element.end -
            (element != node.elements.last ? 0 : node.isMultiline ? 3 : 1),
      );
    }
  }

  void visitLexeme(
    Token token, {
    @required bool isSingleQuoted,
    @required bool isMultiline,
    @required int contentsOffset,
    @required int contentsEnd,
  }) {
    // For multiline string we keep the list on pending quotes.
    // Starting from 3 consecutive quotes, we allow escaping.
    // index -> escaped
    final pendingQuotes = <int, bool>{};
    void checkPendingQuotes() {
      if (isMultiline && pendingQuotes.length < 3) {
        final escapeIndexes =
            pendingQuotes.entries.where((e) => e.value).map((e) => e.key);
        for (var index in escapeIndexes) {
          // case for '''___\'''' : without last backslash it leads a parsing error
          if (contentsEnd != token.end && index + 2 == contentsEnd) continue;
          rule.reporter.reportErrorForOffset(rule.lintCode, index, 1);
        }
      }
    }

    final lexeme = token.lexeme
        .substring(contentsOffset - token.offset, contentsEnd - token.offset);
    for (var i = 0; i < lexeme.length; i++) {
      var current = lexeme[i];
      var escaped = false;
      if (current == r'\') {
        escaped = true;
        i += 1;
        current = lexeme[i];
        if (isSingleQuoted && current == '"' ||
            !isSingleQuoted && current == "'" ||
            !allowedEscapedChars.contains(current)) {
          rule.reporter
              .reportErrorForOffset(rule.lintCode, contentsOffset + i - 1, 1);
        }
      }
      if (isSingleQuoted ? current == "'" : current == '"') {
        pendingQuotes[contentsOffset + i - (escaped ? 1 : 0)] = escaped;
      } else {
        checkPendingQuotes();
        pendingQuotes.clear();
      }
    }
    checkPendingQuotes();
  }

  /// The special escaped chars listed in language specification
  static const allowedEscapedChars = [
    '"',
    "'",
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
}
