// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use Flutter TODO format: '
    '// TODO(username): message, https://URL-to-issue.';

class FlutterStyleTodos extends LintRule {
  static final _todoRegExp = RegExp(r'//+\s*TODO\b', caseSensitive: false);

  static final RegExp _todoExpectedRegExp =
      RegExp(r'// TODO\([a-zA-Z0-9][-a-zA-Z0-9\.]*\): ');

  FlutterStyleTodos()
      : super(
          name: LintNames.flutter_style_todos,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.flutter_style_todos;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }

  /// Returns whether the given [content] is invalid and should trigger a lint.
  static bool invalidTodo(String content) =>
      content.startsWith(_todoRegExp) &&
      !content.startsWith(_todoExpectedRegExp);
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkComments(Token token) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      _checkComment(comment);
      comment = comment.next;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    Token? token = node.beginToken;
    while (token != null) {
      checkComments(token);
      if (token == token.next) break;
      token = token.next;
    }
  }

  void _checkComment(Token node) {
    var content = node.lexeme;
    if (FlutterStyleTodos.invalidTodo(content)) {
      rule.reportLintForToken(node);
    }
  }
}
