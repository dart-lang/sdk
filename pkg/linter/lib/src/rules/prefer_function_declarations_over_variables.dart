// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Use a function declaration to bind a function to a name.';

class PreferFunctionDeclarationsOverVariables extends LintRule {
  PreferFunctionDeclarationsOverVariables()
    : super(
        name: LintNames.prefer_function_declarations_over_variables,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.prefer_function_declarations_over_variables;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer is FunctionExpression) {
      var function = node.thisOrAncestorOfType<FunctionBody>();
      if (function == null) {
        // When there is no enclosing function body, this is a variable
        // definition for a field or a top-level variable, which should only
        // be reported if final.
        if (node.isFinal) {
          rule.reportAtNode(node);
        }
      } else {
        var declaredElement = node.declaredElement;
        if (declaredElement != null &&
            !function.isPotentiallyMutatedInScope(declaredElement)) {
          rule.reportAtNode(node);
        }
      }
    }
  }
}
