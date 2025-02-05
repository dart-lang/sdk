// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid single cascade in expression statements.';

class AvoidSingleCascadeInExpressionStatements extends LintRule {
  AvoidSingleCascadeInExpressionStatements()
      : super(
          name: LintNames.avoid_single_cascade_in_expression_statements,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_single_cascade_in_expression_statements;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCascadeExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  String operatorFor(Expression section) {
    Token? operator;
    if (section is PropertyAccess) {
      operator = section.operator;
    } else if (section is MethodInvocation) {
      operator = section.operator;
    }
    if (operator?.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      return '?.';
    }
    return '.';
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    var sections = node.cascadeSections;
    if (sections.length == 1 && node.parent is ExpressionStatement) {
      var operator = operatorFor(sections[0]);
      rule.reportLint(node, arguments: [operator]);
    }
  }
}
