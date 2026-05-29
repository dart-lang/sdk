// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/utilities/extensions/ast.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid defining unused parameters in constructors.';

class AvoidUnusedConstructorParameters extends AnalysisRule {
  new()
    : super(
        name: LintNames.avoid_unused_constructor_parameters,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.avoidUnusedConstructorParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _ConstructorVisitor extends RecursiveAstVisitor<void> {
  final FormalParameterList parameterList;
  final Set<FormalParameter> unusedParameters;

  new(this.parameterList)
    : unusedParameters = parameterList.parameters.where((p) {
        var element = p.declaredFragment?.element;
        return element != null &&
            element is! FieldFormalParameterElement &&
            element is! SuperFormalParameterElement &&
            !element.metadata.hasDeprecated &&
            !(element.name ?? '').isJustUnderscores;
      }).toSet();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    unusedParameters.removeWhere(
      (p) => node.element == p.declaredFragment?.element,
    );
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;
    if (node.redirectedConstructor != null) return;
    if (node.externalKeyword != null) return;

    _checkConstructorParameters(
      parameterList: node.parameters,
      initializers: node.initializers,
      body: node.body,
      fields: null,
    );
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var fields = node.parent.classMembers
        .whereType<FieldDeclaration>()
        .expand((declaration) => declaration.fields.variables)
        .where((field) => field.initializer != null)
        .toList();
    _checkConstructorParameters(
      parameterList: node.formalParameters,
      initializers: node.body?.initializers,
      body: node.body?.body,
      fields: fields,
    );
  }

  void _checkConstructorParameters({
    required FormalParameterList parameterList,
    required List<ConstructorInitializer>? initializers,
    required FunctionBody? body,
    required List<VariableDeclaration>? fields,
  }) {
    var constructorVisitor = _ConstructorVisitor(parameterList);
    body?.visitChildren(constructorVisitor);
    if (initializers != null) {
      for (var i in initializers) {
        i.visitChildren(constructorVisitor);
      }
    }

    if (fields != null) {
      for (var field in fields) {
        field.initializer?.accept(constructorVisitor);
      }
    }

    for (var parameter in constructorVisitor.unusedParameters) {
      rule.reportAtNode(parameter, arguments: [parameter.name!.lexeme]);
    }
  }
}
