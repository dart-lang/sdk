// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary null checks.';

const _details = r'''

Don't apply a null check when a nullable value is accepted.

**BAD:**
```dart
f(int? i);
m() {
  int? j;
  f(j!);
}

```

**GOOD:**
```dart
f(int? i);
m() {
  int? j;
  f(j);
}
```

''';

DartType? getExpectedType(PostfixExpression node) {
  var realNode =
      node.thisOrAncestorMatching((e) => e.parent is! ParenthesizedExpression);
  var parent = realNode?.parent;
  var withAwait = false;
  if (parent is AwaitExpression) {
    withAwait = true;
    parent = parent.parent;
  }

  // in return value
  if (parent is ReturnStatement || parent is ExpressionFunctionBody) {
    var parentExpression = parent?.thisOrAncestorOfType<FunctionExpression>();
    if (parentExpression == null) {
      return null;
    }
    var staticType = parentExpression.staticType;
    if (staticType is! FunctionType) {
      return null;
    }
    staticType = staticType.returnType;
    if (withAwait || parentExpression.body.keyword?.lexeme == 'async') {
      return staticType.isDartAsyncFuture || staticType.isDartAsyncFutureOr
          ? (staticType as ParameterizedType?)?.typeArguments.first
          : null;
    } else {
      return staticType;
    }
  }
  // in yield value
  if (parent is YieldStatement) {
    var parentExpression = parent.thisOrAncestorOfType<FunctionExpression>();
    if (parentExpression == null) {
      return null;
    }
    var staticType = parentExpression.staticType;
    if (staticType is! FunctionType) {
      return null;
    }
    staticType = staticType.returnType;
    return staticType.isDartCoreIterable || staticType.isDartAsyncStream
        ? (staticType as ParameterizedType).typeArguments.first
        : null;
  }
  // assignment
  if (parent is AssignmentExpression &&
      parent.operator.type == TokenType.EQ &&
      (parent.leftHandSide is! Identifier ||
          node.operand is! Identifier ||
          (parent.leftHandSide as Identifier).name !=
              (node.operand as Identifier).name)) {
    return parent.writeType;
  }
  // in variable declaration
  if (parent is VariableDeclaration) {
    return parent.declaredElement?.type;
  }
  // as right member of binary operator
  if (parent is BinaryExpression && parent.rightOperand == realNode) {
    var parentElement = parent.staticElement;
    if (parentElement == null) {
      return null;
    }
    return parentElement.parameters.first.type;
  }
  // as member of list
  if (parent is ListLiteral) {
    return (parent.staticType as ParameterizedType?)?.typeArguments.first;
  }
  // as member of set
  if (parent is SetOrMapLiteral && parent.isSet) {
    return (parent.staticType as ParameterizedType?)?.typeArguments.first;
  }
  // as member of map
  if (parent is MapLiteralEntry) {
    var typeParameters =
        (parent.parent! as SetOrMapLiteral).staticType as ParameterizedType?;
    return typeParameters?.typeArguments[parent.key == node ? 0 : 1];
  }
  // as parameter of function
  if (parent is NamedExpression) {
    realNode = parent;
    parent = parent.parent;
  }
  if (parent is ArgumentList && realNode is Expression) {
    return realNode.staticParameterElement?.type;
  }
  return null;
}

class UnnecessaryNullChecks extends LintRule {
  UnnecessaryNullChecks()
      : super(
            name: 'unnecessary_null_checks',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var expectedType = getExpectedType(node);
    if (expectedType != null && context.typeSystem.isNullable(expectedType)) {
      rule.reportLintForToken(node.operator);
    }
  }
}
