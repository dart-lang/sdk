// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = "Avoid switch statements on a 'Type'.";

const _objectToStringName = 'toString';

class SwitchOnType extends AnalysisRule {
  new() : super(name: LintNames.switch_on_type, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.switchOnType;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.patterns)) return;
    var visitor = _Visitor(this, context);
    registry.addSwitchExpression(this, visitor);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  new(this.rule, this.context);

  /// A reference to the [Type] type.
  ///
  /// This is used to check if the type of the expression is assignable to
  /// [Type].
  ///
  /// This shortens the code and avoids multiple calls to
  /// `context.typeProvider.typeType`.
  InterfaceType get _typeType => context.typeProvider.typeType;

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _processExpression(node.expression, errorNode: node.expression);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _processExpression(node.expression, errorNode: node.expression);
  }

  /// Returns `true` if the [type] is assignable to [Type].
  bool _isAssignableToType(DartType? type) {
    if (type == null || type is DynamicType) return false;
    return context.typeSystem.isAssignableTo(type, _typeType);
  }

  /// Processes the [expression] of a [SwitchStatement] or [SwitchExpression].
  ///
  /// Returns `true` if the lint was reportred and `false` otherwise.
  bool _processExpression(
    Expression expression, {
    required Expression errorNode,
  }) {
    if (expression case StringInterpolation(:var elements)) {
      return _processInterpolation(elements, errorNode: errorNode);
    }
    if (expression case ConditionalExpression(
      :var thenExpression,
      :var elseExpression,
    )) {
      return _processExpression(thenExpression, errorNode: errorNode) ||
          _processExpression(elseExpression, errorNode: errorNode);
    }

    if (expression case SwitchExpression(:var cases)) {
      for (var caseClause in cases) {
        if (_processExpression(caseClause.expression, errorNode: errorNode)) {
          return true;
        }
      }
      return false;
    }

    if (expression
        case BinaryExpression(
          :var leftOperand,
          :var rightOperand,
          :var operator,
        )
        when operator.lexeme == TokenType.PLUS.lexeme) {
      return _processExpression(leftOperand, errorNode: errorNode) ||
          _processExpression(rightOperand, errorNode: errorNode);
    }

    var type = switch (expression) {
      PrefixedIdentifier(:var identifier) => identifier.staticType,
      PropertyAccess(:var propertyName) => propertyName.staticType,
      SimpleIdentifier(:var staticType) => staticType,
      TypeLiteral(:var staticType) => staticType,
      MethodInvocation(:var methodName, :var realTarget?) =>
        methodName.element.isToStringMethod ? realTarget.staticType : null,
      _ => null,
    };

    if (_isAssignableToType(type)) {
      rule.reportAtNode(errorNode);
      return true;
    }
    return false;
  }

  /// Processes the [elements] of an [InterpolationExpression].
  ///
  /// Returns `true` if the lint was reported and `false` otherwise.
  bool _processInterpolation(
    NodeList<InterpolationElement> elements, {
    required Expression errorNode,
  }) {
    for (var element in elements) {
      switch (element) {
        case InterpolationExpression(:var expression):
          var reported = _processExpression(expression, errorNode: errorNode);

          // This return is necessary to avoid reporting multiple times.
          if (reported) {
            return true;
          }
        case InterpolationString():
          break;
      }
    }
    return false;
  }
}

extension on Element? {
  /// Returns `true` if this element is the `toString` method.
  bool get isToStringMethod {
    var self = this;
    return self is MethodElement && self.name == _objectToStringName;
  }
}
