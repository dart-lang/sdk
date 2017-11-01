// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Separate the control structure expression from its statement.';

const _details = r'''

From the [flutter style guide](https://flutter.io/style-guide/):

**DO** separate the control structure expression from its statement.

Don't put the statement part of an `if`, `for`, `while`, `do` on the same line
as the expression, even if it is short.  Doing so makes it unclear that there
is relevant code there.  This is especially important for early returns.

**GOOD:**
```
if (notReady)
  return;

if (notReady)
  return;
else
  print('ok')

while (condition)
  i += 1;
```

**BAD:**
```
if (notReady) return;

if (notReady)
  return;
else print('ok')

while (condition) i += 1;
```

''';

class AlwaysPutControlBodyOnNewLine extends LintRule {
  AlwaysPutControlBodyOnNewLine()
      : super(
            name: 'always_put_control_body_on_new_line',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitIfStatement(IfStatement node) {
    _checkNodeOnNextLine(node.thenStatement, node.rightParenthesis.end);
    if (node.elseKeyword != null && node.elseStatement is! IfStatement)
      _checkNodeOnNextLine(node.elseStatement, node.elseKeyword.end);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  @override
  visitForStatement(ForStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  @override
  visitDoStatement(DoStatement node) {
    _checkNodeOnNextLine(node.body, node.doKeyword.end);
  }

  void _checkNodeOnNextLine(AstNode node, int controlEnd) {
    if (node is Block && node.statements.isEmpty) return;

    final unit = node.root as CompilationUnit;
    final offsetFirstStatement =
        node is Block ? node.statements.first.offset : node.offset;
    if (unit.lineInfo.getLocation(controlEnd).lineNumber ==
        unit.lineInfo.getLocation(offsetFirstStatement).lineNumber) {
      rule.reportLintForToken(node.beginToken);
    }
  }
}
