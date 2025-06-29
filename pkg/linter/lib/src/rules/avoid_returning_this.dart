// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Avoid returning this from methods just to enable a fluent interface.';

bool _returnsThis(ReturnStatement node) => node.expression is ThisExpression;

class AvoidReturningThis extends LintRule {
  AvoidReturningThis()
    : super(name: LintNames.avoid_returning_this, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoid_returning_this;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  List<ReturnStatement> returnStatements = [];

  bool foundNonThisReturn = false;

  List<ReturnStatement> collectReturns(BlockFunctionBody body) {
    body.accept(this);
    return returnStatements;
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    // Short-circuit visiting on Function expressions.
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    // Short-circuit if we've encountered a non-this return.
    if (foundNonThisReturn) return;
    // Short-circuit if not returning this.
    if (!_returnsThis(node)) {
      foundNonThisReturn = true;
      returnStatements.clear();
      return;
    }
    returnStatements.add(node);
    super.visitReturnStatement(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator) return;

    var parent = node.parent;
    if (parent is ClassDeclaration ||
        parent is EnumDeclaration ||
        parent is MixinDeclaration) {
      if (node.isOverride) {
        return;
      }

      var returnType = node.declaredFragment?.element.returnType;
      if (returnType is InterfaceType &&
          returnType.element ==
              // ignore: cast_nullable_to_non_nullable
              (parent as Declaration).declaredFragment?.element) {
      } else {
        return;
      }
    } else {
      // Ignore Extensions.
      return;
    }

    var body = node.body;
    if (body is BlockFunctionBody) {
      var returnStatements = _BodyVisitor().collectReturns(body);
      if (returnStatements.isNotEmpty) {
        rule.reportAtNode(returnStatements.first.expression);
      }
    } else if (body is ExpressionFunctionBody) {
      if (body.expression is ThisExpression) {
        rule.reportAtToken(node.name);
      }
    }
  }
}
