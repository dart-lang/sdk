// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid `final` for parameter declarations.';

class AvoidFinalParameters extends LintRule {
  AvoidFinalParameters()
      : super(
          name: LintNames.avoid_final_parameters,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.prefer_final_parameters];

  @override
  LintCode get lintCode => LinterLintCode.avoid_final_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _reportApplicableParameters(node.parameters);

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _reportApplicableParameters(node.parameters);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _reportApplicableParameters(node.parameters);

  /// Report the lint for parameters in the [parameters] list that are final.
  void _reportApplicableParameters(FormalParameterList? parameters) {
    if (parameters != null) {
      for (var param in parameters.parameters) {
        if (param.isFinal) {
          rule.reportLint(param);
        }
      }
    }
  }
}
