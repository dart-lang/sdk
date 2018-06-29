// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'AVOID lines longer than 80 characters.';

const _details = r'''

**AVOID** lines longer than 80 characters

Readability studies show that long lines of text are harder to read because your
eye has to travel farther when moving to the beginning of the next line. This is
why newspapers and magazines use multiple columns of text.

If you really find yourself wanting lines longer than 80 characters, our
experience is that your code is likely too verbose and could be a little more
compact. The main offender is usually `VeryLongCamelCaseClassNames`. Ask
yourself, “Does each word in that type name tell me something critical or
prevent a name collision?” If not, consider omitting it.

Note that dartfmt does 99% of this for you, but the last 1% is you. It does not
split long string literals to fit in 80 columns, so you have to do that
manually.

We make an exception for URIs and file paths. When those occur in comments or
strings (usually in imports and exports), they may remain on a single line even
if they go over the line limit. This makes it easier to search source files for
a given path.
''';

class LinesLongerThan80Chars extends LintRule implements NodeLintRule {
  LinesLongerThan80Chars()
      : super(
            name: 'lines_longer_than_80_chars',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final lineInfo = node.lineInfo;
    final lineCount = lineInfo.lineCount;
    final longLines = <_LineInfo>[];
    for (int i = 0; i < lineCount; i++) {
      final start = lineInfo.getOffsetOfLine(i);
      final end = i == lineCount - 1
          ? node.end
          : lineInfo.getOffsetOfLineAfter(start) - 1;
      final length = end - start;
      if (length > 80) {
        final line = new _LineInfo(index: i, offset: start, end: end);
        longLines.add(line);
      }
    }

    if (longLines.isEmpty) return;

    final allowedLineVisitor = new _AllowedLongLineVisitor(lineInfo);
    node.accept(allowedLineVisitor);
    final allowedCommentVisitor = new _AllowedCommentVisitor(lineInfo);
    node.accept(allowedCommentVisitor);

    final allowedLines = []
      ..addAll(allowedLineVisitor.allowedLines)
      ..addAll(allowedCommentVisitor.allowedLines);

    for (final line in longLines) {
      if (allowedLines.contains(line.index + 1)) continue;
      rule.reporter
          .reportErrorForOffset(rule.lintCode, line.offset, line.length);
    }
  }
}

class _LineInfo {
  _LineInfo({this.index, this.offset, this.end});
  final int index;
  final int offset;
  final int end;
  int get length => end - offset;
}

class _AllowedLongLineVisitor extends RecursiveAstVisitor {
  _AllowedLongLineVisitor(this.lineInfo);

  final LineInfo lineInfo;
  final allowedLines = <int>[];

  @override
  visitStringInterpolation(StringInterpolation node) {
    if (node.isMultiline) {
      _handleMultilines(node);
    } else {
      final value = node.elements.map((e) {
        if (e is InterpolationString) return e.value;
        if (e is InterpolationExpression) return ' ' * e.length;
      }).join();
      _handleSingleLine(node, value);
    }
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isMultiline)
      _handleMultilines(node);
    else
      _handleSingleLine(node, node.value);
  }

  _handleMultilines(SingleStringLiteral node) {
    final startLine = lineInfo.getLocation(node.offset).lineNumber;
    final endLine = lineInfo.getLocation(node.end).lineNumber;
    for (var i = startLine; i <= endLine; i++) {
      allowedLines.add(i);
    }
  }

  _handleSingleLine(AstNode node, String value) {
    if (_looksLikeUriOrPath(value)) {
      final line = lineInfo.getLocation(node.offset).lineNumber;
      allowedLines.add(line);
    }
  }
}

class _AllowedCommentVisitor extends SimpleAstVisitor {
  _AllowedCommentVisitor(this.lineInfo);

  final LineInfo lineInfo;
  final allowedLines = <int>[];

  @override
  visitCompilationUnit(CompilationUnit node) {
    var token = node.beginToken;
    while (token != null) {
      _getPrecedingComments(token).forEach(_visitComment);
      if (token == token.next) break;
      token = token.next;
    }
  }

  Iterable<CommentToken> _getPrecedingComments(Token token) sync* {
    CommentToken comment = token.precedingComments;
    while (comment != null) {
      yield comment;
      comment = comment.next;
    }
  }

  void _visitComment(CommentToken comment) {
    final content = comment.toString();
    final lines = [];
    if (content.startsWith('///')) {
      lines.add(content.substring(3));
    } else if (content.startsWith('//')) {
      lines.add(content.substring(2));
    } else if (content.startsWith('/*')) {
      // remove last slash before finding slash
      lines.addAll(content.substring(2, content.length - 2).split('\n'));
    }
    for (var i = 0; i < lines.length; i++) {
      final value = lines[i];
      if (_looksLikeUriOrPath(value)) {
        final line = lineInfo.getLocation(comment.offset).lineNumber + i;
        allowedLines.add(line);
      }
    }
  }
}

/// String looks like URI if it contains a slash or backslash.
final _uriRegExp = new RegExp(r'[/\\]');
bool _looksLikeUriOrPath(String value) => _uriRegExp.hasMatch(value);
