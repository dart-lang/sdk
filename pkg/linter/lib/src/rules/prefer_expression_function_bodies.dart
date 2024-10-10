// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Use => for short members whose body is a single return statement.';

class PreferExpressionFunctionBodies extends LintRule {
  PreferExpressionFunctionBodies()
      : super(
          name: LintNames.prefer_expression_function_bodies,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_expression_function_bodies;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBlockFunctionBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    var statements = node.block.statements;
    if (statements.length != 1) return;

    var uniqueStatement = node.block.statements.single;
    if (uniqueStatement is! ReturnStatement) return;
    if (uniqueStatement.expression == null) return;

    rule.reportLint(node);
  }
}
