// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid `double` and `int` checks.';

class AvoidDoubleAndIntChecks extends LintRule {
  AvoidDoubleAndIntChecks()
    : super(name: LintNames.avoid_double_and_int_checks, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidDoubleAndIntChecks;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement is IfStatement) {
      var ifCondition = node.expression;
      var elseCondition = elseStatement.expression;
      if (ifCondition is IsExpression && elseCondition is IsExpression) {
        var typeProvider = context.typeProvider;
        var ifExpression = ifCondition.expression;
        var elseIsExpression = elseCondition.expression;
        if (ifExpression is SimpleIdentifier &&
            elseIsExpression is SimpleIdentifier &&
            ifExpression.name == elseIsExpression.name &&
            ifCondition.type.type == typeProvider.doubleType &&
            elseCondition.type.type == typeProvider.intType &&
            (ifExpression.element is FormalParameterElement ||
                ifExpression.element is LocalVariableElement)) {
          rule.reportAtNode(elseCondition);
        }
      }
    }
  }
}
