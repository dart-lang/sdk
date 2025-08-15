// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid return types on setters.';

class AvoidReturnTypesOnSetters extends LintRule {
  AvoidReturnTypesOnSetters()
    : super(name: LintNames.avoid_return_types_on_setters, description: _desc);

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidReturnTypesOnSetters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportAtNode(node.returnType);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportAtNode(node.returnType);
      }
    }
  }
}
