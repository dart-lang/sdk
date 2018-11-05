// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use Flutter TODO format: '
    '// TODO(username): message, https://URL-to-issue.';

const _details = r'''

**DO** Use Flutter TODO format.

**GOOD:**
```
// TODO(username): message.
// TODO(username): message, https://URL-to-issue.
```

''';

class FlutterStyleTodos extends LintRule implements NodeLintRuleWithContext {
  FlutterStyleTodos()
      : super(
            name: 'flutter_style_todos',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
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

  Iterable<CommentToken> _getPrecedingComments(Token token) sync* {
    CommentToken comment = token.precedingComments;
    while (comment != null) {
      yield comment;
      comment = comment.next;
    }
  }

  static final _todoRegExp = new RegExp(r'//+(.* )?TODO\b');
  static final _todoExpectedRegExp =
      new RegExp(r'// TODO\([a-zA-Z][-a-zA-Z0-9]*\): ');

  void _visitComment(CommentToken node) {
    final content = node.toString();
    if (content.startsWith(_todoRegExp) &&
        !content.startsWith(_todoExpectedRegExp)) {
      rule.reportLintForToken(node);
    }
  }
}
