// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid returning `null` for `void`.';

class AvoidReturningNullForVoid extends MultiAnalysisRule {
  AvoidReturningNullForVoid()
    : super(name: LintNames.avoid_returning_null_for_void, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.avoid_returning_null_for_void_from_function,
    LinterLintCode.avoid_returning_null_for_void_from_method,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addExpressionFunctionBody(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _visit(node, node.expression);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression case var nodeExpression?) {
      _visit(node, nodeExpression);
    }
  }

  void _visit(AstNode node, Expression expression) {
    if (expression is! NullLiteral) return;

    var parent = node.thisOrAncestorMatching(
      (e) => e is FunctionExpression || e is MethodDeclaration,
    );
    if (parent == null) return;

    var (type, isAsync, code) = switch (parent) {
      FunctionExpression() => (
        parent.declaredFragment?.element.returnType,
        parent.body.isAsynchronous,
        LinterLintCode.avoid_returning_null_for_void_from_function,
      ),
      MethodDeclaration() => (
        parent.declaredFragment?.element.returnType,
        parent.body.isAsynchronous,
        LinterLintCode.avoid_returning_null_for_void_from_method,
      ),
      _ => throw StateError('Unexpected type'),
    };
    if (type == null) return;

    if (!isAsync && type is VoidType) {
      rule.reportAtNode(node, diagnosticCode: code);
    } else if (isAsync &&
        type.isDartAsyncFuture &&
        (type as InterfaceType).typeArguments.first is VoidType) {
      rule.reportAtNode(node, diagnosticCode: code);
    }
  }
}
