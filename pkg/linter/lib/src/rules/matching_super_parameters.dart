// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Use matching super parameter names.';

class MatchingSuperParameters extends LintRule {
  MatchingSuperParameters()
      : super(
          name: LintNames.matching_super_parameters,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.matching_super_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  const _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var positionalSuperParameters = <SuperFormalParameter>[];
    for (var parameter in node.parameters.parameters) {
      if (parameter is SuperFormalParameter && parameter.isPositional) {
        positionalSuperParameters.add(parameter);
      }
    }
    if (positionalSuperParameters.isEmpty) {
      // We are only concerned with positional super-parameters.
      return;
    }
    var superInvocation =
        node.initializers.whereType<SuperConstructorInvocation>().firstOrNull;
    var superConstructor = superInvocation?.staticElement;
    if (superConstructor == null) {
      var class_ = node.parent;
      if (class_ is ClassDeclaration) {
        superConstructor =
            class_.declaredElement?.supertype?.element.unnamedConstructor;
      }
    }
    if (superConstructor is! ConstructorElement) {
      return;
    }
    var positionalParametersOfSuper =
        superConstructor.parameters.where((p) => p.isPositional).toList();
    if (positionalParametersOfSuper.length < positionalSuperParameters.length) {
      // More positional parameters are passed to super constructor than it
      // has positional parameters, an error.
      return;
    }
    for (var i = 0; i < positionalSuperParameters.length; i++) {
      var superParameter = positionalSuperParameters[i];
      var superParameterName = superParameter.name.lexeme;
      var parameterOfSuperName = positionalParametersOfSuper[i].name;
      if (superParameterName != parameterOfSuperName) {
        rule.reportLint(superParameter,
            arguments: [superParameterName, parameterOfSuperName]);
      }
    }
  }
}
