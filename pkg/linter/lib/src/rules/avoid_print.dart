// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'Avoid `print` calls in production code.';

class AvoidPrint extends LintRule {
  AvoidPrint() : super(name: LintNames.avoid_print, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidPrint;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if ((node.methodName.element?.isDartCorePrint ?? false) &&
        !_isDebugOnly(node)) {
      rule.reportAtNode(node.methodName);
    }

    node.argumentList.arguments.forEach(_validateArgument);
  }

  bool _isDebugOnly(Expression expression) {
    AstNode? node = expression;
    while (node != null) {
      var parent = node.parent;
      if (parent is IfStatement && node == parent.thenStatement) {
        var condition = parent.expression;
        if (condition is SimpleIdentifier && isKDebugMode(condition.element)) {
          return true;
        }
      } else if (parent is FunctionBody) {
        return false;
      }
      node = parent;
    }
    return false;
  }

  void _validateArgument(Expression expression) {
    if (expression is SimpleIdentifier) {
      var element = expression.element;
      if (element.isDartCorePrint) {
        rule.reportAtNode(expression);
      }
    }
  }
}
