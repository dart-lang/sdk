// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid defining unused parameters in constructors.';

class AvoidUnusedConstructorParameters extends LintRule {
  AvoidUnusedConstructorParameters()
    : super(
        name: LintNames.avoid_unused_constructor_parameters,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidUnusedConstructorParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _ConstructorVisitor extends RecursiveAstVisitor<void> {
  final ConstructorDeclaration element;
  final Set<FormalParameter> unusedParameters;

  _ConstructorVisitor(this.element)
    : unusedParameters =
          element.parameters.parameters.where((p) {
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
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;
    if (node.redirectedConstructor != null) return;
    if (node.externalKeyword != null) return;

    var constructorVisitor = _ConstructorVisitor(node);
    node.body.visitChildren(constructorVisitor);
    for (var i in node.initializers) {
      i.visitChildren(constructorVisitor);
    }

    for (var parameter in constructorVisitor.unusedParameters) {
      rule.reportAtNode(parameter, arguments: [parameter.name!.lexeme]);
    }
  }
}
