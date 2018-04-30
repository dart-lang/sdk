// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Avoid returning this from methods just to enable a fluent interface.';

const _details = r'''

**AVOID** returning this from methods just to enable a fluent interface.

Returning `this` from a method is redundant; Dart has a cascade operator which
allows method chaining universally.

Returning `this` is allowed for:

- operators
- methods with a return type different of the current class
- methods defined in parent classes / mixins or interfaces

**BAD:**
```
var buffer = new StringBuffer()
  .write('one')
  .write('two')
  .write('three');
```

**GOOD:**
```
var buffer = new StringBuffer()
  ..write('one')
  ..write('two')
  ..write('three');
```

''';

bool _isFunctionExpression(AstNode node) => node is FunctionExpression;

bool _isReturnStatement(AstNode node) => node is ReturnStatement;

bool _returnsThis(AstNode node) =>
    (node as ReturnStatement).expression is ThisExpression;

class AvoidReturningThis extends LintRule implements NodeLintRule {
  AvoidReturningThis()
      : super(
            name: 'avoid_returning_this',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator) return;
    if (node.element.returnType !=
            (node.parent as ClassDeclaration).element?.type ||
        DartTypeUtilities.overridesMethod(node)) {
      return;
    }
    final body = node.body;
    if (body is BlockFunctionBody) {
      final returnStatements = DartTypeUtilities
          .traverseNodesInDFS(body.block,
              excludeCriteria: _isFunctionExpression)
          .where(_isReturnStatement);
      if (returnStatements.isNotEmpty && returnStatements.every(_returnsThis)) {
        rule.reportLint(node.name);
      }
    } else if (body is ExpressionFunctionBody) {
      if (body.expression is ThisExpression) {
        rule.reportLint(node.name);
      }
    }
  }
}
