// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use case expressions that are valid in Dart 3.0.';

class InvalidCasePatterns extends LintRule {
  InvalidCasePatterns()
      : super(
          name: LintNames.invalid_case_patterns,
          description: _desc,
          state: State.experimental(),
        );

  // TODO(pq): update to add specific messages w/ specific corrections
  // https://github.com/dart-lang/linter/issues/4172
  @override
  LintCode get lintCode => LinterLintCode.invalid_case_patterns;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    // This lint rule is only meant for code which does not have 'patterns'
    // enabled.
    if (context.isEnabled(Feature.patterns)) return;

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
        rule.reportLint(expression);
      }
    } else if (expression is ListLiteral) {
      if (expression.constKeyword == null) {
        rule.reportLint(expression);
      }
    } else if (expression is MethodInvocation) {
      if (expression.methodName.isDartCoreIdentifier(named: 'identical')) {
        rule.reportLint(expression);
      }
    } else if (expression is PrefixExpression) {
      if (expression.operand is! IntegerLiteral) {
        rule.reportLint(expression);
      }
    } else if (expression is BinaryExpression) {
      rule.reportLint(expression);
    } else if (expression is ConditionalExpression) {
      rule.reportLint(expression);
    } else if (expression is PropertyAccess) {
      if (expression.propertyName.isDartCoreIdentifier(named: 'length')) {
        rule.reportLint(expression);
      }
    } else if (expression is IsExpression) {
      rule.reportLint(expression);
    } else if (expression is InstanceCreationExpression) {
      if (expression.isConst && expression.keyword?.type != Keyword.CONST) {
        rule.reportLint(expression);
      }
    } else if (expression is SimpleIdentifier) {
      var token = expression.token;
      if (token is StringToken && token.lexeme == '_') {
        rule.reportLint(expression);
      }
    }
  }
}

extension on SimpleIdentifier {
  bool isDartCoreIdentifier({required String named}) {
    if (name != named) return false;
    var library = element?.library2;
    return library != null && library.isDartCore;
  }
}
