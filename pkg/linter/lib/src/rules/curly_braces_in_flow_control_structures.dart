// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'DO use curly braces for all flow control structures.';

const _details = r'''
**DO** use curly braces for all flow control structures.

Doing so avoids the [dangling else](https://en.wikipedia.org/wiki/Dangling_else)
problem.

**BAD:**
```dart
if (overflowChars != other.overflowChars)
  return overflowChars < other.overflowChars;
```

**GOOD:**
```dart
if (isWeekDay) {
  print('Bike to work!');
} else {
  print('Go dancing or read a book!');
}
```

There is one exception to this: an `if` statement with no `else` clause where
the entire `if` statement and the then body all fit in one line. In that case,
you may leave off the braces if you prefer:

**GOOD:**
```dart
if (arg == null) return defaultValue;
```

If the body wraps to the next line, though, use braces:

**GOOD:**
```dart
if (overflowChars != other.overflowChars) {
  return overflowChars < other.overflowChars;
}
```

''';

class CurlyBracesInFlowControlStructures extends LintRule {
  static const LintCode code = LintCode(
      'curly_braces_in_flow_control_structures',
      'Statements in {0} should be enclosed in a block.',
      correctionMessage: 'Try wrapping the statement in a block.');

  CurlyBracesInFlowControlStructures()
      : super(
            name: 'curly_braces_in_flow_control_structures',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  bool get canUseParsedResult => true;

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

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    _check('a do', node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _check('a for', node.body);
  }

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement == null) {
      var parent = node.parent;
      if (parent is IfStatement && node == parent.elseStatement) {
        _check('an if', node.thenStatement);
        return;
      }
      if (node.thenStatement is Block) return;

      var unit = node.root as CompilationUnit;
      var lineInfo = unit.lineInfo;
      if (lineInfo.getLocation(node.rightParenthesis.end).lineNumber !=
          lineInfo.getLocation(node.thenStatement.end).lineNumber) {
        rule.reportLint(node.thenStatement, arguments: ['an if']);
      }
    } else {
      _check('an if', node.thenStatement);
      if (elseStatement is! IfStatement) {
        _check('an if', elseStatement);
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check('a while', node.body);
  }

  void _check(String where, Statement node) {
    if (node is! Block) rule.reportLint(node, arguments: [where]);
  }
}
