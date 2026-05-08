// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
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
// ignore: implementation_imports
import 'package:analyzer/src/utilities/extensions/collection.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/ascii_utils.dart';

const _desc = r'Unnecessary underscores can be removed.';

class UnnecessaryUnderscores extends AnalysisRule {
  UnnecessaryUnderscores()
    : super(name: LintNames.unnecessary_underscores, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryUnderscores;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.wildcard_variables)) return;
    var visitor = _Visitor(this);
    registry.addFormalParameterList(this, visitor);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final Set<Element> referencedElements = <Element>{};

  _BodyVisitor();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    referencedElements.addIfNotNull(node.element);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    var justUnderscoresParameters = <FormalParameter>[];

    for (var parameter in node.parameters) {
      var parameterName = parameter.name;
      if (parameterName == null) continue;
      var element = parameter.declaredFragment?.element;
      if (element is FieldFormalParameterElement && element.isDeclaring) {
        continue;
      }
      var name = element?.name;
      if (isJustUnderscores(name)) {
        justUnderscoresParameters.add(parameter);
      }
    }

    if (justUnderscoresParameters.isEmpty) return;

    var functionDeclaration = node.parent;
    if (functionDeclaration is FunctionExpression) {
      functionDeclaration = functionDeclaration.parent;
    }

    var referencedElements = switch (functionDeclaration) {
      ConstructorDeclaration() => collectReferences(
        functionDeclaration.body,
        documentationComment: functionDeclaration.documentationComment,
      ),
      FunctionDeclaration() => collectReferences(
        functionDeclaration.functionExpression.body,
        documentationComment: functionDeclaration.documentationComment,
      ),
      MethodDeclaration() => collectReferences(
        functionDeclaration.body,
        documentationComment: functionDeclaration.documentationComment,
      ),
      PrimaryConstructorDeclaration() => collectReferences(
        functionDeclaration.body?.body,
        documentationComment: functionDeclaration.body?.documentationComment,
      ),
      _ => const <Element>{},
    };

    for (var parameter in justUnderscoresParameters) {
      if (!referencedElements.contains(parameter.declaredFragment!.element)) {
        rule.reportAtToken(parameter.name!);
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var element = node.declaredFragment?.element;
    if (element is FieldElement || element is TopLevelVariableElement) return;

    if (isJustUnderscores(node.name.lexeme)) {
      var parent = node.thisOrAncestorOfType<FunctionBody>();
      if (!collectReferences(parent).contains(node.declaredFragment?.element)) {
        rule.reportAtToken(node.name);
      }
    }
  }

  static Set<Element> collectReferences(
    FunctionBody? node, {
    Comment? documentationComment,
  }) {
    if (node == null) return const {};
    var visitor = _BodyVisitor();
    node.accept(visitor);
    if (documentationComment != null) {
      documentationComment.accept(visitor);
    }
    return visitor.referencedElements;
  }

  static bool isJustUnderscores(String? name) =>
      name != null && name.length > 1 && name.isJustUnderscores;
}
