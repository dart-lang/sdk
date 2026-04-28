// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
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

const _desc = "Don't use an explicit `const` in a generative enum constructor.";

class UnnecessaryConstInEnumConstructor extends AnalysisRule {
  UnnecessaryConstInEnumConstructor()
    : super(
        name: LintNames.unnecessary_const_in_enum_constructor,
        description: _desc,
      );

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryConstInEnumConstructor;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.primary_constructors)) {
      return;
    }
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var constKeyword = node.constKeyword;
    if (constKeyword != null) {
      rule.reportAtToken(constKeyword);
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var constKeyword = node.constKeyword;
    if (constKeyword != null) {
      rule.reportAtToken(constKeyword);
    }
  }
}
