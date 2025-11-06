// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Use throwsA matcher instead of fail().';

class UseTestThrowsMatchers extends LintRule {
  UseTestThrowsMatchers()
    : super(name: LintNames.use_test_throws_matchers, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.useTestThrowsMatchers;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addTryStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isTestInvocation(Statement statement, String functionName) {
    if (statement is! ExpressionStatement) return false;
    var expression = statement.expression;
    if (expression is! MethodInvocation) return false;
    var element = expression.methodName.element;
    return element is TopLevelFunctionElement &&
        element.library.uri ==
            Uri.parse('package:test_api/src/frontend/expect.dart') &&
        element.name == functionName;
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.length != 1 || node.body.statements.isEmpty) return;

    var lastBodyStatement = node.body.statements.last;

    if (isTestInvocation(lastBodyStatement, 'fail') &&
        node.finallyBlock == null) {
      rule.reportAtNode(lastBodyStatement);
    }
  }
}
