// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use Flutter TODO format: '
    '// TODO(username): message, https://URL-to-issue.';

const _details = r'''

**DO** Use Flutter TODO format.

From the [Flutter docs](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#comments):

> TODOs should include the string TODO in all caps, followed by the GitHub username of the person with the best context about the problem referenced by the TODO in parenthesis. A TODO is not a commitment that the person referenced will fix the problem, it is intended to be the person with enough context to explain the problem. Thus, when you create a TODO, it is almost always your username that is given.

**GOOD:**
```
// TODO(username): message.
// TODO(username): message, https://URL-to-issue.
```

''';

class FlutterStyleTodos extends LintRule implements NodeLintRule {
  FlutterStyleTodos()
      : super(
            name: 'flutter_style_todos',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static final _todoRegExp = RegExp(r'//+(.* )?TODO\b');

  static final _todoExpectedRegExp =
      RegExp(r'// TODO\([a-zA-Z][-a-zA-Z0-9]*\): ');

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var token = node.beginToken;
    while (token != null) {
      _getPrecedingComments(token).forEach(_visitComment);
      if (token == token.next) break;
      token = token.next;
    }
  }

  Iterable<Token> _getPrecedingComments(Token token) sync* {
    Token comment = token.precedingComments;
    while (comment != null) {
      yield comment;
      comment = comment.next;
    }
  }

  void _visitComment(Token node) {
    final content = node.lexeme;
    if (content.startsWith(_todoRegExp) &&
        !content.startsWith(_todoExpectedRegExp)) {
      rule.reportLintForToken(node);
    }
  }
}
