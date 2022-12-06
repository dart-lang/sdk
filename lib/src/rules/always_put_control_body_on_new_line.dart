// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Separate the control structure expression from its statement.';

const _details = r'''
From the [style guide for the flutter repo](https://flutter.dev/style-guide/):

**DO** separate the control structure expression from its statement.

Don't put the statement part of an `if`, `for`, `while`, `do` on the same line
as the expression, even if it is short.  Doing so makes it unclear that there
is relevant code there.  This is especially important for early returns.

**BAD:**
```dart
if (notReady) return;

if (notReady)
  return;
else print('ok')

while (condition) i += 1;
```

**GOOD:**
```dart
if (notReady)
  return;

if (notReady)
  return;
else
  print('ok')

while (condition)
  i += 1;
```

Note that this rule can conflict with the
[Dart formatter](https://dart.dev/tools/dart-format), and should not be enabled
when the Dart formatter is used.

''';

class AlwaysPutControlBodyOnNewLine extends LintRule {
  static const LintCode code = LintCode('always_put_control_body_on_new_line',
      'Statement should be on a separate line.',
      correctionMessage: 'Try moving the statement to a new line.');

  AlwaysPutControlBodyOnNewLine()
      : super(
            name: 'always_put_control_body_on_new_line',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    _checkNodeOnNextLine(node.body, node.doKeyword.end);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _checkNodeOnNextLine(node.thenStatement, node.rightParenthesis.end);
    var elseKeyword = node.elseKeyword;
    var elseStatement = node.elseStatement;
    if (elseKeyword != null && elseStatement is! IfStatement) {
      _checkNodeOnNextLine(elseStatement, elseKeyword.end);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  void _checkNodeOnNextLine(AstNode? node, int controlEnd) {
    if (node == null || node is Block && node.statements.isEmpty) return;

    var unit = node.root as CompilationUnit;
    var offsetFirstStatement =
        node is Block ? node.statements.first.offset : node.offset;
    var lineInfo = unit.lineInfo;
    if (lineInfo.getLocation(controlEnd).lineNumber ==
        lineInfo.getLocation(offsetFirstStatement).lineNumber) {
      rule.reportLintForToken(node.beginToken);
    }
  }
}
