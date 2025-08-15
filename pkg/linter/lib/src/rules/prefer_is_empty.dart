// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

const _desc = r'Use `isEmpty` for `Iterable`s and `Map`s.';

class PreferIsEmpty extends MultiAnalysisRule {
  PreferIsEmpty() : super(name: LintNames.prefer_is_empty, description: _desc);

  // TODO(brianwilkerson): Both `alwaysFalse` and `alwaysTrue` should be warnings
  //  rather than lints because they represent a bug rather than a style
  //  preference.
  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.preferIsEmptyAlwaysFalse,
    LinterLintCode.preferIsEmptyAlwaysTrue,
    LinterLintCode.preferIsEmptyUseIsEmpty,
    LinterLintCode.preferIsEmptyUseIsNotEmpty,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferIsEmpty rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // TODO(pq): not evaluating constants deliberately but we *should*.
    // see: https://github.com/dart-lang/linter/issues/2818
    var value = getIntValue(node.rightOperand, null);
    if (value != null) {
      if (_isLengthAccess(node.leftOperand)) {
        _check(node, value, constantOnRight: true);
      }
    } else {
      value = getIntValue(node.leftOperand, null);
      if (value != null) {
        if (_isLengthAccess(node.rightOperand)) {
          _check(node, value, constantOnRight: false);
        }
      }
    }
  }

  void _check(
    BinaryExpression expression,
    int value, {
    required bool constantOnRight,
  }) {
    // Don't lint if we're in a const constructor initializer.
    var constructorInitializer =
        expression.thisOrAncestorOfType<ConstructorInitializer>();
    if (constructorInitializer != null) {
      var constructorDecl = constructorInitializer.parent;
      if (constructorDecl is! ConstructorDeclaration ||
          constructorDecl.constKeyword != null) {
        return;
      }
    }

    // Or in a const context.
    // See: https://github.com/dart-lang/linter/issues/1719
    if (expression.inConstantContext) {
      return;
    }

    var operator = expression.operator;
    if (value == 0) {
      if (operator.type == TokenType.EQ_EQ ||
          operator.type == TokenType.LT_EQ) {
        rule.reportAtNode(
          expression,
          diagnosticCode: LinterLintCode.preferIsEmptyUseIsEmpty,
        );
      } else if (operator.type == TokenType.GT ||
          operator.type == TokenType.BANG_EQ) {
        rule.reportAtNode(
          expression,
          diagnosticCode: LinterLintCode.preferIsEmptyUseIsNotEmpty,
        );
      } else if (operator.type == TokenType.LT) {
        rule.reportAtNode(
          expression,
          diagnosticCode: LinterLintCode.preferIsEmptyAlwaysFalse,
        );
      } else if (operator.type == TokenType.GT_EQ) {
        rule.reportAtNode(
          expression,
          diagnosticCode: LinterLintCode.preferIsEmptyAlwaysTrue,
        );
      }
    } else if (value == 1) {
      if (constantOnRight) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator.type == TokenType.GT_EQ) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyUseIsNotEmpty,
          );
        } else if (operator.type == TokenType.LT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyUseIsEmpty,
          );
        }
      } else {
        // '1 <= length' is same as 'isNotEmpty',
        // and '1 > length' is same as 'isEmpty'
        if (operator.type == TokenType.LT_EQ) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyUseIsNotEmpty,
          );
        } else if (operator.type == TokenType.GT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyUseIsEmpty,
          );
        }
      }
    } else if (value < 0) {
      if (constantOnRight) {
        // 'length' is always >= 0, so comparing with negative makes no sense.
        if (operator.type == TokenType.EQ_EQ ||
            operator.type == TokenType.LT_EQ ||
            operator.type == TokenType.LT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyAlwaysFalse,
          );
        } else if (operator.type == TokenType.BANG_EQ ||
            operator.type == TokenType.GT_EQ ||
            operator.type == TokenType.GT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyAlwaysTrue,
          );
        }
      } else {
        // 'length' is always >= 0, so comparing with negative makes no sense.
        if (operator.type == TokenType.EQ_EQ ||
            operator.type == TokenType.GT_EQ ||
            operator.type == TokenType.GT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyAlwaysFalse,
          );
        } else if (operator.type == TokenType.BANG_EQ ||
            operator.type == TokenType.LT_EQ ||
            operator.type == TokenType.LT) {
          rule.reportAtNode(
            expression,
            diagnosticCode: LinterLintCode.preferIsEmptyAlwaysTrue,
          );
        }
      }
    }
  }

  // TODO(pq): consider sharing
  T? _drillDownTo<T extends Expression>(
    Expression expression, {
    required bool ignoreParens,
    required bool ignoreAs,
  }) {
    var search = expression;
    while (true) {
      if (ignoreParens && search is ParenthesizedExpression) {
        search = search.expression;
      } else if (ignoreAs && search is AsExpression) {
        search = search.expression;
      } else {
        break;
      }
    }

    return search is T ? search : null;
  }

  bool _isLengthAccess(Expression operand) {
    var node = _drillDownTo(operand, ignoreParens: true, ignoreAs: true);
    if (node == null) {
      return false;
    }

    SimpleIdentifier? identifier;
    InterfaceType? type;

    if (node is PrefixedIdentifier) {
      identifier = node.identifier;
      var operandType = node.prefix.staticType;
      if (operandType is InterfaceType) {
        type = operandType;
      }
    } else if (node is PropertyAccess) {
      identifier = node.propertyName;
      var parentType = node.target?.staticType;
      if (parentType is InterfaceType) {
        type = parentType;
      }
    }

    if (identifier?.name != 'length') {
      return false;
    }

    // Should be subtype of Iterable, Map or String.
    if (type == null ||
        !type.implementsInterface('Iterable', 'dart.core') &&
            !type.implementsInterface('Map', 'dart.core') &&
            !type.isDartCoreString) {
      return false;
    }

    return true;
  }
}
