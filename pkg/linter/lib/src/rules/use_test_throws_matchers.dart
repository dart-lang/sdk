// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Use throwsA matcher instead of fail().';

class UseTestThrowsMatchers extends LintRule {
  UseTestThrowsMatchers()
      : super(
          name: LintNames.use_test_throws_matchers,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_test_throws_matchers;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
        element.library2.uri ==
            Uri.parse('package:test_api/src/frontend/expect.dart') &&
        element.name3 == functionName;
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.length != 1 || node.body.statements.isEmpty) return;

    var lastBodyStatement = node.body.statements.last;

    if (isTestInvocation(lastBodyStatement, 'fail') &&
        node.finallyBlock == null) {
      rule.reportLint(lastBodyStatement);
    }
  }
}
