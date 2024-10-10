// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

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

    var visitor = _Visitor(this, context.libraryElement);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, LibraryElement? library)
      : _wildCardVariablesEnabled =
            library?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;

  bool isWildcardIdentifier(String lexeme) =>
      _wildCardVariablesEnabled && lexeme == '_';

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) return;
    if (node.documentationComment != null) return;

    var parentNode = node.parent;
    if (parentNode is! Declaration) {
      return;
    }
    var parentElement = parentNode.declaredElement;
    // Note: there are no override semantics with extension methods.
    if (parentElement is! InterfaceElement) {
      return;
    }

    var classElement = parentElement;

    if (classElement.isPrivate) return;

    var parentMethod = classElement.lookUpInheritedMethod(
        node.name.lexeme, classElement.library);

    // If it's not an inherited method, check for an augmentation.
    if (parentMethod == null && node.isAugmentation) {
      var element = node.declaredElement;
      // Note that we only require an augmentation to conform to the previous
      // declaration/augmentation in the chain.
      var target = element?.augmentationTarget;
      if (target is MethodElement) {
        parentMethod = target;
      }
    }

    if (parentMethod == null) return;

    var nodeParams = node.parameters;
    if (nodeParams == null) {
      return;
    }

    var parameters = nodeParams.parameters.where((p) => !p.isNamed).toList();
    var parentParameters =
        parentMethod.parameters.where((p) => !p.isNamed).toList();
    var count = math.min(parameters.length, parentParameters.length);
    for (var i = 0; i < count; i++) {
      if (parentParameters.length <= i) break;

      var parentParameterName = parentParameters[i].name;
      if (isWildcardIdentifier(parentParameterName)) continue;

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
