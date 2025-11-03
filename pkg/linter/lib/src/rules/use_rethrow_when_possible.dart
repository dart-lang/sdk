// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use rethrow to rethrow a caught exception.';

class UseRethrowWhenPossible extends AnalysisRule {
  UseRethrowWhenPossible()
    : super(name: LintNames.use_rethrow_when_possible, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.useRethrowWhenPossible;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (node.parent is! ExpressionStatement) return;

    var element = node.expression.canonicalElement;
    if (element != null) {
      var catchClause = node.thisOrAncestorOfType<CatchClause>();
      var exceptionParameter =
          catchClause?.exceptionParameter?.declaredFragment?.element;
      if (element == exceptionParameter) {
        rule.reportAtNode(node);
      }
    }
  }
}
