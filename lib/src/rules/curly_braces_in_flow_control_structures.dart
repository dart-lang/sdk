// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'DO use curly braces for all flow control structures.';

const _details = r'''

**DO** use curly braces for all flow control structures.

Doing so avoids the [dangling else](http://en.wikipedia.org/wiki/Dangling_else)
problem.

**GOOD:**
```
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
```
if (arg == null) return defaultValue;
```

If the body wraps to the next line, though, use braces:

**GOOD:**
```
if (overflowChars != other.overflowChars) {
  return overflowChars < other.overflowChars;
}
```

**BAD:**
```dart
if (overflowChars != other.overflowChars)
  return overflowChars < other.overflowChars;
```
''';

class CurlyBracesInFlowControlStructures extends LintRule
    implements NodeLintRule {
  CurlyBracesInFlowControlStructures()
      : super(
            name: 'curly_braces_in_flow_control_structures',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
    _check(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _check(node.body);
  }

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement == null) {
      if (node.thenStatement is Block) return;

      final unit = node.root as CompilationUnit;
      if (unit.lineInfo.getLocation(node.rightParenthesis.end).lineNumber !=
          unit.lineInfo.getLocation(node.thenStatement.end).lineNumber) {
        rule.reportLint(node.thenStatement);
      }
    } else {
      _check(node.thenStatement);
      if (elseStatement is! IfStatement) {
        _check(elseStatement);
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check(node.body);
  }

  void _check(Statement node) {
    if (node is! Block) rule.reportLint(node);
  }
}
