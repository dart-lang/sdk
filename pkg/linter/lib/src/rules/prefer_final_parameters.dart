// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/element/extensions.dart'; //ignore: implementation_imports

import '../analyzer.dart';

const _desc =
    r'Prefer final for parameter declarations if they are not reassigned.';

class PreferFinalParameters extends LintRule {
  PreferFinalParameters()
      : super(
          name: LintNames.prefer_final_parameters,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules =>
      const [LintNames.unnecessary_final, LintNames.avoid_final_parameters];

  @override
  LintCode get lintCode => LinterLintCode.prefer_final_parameters;

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
      _reportApplicableParameters(node.parameters, node.body);

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _reportApplicableParameters(node.parameters, node.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _reportApplicableParameters(node.parameters, node.body);

  /// Report the lint for parameters in the [parameters] list that are not
  /// const or final already and not potentially mutated in the function [body].
  void _reportApplicableParameters(
      FormalParameterList? parameters, FunctionBody body) {
    if (parameters != null) {
      for (var param in parameters.parameters) {
        if (param is DefaultFormalParameter) {
          param = param.parameter;
        }
        if (param.isFinal ||
            param.isConst ||
            // A field formal parameter is final even without the `final`
            // modifier.
            param is FieldFormalParameter ||
            // A super formal parameter is final even without the `final`
            // modifier.
            param is SuperFormalParameter) {
          continue;
        }
        var declaredElement = param.declaredFragment?.element;
        if (declaredElement != null &&
            !declaredElement.isInitializingFormal &&
            !declaredElement.isWildcardVariable &&
            !body.isPotentiallyMutatedInScope2(declaredElement)) {
          rule.reportLint(param, arguments: [param.name!.lexeme]);
        }
      }
    }
  }
}
