// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Avoid shadowing type parameters.';

class AvoidShadowingTypeParameters extends AnalysisRule {
  AvoidShadowingTypeParameters()
    : super(
        name: LintNames.avoid_shadowing_type_parameters,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.avoidShadowingTypeParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFunctionDeclarationStatement(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final AnalysisRule rule;

  _Visitor(this.rule, RuleContext context)
    : _wildCardVariablesEnabled = context.isFeatureEnabled(
        Feature.wildcard_variables,
      );

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    var functionExpression = node.functionDeclaration.functionExpression;
    if (functionExpression.typeParameters != null) {
      _checkAncestorParameters(functionExpression.typeParameters, node);
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var typeParameters = node.functionType?.typeParameters;
    if (typeParameters != null) {
      _checkForShadowing(typeParameters, node.typeParameters, 'typedef');
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.typeParameters == null) {
      return;
    }

    // Static methods have nothing above them to shadow.
    if (!node.isStatic) {
      _checkAncestorParameters(node.typeParameters, node);
    }
  }

  // Check the ancestors of [node] for type parameter shadowing.
  void _checkAncestorParameters(
    TypeParameterList? typeParameters,
    AstNode node,
  ) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is ClassDeclaration) {
        _checkForShadowing(
          typeParameters,
          parent.namePart.typeParameters,
          'class',
        );
      } else if (parent is EnumDeclaration) {
        _checkForShadowing(
          typeParameters,
          parent.namePart.typeParameters,
          'enum',
        );
      } else if (parent is ExtensionDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'extension');
      } else if (parent is ExtensionTypeDeclaration) {
        _checkForShadowing(
          typeParameters,
          parent.primaryConstructor.typeParameters,
          'extension type',
        );
      } else if (parent is MethodDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'method');
      } else if (parent is MixinDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'mixin');
      } else if (parent is FunctionDeclaration) {
        _checkForShadowing(
          typeParameters,
          parent.functionExpression.typeParameters,
          'function',
        );
      }
      parent = parent.parent;
    }
  }

  // Check whether any of [typeParameters] shadow [ancestorTypeParameters].
  void _checkForShadowing(
    TypeParameterList? typeParameters,
    TypeParameterList? ancestorTypeParameters,
    String ancestorKind,
  ) {
    if (typeParameters == null || ancestorTypeParameters == null) {
      return;
    }

    var ancestorTypeParameterNames = ancestorTypeParameters.typeParameters
        .map((tp) => tp.name.lexeme)
        .toSet();

    for (var parameter in typeParameters.typeParameters) {
      var lexeme = parameter.name.lexeme;
      if (_wildCardVariablesEnabled && lexeme == '_') continue;
      if (ancestorTypeParameterNames.contains(lexeme)) {
        rule.reportAtNode(
          parameter,
          arguments: [parameter.name.lexeme, ancestorKind],
        );
      }
    }
  }
}
