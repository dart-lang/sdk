// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// [RecursiveAstVisitor2] that delegates visit methods to functions.
class FunctionAstVisitor extends RecursiveAstVisitor2<void> {
  final void Function(Block)? block;
  final void Function(CatchClauseParameter)? catchClauseParameter;
  final void Function(DeclaredIdentifier)? declaredIdentifier;
  final void Function(DeclaredVariablePattern)? declaredVariablePattern;
  final void Function(ForElement)? forElement;
  final void Function(ForStatement)? forStatement;
  final void Function(FunctionExpression)? functionExpression;
  final void Function(GuardedPattern)? guardedPattern;
  final void Function(IfElement)? ifElement;
  final void Function(IfStatement)? ifStatement;
  final void Function(Label)? label;
  final void Function(LocalFunctionDeclaration)? localFunctionDeclaration;
  final void Function(LocalVariable)? localVariable;
  final void Function(MethodDeclaration)? methodDeclaration;
  final void Function(PatternAssignment)? patternAssignment;
  final void Function(PatternVariableDeclaration)? patternVariableDeclaration;
  final void Function(PatternVariableDeclarationStatement)?
  patternVariableDeclarationStatement;
  final void Function(SwitchExpression)? switchExpression;
  final void Function(SwitchExpressionCase)? switchExpressionCase;
  final void Function(SwitchPatternCase)? switchPatternCase;
  final void Function(TopLevelFunctionDeclaration)? topLevelFunctionDeclaration;
  final void Function(TypeParameter)? typeParameter;
  final void Function(UnqualifiedFunctionInvocation)?
  unqualifiedFunctionInvocation;

  new({
    this.block,
    this.catchClauseParameter,
    this.declaredIdentifier,
    this.declaredVariablePattern,
    this.forElement,
    this.forStatement,
    this.functionExpression,
    this.guardedPattern,
    this.ifElement,
    this.ifStatement,
    this.label,
    this.localFunctionDeclaration,
    this.localVariable,
    this.methodDeclaration,
    this.patternAssignment,
    this.patternVariableDeclaration,
    this.patternVariableDeclarationStatement,
    this.switchExpression,
    this.switchExpressionCase,
    this.switchPatternCase,
    this.topLevelFunctionDeclaration,
    this.typeParameter,
    this.unqualifiedFunctionInvocation,
  });

  @override
  void visitBlock(Block node) {
    block?.call(node);
    super.visitBlock(node);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    catchClauseParameter?.call(node);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (declaredIdentifier != null) {
      declaredIdentifier!(node);
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    declaredVariablePattern?.call(node);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitForElement(ForElement node) {
    if (forElement != null) {
      forElement!(node);
    }
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (forStatement != null) {
      forStatement!(node);
    }
    super.visitForStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    functionExpression?.call(node);
    super.visitFunctionExpression(node);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    guardedPattern?.call(node);
    super.visitGuardedPattern(node);
  }

  @override
  void visitIfElement(IfElement node) {
    ifElement?.call(node);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    ifStatement?.call(node);
    super.visitIfStatement(node);
  }

  @override
  void visitLabel(Label node) {
    if (label != null) {
      label!(node);
    }
    super.visitLabel(node);
  }

  @override
  void visitLocalFunctionDeclaration(LocalFunctionDeclaration node) {
    localFunctionDeclaration?.call(node);
    super.visitLocalFunctionDeclaration(node);
  }

  @override
  void visitLocalVariable(LocalVariable node) {
    localVariable?.call(node);
    super.visitLocalVariable(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    methodDeclaration?.call(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    patternAssignment?.call(node);
    super.visitPatternAssignment(node);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    patternVariableDeclaration?.call(node);
    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    patternVariableDeclarationStatement?.call(node);
    super.visitPatternVariableDeclarationStatement(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    switchExpression?.call(node);
    super.visitSwitchExpression(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    switchExpressionCase?.call(node);
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    switchPatternCase?.call(node);
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitTopLevelFunctionDeclaration(TopLevelFunctionDeclaration node) {
    topLevelFunctionDeclaration?.call(node);
    super.visitTopLevelFunctionDeclaration(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    typeParameter?.call(node);
    super.visitTypeParameter(node);
  }

  @override
  void visitUnqualifiedFunctionInvocation(UnqualifiedFunctionInvocation node) {
    unqualifiedFunctionInvocation?.call(node);
    super.visitUnqualifiedFunctionInvocation(node);
  }
}
