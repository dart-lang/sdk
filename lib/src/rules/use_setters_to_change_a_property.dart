// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.use_setters_to_change_a_property;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Use a setter for operations that conceptually change a property.';

const _details = r'''

**DO** use a setter for operations that conceptually change a property.

**BAD:**
```
rectangle.setWidth(3);
button.setVisible(false);
```

**GOOD:**
```
rectangle.width = 3;
button.visible = false;
```

''';

bool _hasInheritedMethod(MethodDeclaration node) =>
    DartTypeUtilities.lookUpInheritedMethod(node) != null;

class UseSettersToChangeAProperty extends LintRule {
  _Visitor _visitor;
  UseSettersToChangeAProperty()
      : super(
            name: 'use_setters_to_change_a_property',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter ||
        node.isGetter ||
        _hasInheritedMethod(node) ||
        node.parameters?.parameters?.length != 1 ||
        node.returnType?.type?.name != 'void') {
      return;
    }
    void _visitExpression(Expression expression) {
      if (expression is AssignmentExpression) {
        final leftOperand = DartTypeUtilities
            .getCanonicalElementFromIdentifier(expression.leftHandSide);
        final rightOperand = DartTypeUtilities
            .getCanonicalElementFromIdentifier(expression.rightHandSide);
        final parameterElement =
            DartTypeUtilities.getCanonicalElementFromIdentifier(
                node.parameters.parameters.first.identifier);
        if (rightOperand == parameterElement && leftOperand is FieldElement) {
          rule.reportLint(node);
        }
      }
    }

    final body = node.body;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.first;
      if (statement is ExpressionStatement) {
        _visitExpression(statement.expression);
      }
    }
  }
}
