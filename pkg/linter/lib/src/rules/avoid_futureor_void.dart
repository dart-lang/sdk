// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/variance_checker.dart';

const _desc = r"Avoid using 'FutureOr<void>' as the type of a result.";

class AvoidFutureOrVoid extends LintRule {
  AvoidFutureOrVoid()
      : super(
            name: LintNames.avoid_futureor_void,
            description: _desc,
            state: State.experimental());

  @override
  LintCode get lintCode => LinterLintCode.avoid_futureor_void;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
    registry.addCastPattern(this, visitor);
    registry.addExtendsClause(this, visitor);
    registry.addExtensionOnClause(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addImplementsClause(this, visitor);
    registry.addIsExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addMixinOnClause(this, visitor);
    registry.addObjectPattern(this, visitor);
    registry.addRepresentationDeclaration(this, visitor);
    registry.addTypeParameter(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
    registry.addWithClause(this, visitor);
  }
}

class _FutureOrVarianceChecker extends VarianceChecker {
  final LintRule rule;
  _FutureOrVarianceChecker(this.rule);

  @override
  void checkNamedType(
    Variance variance,
    DartType staticType,
    TypeAnnotation typeAnnotation,
  ) {
    if (staticType is ParameterizedType) {
      if (variance == Variance.in_) return;
      if (!staticType.isDartAsyncFutureOr) return;
      var typeArguments = staticType.typeArguments;
      if (typeArguments.length != 1) return; // Just to be safe.
      if (typeArguments.first is VoidType) {
        rule.reportLint(typeAnnotation);
      }
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;
  final VarianceChecker checker;

  _Visitor(this.rule, this.context) : checker = _FutureOrVarianceChecker(rule);

  @override
  void visitAsExpression(AsExpression node) => checker.checkOut(node.type);

  @override
  void visitCastPattern(CastPattern node) => checker.checkOut(node.type);

  @override
  void visitExtendsClause(ExtendsClause node) =>
      checker.checkOut(node.superclass);

  @override
  void visitExtensionOnClause(ExtensionOnClause node) =>
      checker.checkOut(node.extendedType);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    checker.checkOut(node.returnType);
    var functionExpression = node.functionExpression;
    functionExpression.typeParameters?.typeParameters
        .forEach(checker.checkBound);
    functionExpression.parameters?.parameters
        .forEach(checker.checkFormalParameterIn);
  }

  @override
  void visitImplementsClause(ImplementsClause node) =>
      node.interfaces.forEach(checker.checkOut);

  @override
  void visitIsExpression(IsExpression node) => checker.checkOut(node.type);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    checker.checkOut(node.returnType);
    node.typeParameters?.typeParameters.forEach(checker.checkBound);
    node.parameters?.parameters.forEach(checker.checkFormalParameterIn);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) =>
      node.superclassConstraints.forEach(checker.checkOut);

  @override
  void visitObjectPattern(ObjectPattern node) => checker.checkOut(node.type);

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) =>
      checker.checkOut(node.fieldType);

  @override
  void visitTypeParameter(TypeParameter node) => checker.checkInOut(node.bound);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) =>
      checker.checkOut(node.type);

  @override
  void visitWithClause(WithClause node) =>
      node.mixinTypes.forEach(checker.checkOut);
}
