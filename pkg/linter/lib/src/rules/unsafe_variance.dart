// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/element.dart' // ignore: implementation_imports
    show TypeParameterElementImpl;
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../util/variance_checker.dart';

const _desc = r'Unsafe type: Has a type variable in a non-covariant position.';

class UnsafeVariance extends LintRule {
  UnsafeVariance()
    : super(
        name: LintNames.unsafe_variance,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unsafe_variance;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _UnsafeVarianceChecker extends VarianceChecker {
  final LintRule rule;
  _UnsafeVarianceChecker(this.rule);

  @override
  void checkNamedType(
    Variance variance,
    DartType staticType,
    TypeAnnotation typeAnnotation,
  ) {
    if (staticType is TypeParameterType) {
      var typeParameterElement = staticType.element3;
      if (!owningDeclarationSupportsVariance(typeParameterElement)) {
        return;
      }
      if (typeParameterElement is TypeParameterElementImpl) {
        if (typeParameterElement.firstFragment.isLegacyCovariant &&
            variance != Variance.out) {
          rule.reportAtNode(typeAnnotation);
        }
      }
    }
  }

  bool owningDeclarationSupportsVariance(Element element) {
    var parent = element.enclosingElement;
    while (parent != null) {
      switch (parent) {
        case InstanceElement():
          if (parent is ClassElement ||
              parent is MixinElement ||
              parent is EnumElement) {
            return true;
          }
          if (parent is ExtensionTypeElement || parent is ExtensionElement) {
            return false;
          }
        case ExecutableElement():
          return false;
      }
      parent = parent.enclosingElement;
    }
    return false;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;
  final VarianceChecker checker;

  _Visitor(this.rule, this.context) : checker = _UnsafeVarianceChecker(rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) return;
    checker.checkOut(node.returnType);
    node.typeParameters?.typeParameters.forEach(checker.checkBound);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) =>
      checker.checkOut(node.type);
}
