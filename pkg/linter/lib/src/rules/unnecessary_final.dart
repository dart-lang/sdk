// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = "Don't use `final` for local variables.";

class UnnecessaryFinal extends MultiAnalysisRule {
  UnnecessaryFinal()
    : super(name: LintNames.unnecessary_final, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    diag.unnecessaryFinalWithType,
    diag.unnecessaryFinalWithoutType,
  ];

  @override
  List<String> get incompatibleRules => const [
    LintNames.prefer_final_locals,
    LintNames.prefer_final_parameters,
    LintNames.prefer_final_in_for_each,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry
      ..addFormalParameterList(this, visitor)
      ..addForStatement(this, visitor)
      ..addDeclaredVariablePattern(this, visitor)
      ..addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  (Token?, AstNode?) getParameterDetails(FormalParameter node) {
    var parameter = node is DefaultFormalParameter ? node.parameter : node;
    return switch (parameter) {
      FieldFormalParameter() => (parameter.keyword, parameter.type),
      SimpleFormalParameter() => (parameter.keyword, parameter.type),
      SuperFormalParameter() => (parameter.keyword, parameter.type),
      _ => (null, null),
    };
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var keyword = node.keyword;
    keyword ??= node
        .thisOrAncestorOfType<PatternVariableDeclaration>()
        ?.keyword;
    if (keyword == null || keyword.type != Keyword.FINAL) return;

    var diagnosticCode = getDiagnosticCode(node.matchedValueType);
    rule.reportAtToken(keyword, diagnosticCode: diagnosticCode);
  }

  @override
  void visitFormalParameterList(FormalParameterList parameterList) {
    for (var node in parameterList.parameters) {
      if (node.isFinal) {
        if (node.declaredFragment!.element case FieldFormalParameterElement(
          // ignore: experimental_member_use
          isDeclaring: true,
        ) when context.isFeatureEnabled(Feature.primary_constructors)) {
          continue;
        }
        var (keyword, type) = getParameterDetails(node);
        if (keyword == null) continue;

        var diagnosticCode = getDiagnosticCode(type);
        rule.reportAtToken(keyword, diagnosticCode: diagnosticCode);
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    // If the following `if` test fails, then either the statement is not a
    // for-each loop, or it is something like `for(a in b) { ... }`.  In the
    // second case, notice `a` is not actually declared from within the
    // loop. `a` is a variable declared outside the loop.
    if (forLoopParts is ForEachPartsWithDeclaration) {
      var loopVariable = forLoopParts.loopVariable;
      var keyword = loopVariable.keyword;
      if (keyword == null) return;
      if (loopVariable.isFinal) {
        var diagnosticCode = getDiagnosticCode(loopVariable.type);
        rule.reportAtToken(keyword, diagnosticCode: diagnosticCode);
      }
    } else if (forLoopParts is ForEachPartsWithPattern) {
      var keyword = forLoopParts.keyword;
      if (keyword.isFinal) {
        rule.reportAtToken(
          keyword,
          diagnosticCode: diag.unnecessaryFinalWithoutType,
        );
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var keyword = node.variables.keyword;
    if (keyword == null) return;
    if (node.variables.isFinal) {
      var diagnosticCode = getDiagnosticCode(node.variables.type);
      rule.reportAtToken(keyword, diagnosticCode: diagnosticCode);
    }
  }

  static DiagnosticCode getDiagnosticCode(Object? type) => type == null
      ? diag.unnecessaryFinalWithoutType
      : diag.unnecessaryFinalWithType;
}
