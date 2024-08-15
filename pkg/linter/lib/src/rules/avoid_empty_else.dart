// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid empty statements in else clauses.';

const _details = r'''
**AVOID** empty statements in the `else` clause of `if` statements.

**BAD:**
```dart
if (x > y)
  print('1');
else ;
  print('2');
```

If you want a statement that follows the empty clause to _conditionally_ run,
remove the dangling semicolon to include it in the `else` clause.
Optionally, also enclose the else's statement in a block.

**GOOD:**
```dart
if (x > y)
  print('1');
else
  print('2');
```

**GOOD:**
```dart
if (x > y) {
  print('1');
} else {
  print('2');
}
```

If you want a statement that follows the empty clause to _unconditionally_ run,
remove the `else` clause.

**GOOD:**
```dart
if (x > y) print('1');

print('2');
```
''';

class AvoidEmptyElse extends LintRule {
  AvoidEmptyElse()
      : super(
            name: 'avoid_empty_else',
            description: _desc,
            details: _details,
            categories: {
              LintRuleCategory.brevity,
              LintRuleCategory.errorProne
            });

  @override
  LintCode get lintCode => LinterLintCode.avoid_empty_else;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement is EmptyStatement &&
        !elseStatement.semicolon.isSynthetic) {
      rule.reportLint(elseStatement);
    }
  }
}
