// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/extensions.dart'; //ignore: implementation_imports
import 'package:pub_semver/pub_semver.dart' show Version;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r'Prefer final for parameter declarations if they are not reassigned.';

class PreferFinalParameters extends AnalysisRule {
  PreferFinalParameters()
    : super(
        name: LintNames.prefer_final_parameters,
        description: _desc,
        state: RuleState.deprecated(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.preferFinalParameters;

  @override
  List<String> get incompatibleRules => const [
    LintNames.unnecessary_final,
    LintNames.avoid_final_parameters,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // This lint isn't relevant with primary constructors enabled
    // as `final` is no longer used to indicate a parameter is final,
    // but rather as a declaring parameter in a primary constructor.
    if (context.isFeatureEnabled(Feature.declaring_constructors)) return;

    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

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
    FormalParameterList? parameters,
    FunctionBody body,
  ) {
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
            !body.isPotentiallyMutatedInScope(declaredElement)) {
          rule.reportAtNode(param, arguments: [param.name!.lexeme]);
        }
      }
    }
  }
}
