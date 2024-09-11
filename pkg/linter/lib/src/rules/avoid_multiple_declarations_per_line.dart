// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't declare multiple variables on a single line.";

const _details = r'''
**DON'T** declare multiple variables on a single line.

**BAD:**
```dart
String? foo, bar, baz;
```

**GOOD:**
```dart
String? foo;
String? bar;
String? baz;
```

''';

class AvoidMultipleDeclarationsPerLine extends LintRule {
  AvoidMultipleDeclarationsPerLine()
      : super(
          name: 'avoid_multiple_declarations_per_line',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_multiple_declarations_per_line;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var parent = node.parent;
    if (parent is ForPartsWithDeclarations && parent.variables == node) return;

    var variables = node.variables;
    if (variables.length > 1) {
      var secondVariable = variables[1];
      rule.reportLintForToken(secondVariable.name);
    }
  }
}
