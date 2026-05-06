// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid `final` for parameter declarations.';

class AvoidFinalParameters extends AnalysisRule {
  AvoidFinalParameters()
    : super(name: LintNames.avoid_final_parameters, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.avoidFinalParameters;

  @override
  List<String> get incompatibleRules => const [
    LintNames.prefer_final_parameters,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // This lint isn't relevant with primary constructors enabled
    // as `final` is no longer used to indicate a parameter is final,
    // but rather as a declaring parameter in a primary constructor.
    if (context.isFeatureEnabled(Feature.primary_constructors)) return;
    registry.addFormalParameterList(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    // A compile-time error is already reported on `GenericFunctionType`s that
    // have any parameters marked `final`.
    if (node.parent is GenericFunctionType) return;

    for (var param in node.parameters) {
      if (param.finalKeyword case var finalKeyword?) {
        if (param.functionTypedSuffix != null) continue;
        if (param is FieldFormalParameter) continue;
        if (param is SuperFormalParameter) continue;
        rule.reportAtToken(finalKeyword);
      }
    }
  }
}
