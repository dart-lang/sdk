// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r"Don't put any logic in createState.";

class NoLogicInCreateState extends LintRule {
  NoLogicInCreateState()
      : super(
          name: LintNames.no_logic_in_create_state,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.no_logic_in_create_state;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'createState') {
      return;
    }

    var parent = node.parent;
    if (parent is! ClassDeclaration ||
        !isStatefulWidget2(parent.declaredFragment?.element)) {
      return;
    }
    var body = node.body;
    Expression? expressionToTest;
    if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        var statement = statements.first;
        if (statement is ReturnStatement) {
          expressionToTest = statement.expression;
        }
      }
    } else if (body is ExpressionFunctionBody) {
      expressionToTest = body.expression;
    } else if (body is EmptyFunctionBody) {
      return;
    }

    if (expressionToTest is InstanceCreationExpression) {
      if (expressionToTest.argumentList.arguments.isEmpty) {
        return;
      }
    }
    rule.reportLint(expressionToTest ?? body);
  }
}
