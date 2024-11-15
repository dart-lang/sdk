// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'
    show TypeParameterElementImpl2;

import '../analyzer.dart';
import '../util/variance_checker.dart';

const _desc = r'Unsafe type: Has a type variable in a non-covariant position.';

class UnsafeVariance extends LintRule {
  UnsafeVariance()
      : super(
          name: LintNames.unsafe_variance,
          description: _desc,
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => LinterLintCode.unsafe_variance;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
      if (typeParameterElement is TypeParameterElementImpl2) {
        if (typeParameterElement.firstFragment.isLegacyCovariant &&
            variance != Variance.out) {
          rule.reportLint(typeAnnotation);
        }
      }
    }
  }

  bool owningDeclarationSupportsVariance(Element2 element) {
    var parent = element.enclosingElement2;
    while (parent != null) {
      switch (parent) {
        case InstanceElement2():
          if (parent is ClassElement2 ||
              parent is MixinElement2 ||
              parent is EnumElement2) {
            return true;
          }
          if (parent is ExtensionTypeElement2 || parent is ExtensionElement2) {
            return false;
          }
        case ExecutableElement2():
          return false;
      }
      parent = parent.enclosingElement2;
    }
    return false;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;
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
