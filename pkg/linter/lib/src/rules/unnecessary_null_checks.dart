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
**DON'T** apply a null check when a nullable value is accepted.

**BAD:**
```dart
f(int? i) {}
m() {
  int? j;
  f(j!);
}

```

**GOOD:**
```dart
f(int? i) {}
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
  var withAwait = parent is AwaitExpression;
  if (withAwait) {
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
    var grandParent = parent.parent;
    while (true) {
      if (grandParent is ForElement) {
        grandParent = grandParent.parent;
      } else if (grandParent is IfElement) {
        grandParent = grandParent.parent;
      } else if (grandParent is SetOrMapLiteral) {
        var type = grandParent.staticType as InterfaceType?;
        return type?.typeArguments[parent.key == node ? 0 : 1];
      } else {
        return null;
      }
    }
  }
  // as parameter of function
  if (parent is NamedExpression) {
    realNode = parent;
    parent = parent.parent;
  }
  if (parent is ArgumentList && realNode is Expression) {
    var grandParent = parent.parent;
    if (grandParent is InstanceCreationExpression) {
      var constructor = grandParent.constructorName.staticElement;
      if (constructor != null) {
        if (constructor.returnType.isDartAsyncFuture &&
            constructor.name == 'value') {
          return null;
        }
      }
    } else if (grandParent is MethodInvocation) {
      var targetType = grandParent.realTarget?.staticType;
      if (targetType is InterfaceType) {
        var targetClass = targetType.element;

        if (targetClass.library.isDartAsync &&
            targetClass.name == 'Completer' &&
            grandParent.methodName.name == 'complete') {
          return null;
        }
      }
    }
    return realNode.staticParameterElement?.type;
  }
  return null;
}

class UnnecessaryNullChecks extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_null_checks', "Unnecessary use of a null check ('!').",
      correctionMessage: 'Try removing the null check.');

  UnnecessaryNullChecks()
      : super(
            name: 'unnecessary_null_checks',
            description: _desc,
            details: _details,
            state: State.experimental(),
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addNullAssertPattern(this, visitor);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    var expectedType = node.matchedValueType;
    if (expectedType != null && context.typeSystem.isNullable(expectedType)) {
      rule.reportLintForToken(node.operator);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var expectedType = getExpectedType(node);
    if (expectedType != null && context.typeSystem.isNullable(expectedType)) {
      rule.reportLintForToken(node.operator);
    }
  }
}
