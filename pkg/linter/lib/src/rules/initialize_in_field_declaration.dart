// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r"Initialize the field in the field's initializer.";

class InitializeInFieldDeclaration extends AnalysisRule {
  new()
    : super(
        name: LintNames.initialize_in_field_declaration,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.initializeInFieldDeclaration;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.primary_constructors)) return;
    var visitor = _Visitor(this);
    registry.addPrimaryConstructorBody(this, visitor);
  }
}

class _ParameterReferenceVisitor extends RecursiveAstVisitor<void> {
  final ConstructorElement constructorElement;
  bool referencesParameter = false;

  new(this.constructorElement);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is FormalParameterElement &&
        element.enclosingElement == constructorElement) {
      referencesParameter = true;
    }
    super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    var declaration = node.declaration;
    if (declaration == null) return;
    var constructorElement = declaration.declaredFragment?.element;
    if (constructorElement == null) return;

    for (var initializer in node.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        var fieldName = initializer.fieldName;
        var fieldElement = fieldName.element;
        if (fieldElement is! FieldElement) continue;
        if (fieldElement.isLate) continue;
        if (fieldElement.enclosingElement !=
            constructorElement.enclosingElement) {
          continue;
        }
        var visitor = _ParameterReferenceVisitor(constructorElement);
        initializer.expression.accept(visitor);
        if (visitor.referencesParameter) {
          rule.reportAtSourceRange(fieldName.sourceRange);
        }
      }
    }
  }
}
