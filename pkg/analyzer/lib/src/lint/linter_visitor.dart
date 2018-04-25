// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/services/lint.dart';

/// The type of the function that handles exceptions in lints.
typedef void LintRuleExceptionHandler(
    AstNode node, LintRule linter, dynamic exception, StackTrace stackTrace);

/// The AST visitor that runs handlers for nodes from the [registry].
class LinterVisitor extends RecursiveAstVisitor<void> {
  final NodeLintRegistry registry;
  final LintRuleExceptionHandler exceptionHandler;

  LinterVisitor(this.registry, this.exceptionHandler);

  @override
  void visitAsExpression(AsExpression node) {
    _runSubscriptions(node, registry._forAsExpression);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _runSubscriptions(node, registry._forAssertStatement);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _runSubscriptions(node, registry._forAssignmentExpression);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _runSubscriptions(node, registry._forAwaitExpression);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _runSubscriptions(node, registry._forBinaryExpression);
    super.visitBinaryExpression(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _runSubscriptions(node, registry._forBreakStatement);
    super.visitBreakStatement(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _runSubscriptions(node, registry._forCatchClause);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _runSubscriptions(node, registry._forClassDeclaration);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _runSubscriptions(node, registry._forClassTypeAlias);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _runSubscriptions(node, registry._forComment);
    super.visitComment(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _runSubscriptions(node, registry._forCompilationUnit);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _runSubscriptions(node, registry._forConstructorDeclaration);
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _runSubscriptions(node, registry._forContinueStatement);
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _runSubscriptions(node, registry._forDeclaredIdentifier);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _runSubscriptions(node, registry._forDefaultFormalParameter);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _runSubscriptions(node, registry._forDoStatement);
    super.visitDoStatement(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _runSubscriptions(node, registry._forEmptyStatement);
    super.visitEmptyStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _runSubscriptions(node, registry._forEnumConstantDeclaration);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _runSubscriptions(node, registry._forEnumDeclaration);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _runSubscriptions(node, registry._forFieldDeclaration);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _runSubscriptions(node, registry._forFieldFormalParameter);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    _runSubscriptions(node, registry._forForEachStatement);
    super.visitForEachStatement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _runSubscriptions(node, registry._forFormalParameterList);
    super.visitFormalParameterList(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _runSubscriptions(node, registry._forForStatement);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _runSubscriptions(node, registry._forFunctionDeclaration);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _runSubscriptions(node, registry._forFunctionTypeAlias);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _runSubscriptions(node, registry._forIfStatement);
    super.visitIfStatement(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _runSubscriptions(node, registry._forImportDirective);
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _runSubscriptions(node, registry._forInstanceCreationExpression);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _runSubscriptions(node, registry._forLibraryDirective);
    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _runSubscriptions(node, registry._forListLiteral);
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    _runSubscriptions(node, registry._forMapLiteral);
    super.visitMapLiteral(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _runSubscriptions(node, registry._forMethodDeclaration);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _runSubscriptions(node, registry._forMethodInvocation);
    super.visitMethodInvocation(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _runSubscriptions(node, registry._forParenthesizedExpression);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _runSubscriptions(node, registry._forReturnStatement);
    super.visitReturnStatement(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _runSubscriptions(node, registry._forSimpleFormalParameter);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _runSubscriptions(node, registry._forSimpleIdentifier);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _runSubscriptions(node, registry._forSimpleStringLiteral);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _runSubscriptions(node, registry._forStringInterpolation);
    super.visitStringInterpolation(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _runSubscriptions(node, registry._forSwitchStatement);
    super.visitSwitchStatement(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _runSubscriptions(node, registry._forThrowExpression);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _runSubscriptions(node, registry._forTopLevelVariableDeclaration);
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTypeName(TypeName node) {
    _runSubscriptions(node, registry._forTypeName);
    super.visitTypeName(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _runSubscriptions(node, registry._forVariableDeclaration);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _runSubscriptions(node, registry._forVariableDeclarationList);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _runSubscriptions(node, registry._forVariableDeclarationStatement);
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _runSubscriptions(node, registry._forWhileStatement);
    super.visitWhileStatement(node);
  }

  void _runSubscriptions<T extends AstNode>(
      T node, List<_Subscription<T>> subscriptions) {
    for (int i = 0; i < subscriptions.length; i++) {
      var subscription = subscriptions[i];
      var timer = subscription.timer;
      timer?.start();
      try {
        subscription.processor(node);
      } catch (exception, stackTrace) {
        exceptionHandler(node, subscription.linter, exception, stackTrace);
      }
      timer?.stop();
    }
  }
}

/// The container to register handlers for AST nodes.
class NodeLintRegistry {
  final bool enableTiming;
  final List<_Subscription<AsExpression>> _forAsExpression = [];
  final List<_Subscription<AssignmentExpression>> _forAssignmentExpression = [];
  final List<_Subscription<AssertStatement>> _forAssertStatement = [];
  final List<_Subscription<AwaitExpression>> _forAwaitExpression = [];
  final List<_Subscription<BinaryExpression>> _forBinaryExpression = [];
  final List<_Subscription<BreakStatement>> _forBreakStatement = [];
  final List<_Subscription<CatchClause>> _forCatchClause = [];
  final List<_Subscription<ClassDeclaration>> _forClassDeclaration = [];
  final List<_Subscription<ClassTypeAlias>> _forClassTypeAlias = [];
  final List<_Subscription<Comment>> _forComment = [];
  final List<_Subscription<CompilationUnit>> _forCompilationUnit = [];
  final List<_Subscription<ConstructorDeclaration>> _forConstructorDeclaration =
      [];
  final List<_Subscription<ContinueStatement>> _forContinueStatement = [];
  final List<_Subscription<DeclaredIdentifier>> _forDeclaredIdentifier = [];
  final List<_Subscription<DefaultFormalParameter>> _forDefaultFormalParameter =
      [];
  final List<_Subscription<DoStatement>> _forDoStatement = [];
  final List<_Subscription<EmptyStatement>> _forEmptyStatement = [];
  final List<_Subscription<EnumConstantDeclaration>>
      _forEnumConstantDeclaration = [];
  final List<_Subscription<EnumDeclaration>> _forEnumDeclaration = [];
  final List<_Subscription<FieldDeclaration>> _forFieldDeclaration = [];
  final List<_Subscription<FieldFormalParameter>> _forFieldFormalParameter = [];
  final List<_Subscription<FormalParameterList>> _forFormalParameterList = [];
  final List<_Subscription<ForEachStatement>> _forForEachStatement = [];
  final List<_Subscription<ForStatement>> _forForStatement = [];
  final List<_Subscription<FunctionDeclaration>> _forFunctionDeclaration = [];
  final List<_Subscription<FunctionTypeAlias>> _forFunctionTypeAlias = [];
  final List<_Subscription<IfStatement>> _forIfStatement = [];
  final List<_Subscription<ImportDirective>> _forImportDirective = [];
  final List<_Subscription<InstanceCreationExpression>>
      _forInstanceCreationExpression = [];
  final List<_Subscription<LibraryDirective>> _forLibraryDirective = [];
  final List<_Subscription<ListLiteral>> _forListLiteral = [];
  final List<_Subscription<MapLiteral>> _forMapLiteral = [];
  final List<_Subscription<MethodDeclaration>> _forMethodDeclaration = [];
  final List<_Subscription<MethodInvocation>> _forMethodInvocation = [];
  final List<_Subscription<ParenthesizedExpression>>
      _forParenthesizedExpression = [];
  final List<_Subscription<ReturnStatement>> _forReturnStatement = [];
  final List<_Subscription<SimpleFormalParameter>> _forSimpleFormalParameter =
      [];
  final List<_Subscription<SimpleIdentifier>> _forSimpleIdentifier = [];
  final List<_Subscription<SimpleStringLiteral>> _forSimpleStringLiteral = [];
  final List<_Subscription<StringInterpolation>> _forStringInterpolation = [];
  final List<_Subscription<SwitchStatement>> _forSwitchStatement = [];
  final List<_Subscription<ThrowExpression>> _forThrowExpression = [];
  final List<_Subscription<TopLevelVariableDeclaration>>
      _forTopLevelVariableDeclaration = [];
  final List<_Subscription<TypeName>> _forTypeName = [];
  final List<_Subscription<VariableDeclaration>> _forVariableDeclaration = [];
  final List<_Subscription<VariableDeclarationList>>
      _forVariableDeclarationList = [];
  final List<_Subscription<VariableDeclarationStatement>>
      _forVariableDeclarationStatement = [];
  final List<_Subscription<WhileStatement>> _forWhileStatement = [];

  NodeLintRegistry(this.enableTiming);

  void addAsExpression(LintRule linter, void Function(AsExpression) f) {
    _forAsExpression.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addAssertStatement(LintRule linter, void Function(AssertStatement) f) {
    _forAssertStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addAssignmentExpression(
      LintRule linter, void Function(AssignmentExpression) f) {
    _forAssignmentExpression
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addAwaitExpression(LintRule linter, void Function(AwaitExpression) f) {
    _forAwaitExpression.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addBinaryExpression(LintRule linter, void Function(BinaryExpression) f) {
    _forBinaryExpression.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addBreakStatement(LintRule linter, void Function(BreakStatement) f) {
    _forBreakStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addCatchClause(LintRule linter, void Function(CatchClause) f) {
    _forCatchClause.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addClassDeclaration(LintRule linter, void Function(ClassDeclaration) f) {
    _forClassDeclaration.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addClassTypeAlias(LintRule linter, void Function(ClassTypeAlias) f) {
    _forClassTypeAlias.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addComment(LintRule linter, void Function(Comment) f) {
    _forComment.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addCompilationUnit(LintRule linter, void Function(CompilationUnit) f) {
    _forCompilationUnit.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addConstructorDeclaration(
      LintRule linter, void Function(ConstructorDeclaration) f) {
    _forConstructorDeclaration
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addContinueStatement(
      LintRule linter, void Function(ContinueStatement) f) {
    _forContinueStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addDeclaredIdentifier(
      LintRule linter, void Function(DeclaredIdentifier) f) {
    _forDeclaredIdentifier.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addDefaultFormalParameter(
      LintRule linter, void Function(DefaultFormalParameter) f) {
    _forDefaultFormalParameter
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addDoStatement(LintRule linter, void Function(DoStatement) f) {
    _forDoStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addEmptyStatement(LintRule linter, void Function(EmptyStatement) f) {
    _forEmptyStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addEnumConstantDeclaration(
      LintRule linter, void Function(EnumConstantDeclaration) f) {
    _forEnumConstantDeclaration
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addEnumDeclaration(LintRule linter, void Function(EnumDeclaration) f) {
    _forEnumDeclaration.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addFieldDeclaration(LintRule linter, void Function(FieldDeclaration) f) {
    _forFieldDeclaration.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addFieldFormalParameter(
      LintRule linter, void Function(FieldFormalParameter) f) {
    _forFieldFormalParameter
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addForEachStatement(LintRule linter, void Function(ForEachStatement) f) {
    _forForEachStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addFormalParameterList(
      LintRule linter, void Function(FormalParameterList) f) {
    _forFormalParameterList
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addForStatement(LintRule linter, void Function(ForStatement) f) {
    _forForStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addFunctionDeclaration(
      LintRule linter, void Function(FunctionDeclaration) f) {
    _forFunctionDeclaration
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addFunctionTypeAlias(
      LintRule linter, void Function(FunctionTypeAlias) f) {
    _forFunctionTypeAlias.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addIfStatement(LintRule linter, void Function(IfStatement) f) {
    _forIfStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addImportDirective(LintRule linter, void Function(ImportDirective) f) {
    _forImportDirective.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addInstanceCreationExpression(
      LintRule linter, void Function(InstanceCreationExpression) f) {
    _forInstanceCreationExpression
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addLibraryDirective(LintRule linter, void Function(LibraryDirective) f) {
    _forLibraryDirective.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addListLiteral(LintRule linter, void Function(ListLiteral) f) {
    _forListLiteral.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addMapLiteral(LintRule linter, void Function(MapLiteral) f) {
    _forMapLiteral.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addMethodDeclaration(
      LintRule linter, void Function(MethodDeclaration) f) {
    _forMethodDeclaration.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addMethodInvocation(LintRule linter, void Function(MethodInvocation) f) {
    _forMethodInvocation.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addParenthesizedExpression(
      LintRule linter, void Function(ParenthesizedExpression) f) {
    _forParenthesizedExpression
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addReturnStatement(LintRule linter, void Function(ReturnStatement) f) {
    _forReturnStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addSimpleFormalParameter(
      LintRule linter, void Function(SimpleFormalParameter) f) {
    _forSimpleFormalParameter
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addSimpleIdentifier(LintRule linter, void Function(SimpleIdentifier) f) {
    _forSimpleIdentifier.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addSimpleStringLiteral(
      LintRule linter, void Function(SimpleStringLiteral) f) {
    _forSimpleStringLiteral
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addStringInterpolation(
      LintRule linter, void Function(StringInterpolation) f) {
    _forStringInterpolation
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addSwitchStatement(LintRule linter, void Function(SwitchStatement) f) {
    _forSwitchStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addThrowExpression(LintRule linter, void Function(ThrowExpression) f) {
    _forThrowExpression.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addTopLevelVariableDeclaration(
      LintRule linter, void Function(TopLevelVariableDeclaration) f) {
    _forTopLevelVariableDeclaration
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addTypeName(LintRule linter, void Function(TypeName) f) {
    _forTypeName.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addVariableDeclaration(
      LintRule linter, void Function(VariableDeclaration) f) {
    _forVariableDeclaration
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addVariableDeclarationList(
      LintRule linter, void Function(VariableDeclarationList) f) {
    _forVariableDeclarationList
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addVariableDeclarationStatement(
      LintRule linter, void Function(VariableDeclarationStatement) f) {
    _forVariableDeclarationStatement
        .add(new _Subscription(linter, f, _getTimer(linter)));
  }

  void addWhileStatement(LintRule linter, void Function(WhileStatement) f) {
    _forWhileStatement.add(new _Subscription(linter, f, _getTimer(linter)));
  }

  /// Get the timer associated with the given [linter].
  Stopwatch _getTimer(LintRule linter) {
    if (enableTiming) {
      return lintRegistry.getTimer(linter);
    } else {
      return null;
    }
  }
}

/// A single subscription for a node type, by the specified [linter].
class _Subscription<T> {
  final LintRule linter;
  final void Function(T) processor;
  final Stopwatch timer;

  _Subscription(this.linter, this.processor, this.timer);
}
