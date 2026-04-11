// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Unnecessary `null` checks.';

/// Returns the "expected" type for [node], or `null` if an expected type
/// cannot be determined.
///
/// If [node] is the right side of an assignment, then `null` is returned,
/// unless [allowPromotable] is true, to avoid reporting code that
/// promotes a type.
DartType? getExpectedType(
  PostfixExpression node, {
  bool allowPromotable = false,
}) {
  var realNode = node.thisOrAncestorMatching(
    (e) => e.parent is! ParenthesizedExpression,
  );
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
    var leftHandSide = parent.leftHandSide;
    if (!allowPromotable && leftHandSide is Identifier) {
      // Do not return a type when the left side of an assignment is promotable.
      var element = leftHandSide.element;
      if (element is LocalVariableElement ||
          element is FormalParameterElement) {
        return null;
      }
      if (element is FieldElement && element.isPromotable) {
        return null;
      }
    }
    return parent.writeType;
  }
  // in variable declaration
  if (parent is VariableDeclaration) {
    var element = parent.declaredFragment?.element;
    return element?.type;
  }
  // as right member of binary operator
  if (parent is BinaryExpression && parent.rightOperand == realNode) {
    var parentElement = parent.element;
    if (parentElement == null) {
      return null;
    }
    return parentElement.formalParameters.first.type;
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
      var constructor = grandParent.constructorName.element;
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
    return realNode.correspondingParameter?.type;
  }
  return null;
}

class UnnecessaryNullChecks extends AnalysisRule {
  UnnecessaryNullChecks()
    : super(name: LintNames.unnecessary_null_checks, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryNullChecks;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addNullAssertPattern(this, visitor);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    var expectedType = node.matchedValueType;
    if (expectedType == null || !context.typeSystem.isNullable(expectedType)) {
      return;
    }
    // In declaration, for-each, and matching (switch case) contexts, the `!`
    // determines the static type of pattern-bound variables. Removing it would
    // widen their types to nullable, which changes program semantics (e.g.,
    // `final (X(n: v!)) = x` declares `v` as non-null; without `!`, `v`
    // would be nullable, which may make downstream uses of `v` ill-typed).
    var parent = node.parent;
    while (parent != null) {
      if (parent is PatternVariableDeclaration ||
          parent is ForEachPartsWithPattern ||
          parent is GuardedPattern) {
        return;
      }
      if (parent is PatternAssignment) {
        break;
      }
      parent = parent.parent;
    }
    rule.reportAtToken(node.operator);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var expectedType = getExpectedType(node);
    if (expectedType != null && context.typeSystem.isNullable(expectedType)) {
      rule.reportAtToken(node.operator);
    }
  }
}
