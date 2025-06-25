// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/token.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'Use case expressions that are valid in Dart 3.0.';

class InvalidCasePatterns extends LintRule {
  InvalidCasePatterns()
    : super(
        name: LintNames.invalid_case_patterns,
        description: _desc,
        state: const RuleState.experimental(),
      );

  // TODO(pq): update to add specific messages w/ specific corrections
  // https://github.com/dart-lang/linter/issues/4172
  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.invalid_case_patterns;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    // This lint rule is only meant for code which does not have 'patterns'
    // enabled.
    if (context.isFeatureEnabled(Feature.patterns)) return;

    var visitor = _Visitor(this);
    registry.addSwitchCase(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitSwitchCase(SwitchCase node) {
    var expression = node.expression.unParenthesized;
    if (expression is SetOrMapLiteral) {
      if (expression.constKeyword == null) {
        rule.reportAtNode(expression);
      }
    } else if (expression is ListLiteral) {
      if (expression.constKeyword == null) {
        rule.reportAtNode(expression);
      }
    } else if (expression is MethodInvocation) {
      if (expression.methodName.isDartCoreIdentifier(named: 'identical')) {
        rule.reportAtNode(expression);
      }
    } else if (expression is PrefixExpression) {
      if (expression.operand is! IntegerLiteral) {
        rule.reportAtNode(expression);
      }
    } else if (expression is BinaryExpression) {
      rule.reportAtNode(expression);
    } else if (expression is ConditionalExpression) {
      rule.reportAtNode(expression);
    } else if (expression is PropertyAccess) {
      if (expression.propertyName.isDartCoreIdentifier(named: 'length')) {
        rule.reportAtNode(expression);
      }
    } else if (expression is IsExpression) {
      rule.reportAtNode(expression);
    } else if (expression is InstanceCreationExpression) {
      if (expression.isConst && expression.keyword?.type != Keyword.CONST) {
        rule.reportAtNode(expression);
      }
    } else if (expression is SimpleIdentifier) {
      var token = expression.token;
      if (token is StringToken && token.lexeme == '_') {
        rule.reportAtNode(expression);
      }
    }
  }
}

extension on SimpleIdentifier {
  bool isDartCoreIdentifier({required String named}) {
    if (name != named) return false;
    var library = element?.library;
    return library != null && library.isDartCore;
  }
}
