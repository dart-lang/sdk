// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Use a setter for operations that conceptually change a property.';

const _details = r'''
**DO** use a setter for operations that conceptually change a property.

**BAD:**
```dart
rectangle.setWidth(3);
button.setVisible(false);
```

**GOOD:**
```dart
rectangle.width = 3;
button.visible = false;
```

''';

class UseSettersToChangeProperties extends LintRule {
  static const LintCode code = LintCode('use_setters_to_change_properties',
      'The method is used to change a property.',
      correctionMessage: 'Try converting the method to a setter.');

  UseSettersToChangeProperties()
      : super(
            name: 'use_setters_to_change_properties',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter ||
        node.isGetter ||
        node.isOverride ||
        node.parameters?.parameters.length != 1 ||
        node.returnType?.type is! VoidType) {
      return;
    }

    void checkExpression(Expression expression) {
      if (expression is AssignmentExpression &&
          expression.operator.type == TokenType.EQ) {
        var leftOperand = expression.writeElement?.canonicalElement;
        var rightOperand = expression.rightHandSide.canonicalElement;
        var parameterElement = node.declaredElement?.parameters.first;
        if (rightOperand == parameterElement && leftOperand is FieldElement) {
          rule.reportLintForToken(node.name);
        }
      }
    }

    var body = node.body;
    if (body is BlockFunctionBody) {
      if (body.block.statements.length == 1) {
        var statement = body.block.statements.first;
        if (statement is ExpressionStatement) {
          checkExpression(statement.expression);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      checkExpression(body.expression);
    }
  }
}
