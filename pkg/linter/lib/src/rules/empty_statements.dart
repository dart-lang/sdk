// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid empty statements.';

const _details = r'''
**AVOID** empty statements.

Empty statements almost always indicate a bug.

For example,

**BAD:**
```dart
if (complicated.expression.foo());
  bar();
```

Formatted with `dart format` the bug becomes obvious:

```dart
if (complicated.expression.foo()) ;
bar();

```

Better to avoid the empty statement altogether.

**GOOD:**
```dart
if (complicated.expression.foo())
  bar();
```

''';

class EmptyStatements extends LintRule {
  static const LintCode code = LintCode(
      'empty_statements', 'Unnecessary empty statement.',
      correctionMessage:
          'Try removing the empty statement or restructuring the code.');

  EmptyStatements()
      : super(
            name: 'empty_statements',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addEmptyStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool definesSemantics(EmptyStatement node) {
    var parent = node.parent;
    if (parent is! SwitchPatternCase) return false;

    var statements = parent.statements;
    if (statements.last != node) return false;

    for (var statement in statements) {
      if (statement is! EmptyStatement) return false;
    }

    return true;
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    if (definesSemantics(node)) return;
    rule.reportLint(node);
  }
}
