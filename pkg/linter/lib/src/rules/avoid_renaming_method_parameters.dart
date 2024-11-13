// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';

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
  LintCode get lintCode => LinterLintCode.avoid_renaming_method_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isInLibDir) return;

    var visitor =
        _Visitor(this, context.libraryElement2, context.inheritanceManager);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final InheritanceManager3 inheritanceManager;

  final LintRule rule;

  _Visitor(this.rule, LibraryElement2? library, this.inheritanceManager)
      : _wildCardVariablesEnabled =
            library?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;

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
      if (parentElement is! InterfaceElement2) return;
      if (parentElement.isPrivate) return;

      var parentMethod = inheritanceManager.getMember4(
          parentElement, Name(parentElement.library2.uri, node.name.lexeme),
          forSuper: true);
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

      var parentParameterName = parentParameters[i].name3;
      if (parentParameterName == null ||
          isWildcardIdentifier(parentParameterName)) {
        continue;
      }

      var parameterName = parameters[i].name;
      if (parameterName == null) continue;

      var paramLexeme = parameterName.lexeme;
      if (isWildcardIdentifier(paramLexeme)) continue;

      if (paramLexeme != parentParameterName) {
        rule.reportLintForToken(parameterName,
            arguments: [paramLexeme, parentParameterName]);
      }
    }
  }
}

extension on Iterable<FormalParameterElement> {
  List<FormalParameterElement> get positional =>
      where((p) => !p.isNamed).toList();
}
