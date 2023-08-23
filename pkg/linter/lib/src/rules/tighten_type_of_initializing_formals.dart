// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Tighten type of initializing formal.';

const _details = r'''
Tighten the type of an initializing formal if a non-null assert exists. This
allows the type system to catch problems rather than have them only be caught at
run-time.

**BAD:**
```dart
class A {
  A.c1(this.p) : assert(p != null);
  A.c2(this.p);
  final String? p;
}
```

**GOOD:**
```dart
class A {
  A.c1(String this.p);
  A.c2(this.p);
  final String? p;
}

class B {
  String? b;
  B(this.b);
}

class C extends B {
  B(String super.b);
}
```
''';

class TightenTypeOfInitializingFormals extends LintRule {
  static const LintCode code = LintCode('tighten_type_of_initializing_formals',
      "Use a type annotation rather than 'assert' to enforce non-nullability.",
      correctionMessage:
          "Try adding a type annotation and removing the 'assert'.");

  TightenTypeOfInitializingFormals()
      : super(
          name: 'tighten_type_of_initializing_formals',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) {
      return;
    }

    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers) {
      if (initializer is! AssertInitializer) continue;

      var condition = initializer.condition;
      if (condition is! BinaryExpression) continue;

      if (condition.operator.type == TokenType.BANG_EQ) {
        if (condition.rightOperand is NullLiteral) {
          var leftOperand = condition.leftOperand;
          if (leftOperand is Identifier) {
            var staticType = leftOperand.staticType;
            if (staticType != null &&
                context.typeSystem.isNullable(staticType)) {
              _check(leftOperand.staticElement, node);
            }
          }
        } else if (condition.leftOperand is NullLiteral) {
          var rightOperand = condition.rightOperand;
          if (rightOperand is Identifier) {
            var staticType = rightOperand.staticType;
            if (staticType != null &&
                context.typeSystem.isNullable(staticType)) {
              _check(rightOperand.staticElement, node);
            }
          }
        }
      }
    }
  }

  void _check(Element? element, ConstructorDeclaration node) {
    if (element is FieldFormalParameterElement ||
        element is SuperFormalParameterElement) {
      rule.reportLint(node.parameters.parameters
          .firstWhere((p) => p.declaredElement == element));
    }
  }
}
