// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid declaring parameters with `var` and no type annotation.';

class VarWithNoTypeAnnotation extends AnalysisRule {
  VarWithNoTypeAnnotation()
    : super(name: LintNames.var_with_no_type_annotation, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.varWithNoTypeAnnotation;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isFeatureEnabled(Feature.primary_constructors)) return;
    registry.addFormalParameterList(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var param in node.parameters) {
      // Super parameters and function typed parameters aren't included here.
      // A compile-time error is produced for those cases.
      var parameter = param;
      Token? keyword;
      TypeAnnotation? type;
      switch (parameter) {
        case RegularFormalParameter():
          if (parameter.functionTypedSuffix == null) {
            keyword = parameter.constFinalOrVarKeyword;
            type = parameter.type;
          }
        case FieldFormalParameter():
          keyword = parameter.constFinalOrVarKeyword;
          type = parameter.type;
        case _:
          continue;
      }
      if (keyword case var keyword?
          when keyword.lexeme == 'var' && type == null) {
        rule.reportAtToken(keyword);
      }
    }
  }
}
