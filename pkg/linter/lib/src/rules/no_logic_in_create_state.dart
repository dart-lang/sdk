// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/flutter_utils.dart';

const _desc = r"Don't put any logic in createState.";

class NoLogicInCreateState extends AnalysisRule {
  NoLogicInCreateState()
    : super(name: LintNames.no_logic_in_create_state, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.noLogicInCreateState;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'createState') {
      return;
    }

    var parent = node.parent;
    if (parent is! ClassDeclaration ||
        !isStatefulWidget(parent.declaredFragment?.element)) {
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
    } else if (expressionToTest is DotShorthandConstructorInvocation) {
      if (expressionToTest.argumentList.arguments.isEmpty) {
        return;
      }
    }

    rule.reportAtNode(expressionToTest ?? body);
  }
}
