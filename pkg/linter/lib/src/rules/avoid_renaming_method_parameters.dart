// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't rename parameters of overridden methods.";

class AvoidRenamingMethodParameters extends LintRule {
  AvoidRenamingMethodParameters()
    : super(
        name: LintNames.avoid_renaming_method_parameters,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidRenamingMethodParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;

    var visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, RuleContext context)
    : _wildCardVariablesEnabled = context.isFeatureEnabled(
        Feature.wildcard_variables,
      );

  bool isWildcardIdentifier(String lexeme) =>
      _wildCardVariablesEnabled && lexeme == '_';

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) return;
    if (node.documentationComment != null) return;

    var nodeParams = node.parameters;
    if (nodeParams == null) return;

    late List<FormalParameterElement> parentParameters;

    var previousFragment = node.declaredFragment?.previousFragment;
    if (previousFragment == null) {
      // If it's the first fragment, check for an inherited member.
      var parentNode = node.parent;
      if (parentNode is! Declaration) return;

      var parentElement = parentNode.declaredFragment?.element;

      // Note: there are no override semantics with extension methods.
      if (parentElement is! InterfaceElement) return;
      if (parentElement.isPrivate) return;

      var parentMethod = parentElement.getInheritedConcreteMember(
        Name(parentElement.library.uri, node.name.lexeme),
      );
      if (parentMethod == null) return;

      parentParameters = parentMethod.formalParameters.positional;
    } else {
      if (!node.isAugmentation) return;

      parentParameters =
          previousFragment.formalParameters.map((p) => p.element).positional;
    }

    var parameters = nodeParams.parameters.where((p) => !p.isNamed).toList();

    var count = math.min(parameters.length, parentParameters.length);
    for (var i = 0; i < count; i++) {
      if (parentParameters.length <= i) break;

      var parentParameterName = parentParameters[i].name;
      if (parentParameterName == null ||
          isWildcardIdentifier(parentParameterName)) {
        continue;
      }

      var parameterName = parameters[i].name;
      if (parameterName == null) continue;

      var paramLexeme = parameterName.lexeme;
      if (isWildcardIdentifier(paramLexeme)) continue;

      if (paramLexeme != parentParameterName) {
        rule.reportAtToken(
          parameterName,
          arguments: [paramLexeme, parentParameterName],
        );
      }
    }
  }
}

extension on Iterable<FormalParameterElement> {
  List<FormalParameterElement> get positional =>
      where((p) => !p.isNamed).toList();
}
