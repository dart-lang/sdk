// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/analysis_rule_timers.dart';
import 'package:analyzer/src/lint/linter.dart';

/// The AST visitor that runs handlers for nodes from the [_registry].
class AnalysisRuleVisitor implements AstVisitor<void> {
  final NodeLintRegistry _registry;

  /// Whether exceptions should be propagated (by rethrowing them).
  final bool _shouldPropagateExceptions;

  AnalysisRuleVisitor(
    this._registry, {
    bool shouldPropagateExceptions = false,
  }) : _shouldPropagateExceptions = shouldPropagateExceptions;

  void afterLibrary() {
    _runAfterLibrarySubscriptions(_registry._afterLibrary);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _runSubscriptions(node, _registry._forAdjacentStrings);
    node.visitChildren(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    _runSubscriptions(node, _registry._forAnnotation);
    node.visitChildren(this);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _runSubscriptions(node, _registry._forArgumentList);
    node.visitChildren(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _runSubscriptions(node, _registry._forAsExpression);
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _runSubscriptions(node, _registry._forAssertInitializer);
    node.visitChildren(this);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _runSubscriptions(node, _registry._forAssertStatement);
    node.visitChildren(this);
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    _runSubscriptions(node, _registry._forAssignedVariablePattern);
    node.visitChildren(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _runSubscriptions(node, _registry._forAssignmentExpression);
    node.visitChildren(this);
  }

  @override
  void visitAugmentedExpression(AugmentedExpression node) {
    _runSubscriptions(node, _registry._forAugmentedExpression);
    node.visitChildren(this);
  }

  @override
  void visitAugmentedInvocation(AugmentedInvocation node) {
    _runSubscriptions(node, _registry._forAugmentedInvocation);
    node.visitChildren(this);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _runSubscriptions(node, _registry._forAwaitExpression);
    node.visitChildren(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _runSubscriptions(node, _registry._forBinaryExpression);
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    _runSubscriptions(node, _registry._forBlock);
    node.visitChildren(this);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _runSubscriptions(node, _registry._forBlockFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _runSubscriptions(node, _registry._forBooleanLiteral);
    node.visitChildren(this);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _runSubscriptions(node, _registry._forBreakStatement);
    node.visitChildren(this);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _runSubscriptions(node, _registry._forCascadeExpression);
    node.visitChildren(this);
  }

  @override
  void visitCaseClause(CaseClause node) {
    _runSubscriptions(node, _registry._forCaseClause);
    node.visitChildren(this);
  }

  @override
  void visitCastPattern(CastPattern node) {
    _runSubscriptions(node, _registry._forCastPattern);
    node.visitChildren(this);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _runSubscriptions(node, _registry._forCatchClause);
    node.visitChildren(this);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _runSubscriptions(node, _registry._forCatchClauseParameter);
    node.visitChildren(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _runSubscriptions(node, _registry._forClassDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _runSubscriptions(node, _registry._forClassTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitComment(Comment node) {
    _runSubscriptions(node, _registry._forComment);
    node.visitChildren(this);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _runSubscriptions(node, _registry._forCommentReference);
    node.visitChildren(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _runSubscriptions(node, _registry._forCompilationUnit);
    node.visitChildren(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _runSubscriptions(node, _registry._forConditionalExpression);
    node.visitChildren(this);
  }

  @override
  void visitConfiguration(Configuration node) {
    _runSubscriptions(node, _registry._forConfiguration);
    node.visitChildren(this);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    _runSubscriptions(node, _registry._forConstantPattern);
    node.visitChildren(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _runSubscriptions(node, _registry._forConstructorDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _runSubscriptions(node, _registry._forConstructorFieldInitializer);
    node.visitChildren(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _runSubscriptions(node, _registry._forConstructorName);
    node.visitChildren(this);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _runSubscriptions(node, _registry._forConstructorReference);
    node.visitChildren(this);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _runSubscriptions(node, _registry._forConstructorSelector);
    node.visitChildren(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _runSubscriptions(node, _registry._forContinueStatement);
    node.visitChildren(this);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _runSubscriptions(node, _registry._forDeclaredIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _runSubscriptions(node, _registry._forDeclaredVariablePattern);
    node.visitChildren(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _runSubscriptions(node, _registry._forDefaultFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _runSubscriptions(node, _registry._forDoStatement);
    node.visitChildren(this);
  }

  @override
  void visitDottedName(DottedName node) {
    _runSubscriptions(node, _registry._forDottedName);
    node.visitChildren(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _runSubscriptions(node, _registry._forDoubleLiteral);
    node.visitChildren(this);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _runSubscriptions(node, _registry._forEmptyFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _runSubscriptions(node, _registry._forEmptyStatement);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    _runSubscriptions(node, _registry._forEnumConstantArguments);
    node.visitChildren(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _runSubscriptions(node, _registry._forEnumConstantDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _runSubscriptions(node, _registry._forEnumDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _runSubscriptions(node, _registry._forExportDirective);
    node.visitChildren(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _runSubscriptions(node, _registry._forExpressionFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _runSubscriptions(node, _registry._forExpressionStatement);
    node.visitChildren(this);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _runSubscriptions(node, _registry._forExtendsClause);
    node.visitChildren(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _runSubscriptions(node, _registry._forExtensionDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    _runSubscriptions(node, _registry._forExtensionOnClause);
    node.visitChildren(this);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _runSubscriptions(node, _registry._forExtensionOverride);
    node.visitChildren(this);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _runSubscriptions(node, _registry._forExtensionTypeDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _runSubscriptions(node, _registry._forFieldDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _runSubscriptions(node, _registry._forFieldFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _runSubscriptions(node, _registry._forForEachPartsWithDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _runSubscriptions(node, _registry._forForEachPartsWithIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _runSubscriptions(node, _registry._forForEachPartsWithPattern);
    node.visitChildren(this);
  }

  @override
  void visitForElement(ForElement node) {
    _runSubscriptions(node, _registry._forForElement);
    node.visitChildren(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _runSubscriptions(node, _registry._forFormalParameterList);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _runSubscriptions(node, _registry._forForPartsWithDeclarations);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _runSubscriptions(node, _registry._forForPartsWithExpression);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _runSubscriptions(node, _registry._forForPartsWithPattern);
    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    _runSubscriptions(node, _registry._forForStatement);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _runSubscriptions(node, _registry._forFunctionDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _runSubscriptions(node, _registry._forFunctionDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _runSubscriptions(node, _registry._forFunctionExpression);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _runSubscriptions(node, _registry._forFunctionExpressionInvocation);
    node.visitChildren(this);
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _runSubscriptions(node, _registry._forFunctionReference);
    node.visitChildren(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _runSubscriptions(node, _registry._forFunctionTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _runSubscriptions(node, _registry._forFunctionTypedFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _runSubscriptions(node, _registry._forGenericFunctionType);
    node.visitChildren(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _runSubscriptions(node, _registry._forGenericTypeAlias);
    node.visitChildren(this);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    _runSubscriptions(node, _registry._forCaseClause);
    node.visitChildren(this);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _runSubscriptions(node, _registry._forHideCombinator);
    node.visitChildren(this);
  }

  @override
  void visitIfElement(IfElement node) {
    _runSubscriptions(node, _registry._forIfElement);
    node.visitChildren(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _runSubscriptions(node, _registry._forIfStatement);
    node.visitChildren(this);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _runSubscriptions(node, _registry._forImplementsClause);
    node.visitChildren(this);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _runSubscriptions(node, _registry._forImplicitCallReference);
    node.visitChildren(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _runSubscriptions(node, _registry._forImportDirective);
    node.visitChildren(this);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _runSubscriptions(node, _registry._forImportPrefixReference);
    node.visitChildren(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _runSubscriptions(node, _registry._forIndexExpression);
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _runSubscriptions(node, _registry._forInstanceCreationExpression);
    node.visitChildren(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _runSubscriptions(node, _registry._forIntegerLiteral);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _runSubscriptions(node, _registry._forInterpolationExpression);
    node.visitChildren(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _runSubscriptions(node, _registry._forInterpolationString);
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _runSubscriptions(node, _registry._forIsExpression);
    node.visitChildren(this);
  }

  @override
  void visitLabel(Label node) {
    _runSubscriptions(node, _registry._forLabel);
    node.visitChildren(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _runSubscriptions(node, _registry._forLabeledStatement);
    node.visitChildren(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _runSubscriptions(node, _registry._forLibraryDirective);
    node.visitChildren(this);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _runSubscriptions(node, _registry._forLibraryIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _runSubscriptions(node, _registry._forListLiteral);
    node.visitChildren(this);
  }

  @override
  void visitListPattern(ListPattern node) {
    _runSubscriptions(node, _registry._forListPattern);
    node.visitChildren(this);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _runSubscriptions(node, _registry._forLogicalAndPattern);
    node.visitChildren(this);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _runSubscriptions(node, _registry._forLogicalOrPattern);
    node.visitChildren(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _runSubscriptions(node, _registry._forMapLiteralEntry);
    node.visitChildren(this);
  }

  @override
  void visitMapPattern(MapPattern node) {
    _runSubscriptions(node, _registry._forMapPattern);
    node.visitChildren(this);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    _runSubscriptions(node, _registry._forMapPatternEntry);
    node.visitChildren(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _runSubscriptions(node, _registry._forMethodDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _runSubscriptions(node, _registry._forMethodInvocation);
    node.visitChildren(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _runSubscriptions(node, _registry._forMixinDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    _runSubscriptions(node, _registry._forMixinOnClause);
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _runSubscriptions(node, _registry._forNamedExpression);
    node.visitChildren(this);
  }

  @override
  void visitNamedType(NamedType node) {
    _runSubscriptions(node, _registry._forNamedType);
    node.visitChildren(this);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _runSubscriptions(node, _registry._forNativeClause);
    node.visitChildren(this);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _runSubscriptions(node, _registry._forNativeFunctionBody);
    node.visitChildren(this);
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    _runSubscriptions(node, _registry._forNullAssertPattern);
    node.visitChildren(this);
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    _runSubscriptions(node, _registry._forNullAwareElement);
    node.visitChildren(this);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    _runSubscriptions(node, _registry._forNullCheckPattern);
    node.visitChildren(this);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _runSubscriptions(node, _registry._forNullLiteral);
    node.visitChildren(this);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _runSubscriptions(node, _registry._forObjectPattern);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _runSubscriptions(node, _registry._forParenthesizedExpression);
    node.visitChildren(this);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    _runSubscriptions(node, _registry._forParenthesizedPattern);
    node.visitChildren(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _runSubscriptions(node, _registry._forPartDirective);
    node.visitChildren(this);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _runSubscriptions(node, _registry._forPartOfDirective);
    node.visitChildren(this);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _runSubscriptions(node, _registry._forPatternAssignment);
    node.visitChildren(this);
  }

  @override
  void visitPatternField(PatternField node) {
    _runSubscriptions(node, _registry._forPatternField);
    node.visitChildren(this);
  }

  @override
  void visitPatternFieldName(PatternFieldName node) {
    _runSubscriptions(node, _registry._forPatternFieldName);
    node.visitChildren(this);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _runSubscriptions(node, _registry._forPatternVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    _runSubscriptions(node, _registry._forPatternVariableDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _runSubscriptions(node, _registry._forPostfixExpression);
    node.visitChildren(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _runSubscriptions(node, _registry._forPrefixedIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _runSubscriptions(node, _registry._forPrefixExpression);
    node.visitChildren(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _runSubscriptions(node, _registry._forPropertyAccess);
    node.visitChildren(this);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _runSubscriptions(node, _registry._forRecordLiterals);
    node.visitChildren(this);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _runSubscriptions(node, _registry._forRecordPattern);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotation);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
      RecordTypeAnnotationNamedField node) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationNamedField);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
      RecordTypeAnnotationNamedFields node) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationNamedFields);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
      RecordTypeAnnotationPositionalField node) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationPositionalField);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _runSubscriptions(node, _registry._forRedirectingConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    _runSubscriptions(node, _registry._forRelationalPattern);
    node.visitChildren(this);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _runSubscriptions(node, _registry._forRepresentationConstructorName);
    node.visitChildren(this);
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    _runSubscriptions(node, _registry._forRepresentationDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    _runSubscriptions(node, _registry._forRestPatternElement);
    node.visitChildren(this);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _runSubscriptions(node, _registry._forRethrowExpression);
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _runSubscriptions(node, _registry._forReturnStatement);
    node.visitChildren(this);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _runSubscriptions(node, _registry._forScriptTag);
    node.visitChildren(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _runSubscriptions(node, _registry._forSetOrMapLiteral);
    node.visitChildren(this);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _runSubscriptions(node, _registry._forShowCombinator);
    node.visitChildren(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _runSubscriptions(node, _registry._forSimpleFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _runSubscriptions(node, _registry._forSimpleIdentifier);
    node.visitChildren(this);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _runSubscriptions(node, _registry._forSimpleStringLiteral);
    node.visitChildren(this);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _runSubscriptions(node, _registry._forSpreadElement);
    node.visitChildren(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _runSubscriptions(node, _registry._forStringInterpolation);
    node.visitChildren(this);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _runSubscriptions(node, _registry._forSuperConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _runSubscriptions(node, _registry._forSuperExpression);
    node.visitChildren(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _runSubscriptions(node, _registry._forSuperFormalParameter);
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _runSubscriptions(node, _registry._forSwitchCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _runSubscriptions(node, _registry._forSwitchDefault);
    node.visitChildren(this);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _runSubscriptions(node, _registry._forSwitchExpression);
    node.visitChildren(this);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _runSubscriptions(node, _registry._forSwitchExpressionCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _runSubscriptions(node, _registry._forSwitchPatternCase);
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _runSubscriptions(node, _registry._forSwitchStatement);
    node.visitChildren(this);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _runSubscriptions(node, _registry._forSymbolLiteral);
    node.visitChildren(this);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _runSubscriptions(node, _registry._forThisExpression);
    node.visitChildren(this);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _runSubscriptions(node, _registry._forThrowExpression);
    node.visitChildren(this);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _runSubscriptions(node, _registry._forTopLevelVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _runSubscriptions(node, _registry._forTryStatement);
    node.visitChildren(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _runSubscriptions(node, _registry._forTypeArgumentList);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _runSubscriptions(node, _registry._forTypeLiteral);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _runSubscriptions(node, _registry._forTypeParameter);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _runSubscriptions(node, _registry._forTypeParameterList);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _runSubscriptions(node, _registry._forVariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _runSubscriptions(node, _registry._forVariableDeclarationList);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _runSubscriptions(node, _registry._forVariableDeclarationStatement);
    node.visitChildren(this);
  }

  @override
  void visitWhenClause(WhenClause node) {
    _runSubscriptions(node, _registry._forWhenClause);
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _runSubscriptions(node, _registry._forWhileStatement);
    node.visitChildren(this);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {
    _runSubscriptions(node, _registry._forWildcardPattern);
    node.visitChildren(this);
  }

  @override
  void visitWithClause(WithClause node) {
    _runSubscriptions(node, _registry._forWithClause);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _runSubscriptions(node, _registry._forYieldStatement);
    node.visitChildren(this);
  }

  /// Handles exceptions that occur during the execution of an [AnalysisRule].
  void _logException(AstNode node, AnalysisRule visitor, Object exception,
      StackTrace stackTrace) {
    var buffer = StringBuffer();
    buffer.write('Exception while using a ${visitor.runtimeType} to visit a ');
    AstNode? currentNode = node;
    var first = true;
    while (currentNode != null) {
      if (first) {
        first = false;
      } else {
        buffer.write(' in ');
      }
      buffer.write(currentNode.runtimeType);
      currentNode = currentNode.parent;
    }
    // TODO(39284): should this exception be silent?
    AnalysisEngine.instance.instrumentationService.logException(
        SilentException(buffer.toString(), exception, stackTrace));
  }

  void _runAfterLibrarySubscriptions(
      List<_AfterLibrarySubscription> subscriptions) {
    for (var subscription in subscriptions) {
      var timer = subscription.timer;
      timer?.start();
      subscription.callback();
      timer?.stop();
    }
  }

  void _runSubscriptions<T extends AstNode>(
      T node, List<_Subscription<T>> subscriptions) {
    for (var subscription in subscriptions) {
      var timer = subscription.timer;
      timer?.start();
      try {
        node.accept(subscription.visitor);
      } catch (exception, stackTrace) {
        _logException(node, subscription.rule, exception, stackTrace);
        if (_shouldPropagateExceptions) {
          rethrow;
        }
      }
      timer?.stop();
    }
  }
}

/// The container to register visitors for separate AST node types.
class NodeLintRegistry {
  final bool _enableTiming;
  final List<_AfterLibrarySubscription> _afterLibrary = [];
  final List<_Subscription<AdjacentStrings>> _forAdjacentStrings = [];
  final List<_Subscription<Annotation>> _forAnnotation = [];
  final List<_Subscription<ArgumentList>> _forArgumentList = [];
  final List<_Subscription<AsExpression>> _forAsExpression = [];
  final List<_Subscription<AssertInitializer>> _forAssertInitializer = [];
  final List<_Subscription<AssertStatement>> _forAssertStatement = [];
  final List<_Subscription<AssignedVariablePattern>>
      _forAssignedVariablePattern = [];
  final List<_Subscription<AssignmentExpression>> _forAssignmentExpression = [];
  final List<_Subscription<AugmentedExpression>> _forAugmentedExpression = [];
  final List<_Subscription<AugmentedInvocation>> _forAugmentedInvocation = [];
  final List<_Subscription<AwaitExpression>> _forAwaitExpression = [];
  final List<_Subscription<BinaryExpression>> _forBinaryExpression = [];
  final List<_Subscription<Block>> _forBlock = [];
  final List<_Subscription<BlockFunctionBody>> _forBlockFunctionBody = [];
  final List<_Subscription<BooleanLiteral>> _forBooleanLiteral = [];
  final List<_Subscription<BreakStatement>> _forBreakStatement = [];
  final List<_Subscription<CascadeExpression>> _forCascadeExpression = [];
  final List<_Subscription<CaseClause>> _forCaseClause = [];
  final List<_Subscription<CastPattern>> _forCastPattern = [];
  final List<_Subscription<CatchClause>> _forCatchClause = [];
  final List<_Subscription<CatchClauseParameter>> _forCatchClauseParameter = [];
  final List<_Subscription<ClassDeclaration>> _forClassDeclaration = [];
  final List<_Subscription<ClassTypeAlias>> _forClassTypeAlias = [];
  final List<_Subscription<Comment>> _forComment = [];
  final List<_Subscription<CommentReference>> _forCommentReference = [];
  final List<_Subscription<CompilationUnit>> _forCompilationUnit = [];
  final List<_Subscription<ConditionalExpression>> _forConditionalExpression =
      [];
  final List<_Subscription<Configuration>> _forConfiguration = [];
  final List<_Subscription<ConstantPattern>> _forConstantPattern = [];
  final List<_Subscription<ConstructorDeclaration>> _forConstructorDeclaration =
      [];
  final List<_Subscription<ConstructorFieldInitializer>>
      _forConstructorFieldInitializer = [];
  final List<_Subscription<ConstructorName>> _forConstructorName = [];
  final List<_Subscription<ConstructorReference>> _forConstructorReference = [];
  final List<_Subscription<ConstructorSelector>> _forConstructorSelector = [];
  final List<_Subscription<ContinueStatement>> _forContinueStatement = [];
  final List<_Subscription<DeclaredIdentifier>> _forDeclaredIdentifier = [];
  final List<_Subscription<DeclaredVariablePattern>>
      _forDeclaredVariablePattern = [];
  final List<_Subscription<DefaultFormalParameter>> _forDefaultFormalParameter =
      [];
  final List<_Subscription<DoStatement>> _forDoStatement = [];
  final List<_Subscription<DottedName>> _forDottedName = [];
  final List<_Subscription<DoubleLiteral>> _forDoubleLiteral = [];
  final List<_Subscription<EmptyFunctionBody>> _forEmptyFunctionBody = [];
  final List<_Subscription<EmptyStatement>> _forEmptyStatement = [];
  final List<_Subscription<EnumConstantArguments>> _forEnumConstantArguments =
      [];
  final List<_Subscription<EnumConstantDeclaration>>
      _forEnumConstantDeclaration = [];
  final List<_Subscription<EnumDeclaration>> _forEnumDeclaration = [];
  final List<_Subscription<ExportDirective>> _forExportDirective = [];
  final List<_Subscription<ExpressionFunctionBody>> _forExpressionFunctionBody =
      [];
  final List<_Subscription<ExpressionStatement>> _forExpressionStatement = [];
  final List<_Subscription<ExtendsClause>> _forExtendsClause = [];
  final List<_Subscription<ExtensionDeclaration>> _forExtensionDeclaration = [];
  final List<_Subscription<ExtensionTypeDeclaration>>
      _forExtensionTypeDeclaration = [];
  final List<_Subscription<ExtensionOnClause>> _forExtensionOnClause = [];
  final List<_Subscription<ExtensionOverride>> _forExtensionOverride = [];
  final List<_Subscription<ObjectPattern>> _forObjectPattern = [];
  final List<_Subscription<FieldDeclaration>> _forFieldDeclaration = [];
  final List<_Subscription<FieldFormalParameter>> _forFieldFormalParameter = [];
  final List<_Subscription<ForEachPartsWithDeclaration>>
      _forForEachPartsWithDeclaration = [];
  final List<_Subscription<ForEachPartsWithIdentifier>>
      _forForEachPartsWithIdentifier = [];
  final List<_Subscription<ForEachPartsWithPattern>>
      _forForEachPartsWithPattern = [];
  final List<_Subscription<ForElement>> _forForElement = [];
  final List<_Subscription<FormalParameterList>> _forFormalParameterList = [];
  final List<_Subscription<ForPartsWithDeclarations>>
      _forForPartsWithDeclarations = [];
  final List<_Subscription<ForPartsWithExpression>> _forForPartsWithExpression =
      [];
  final List<_Subscription<ForPartsWithPattern>> _forForPartsWithPattern = [];
  final List<_Subscription<ForStatement>> _forForStatement = [];
  final List<_Subscription<FunctionDeclaration>> _forFunctionDeclaration = [];
  final List<_Subscription<FunctionDeclarationStatement>>
      _forFunctionDeclarationStatement = [];
  final List<_Subscription<FunctionExpression>> _forFunctionExpression = [];
  final List<_Subscription<FunctionExpressionInvocation>>
      _forFunctionExpressionInvocation = [];
  final List<_Subscription<FunctionReference>> _forFunctionReference = [];
  final List<_Subscription<FunctionTypeAlias>> _forFunctionTypeAlias = [];
  final List<_Subscription<FunctionTypedFormalParameter>>
      _forFunctionTypedFormalParameter = [];
  final List<_Subscription<GenericFunctionType>> _forGenericFunctionType = [];
  final List<_Subscription<GenericTypeAlias>> _forGenericTypeAlias = [];
  final List<_Subscription<GuardedPattern>> _forGuardedPattern = [];
  final List<_Subscription<HideCombinator>> _forHideCombinator = [];
  final List<_Subscription<IfElement>> _forIfElement = [];
  final List<_Subscription<IfStatement>> _forIfStatement = [];
  final List<_Subscription<ImplementsClause>> _forImplementsClause = [];
  final List<_Subscription<ImplicitCallReference>> _forImplicitCallReference =
      [];
  final List<_Subscription<ImportDirective>> _forImportDirective = [];
  final List<_Subscription<ImportPrefixReference>> _forImportPrefixReference =
      [];
  final List<_Subscription<IndexExpression>> _forIndexExpression = [];
  final List<_Subscription<InstanceCreationExpression>>
      _forInstanceCreationExpression = [];
  final List<_Subscription<IntegerLiteral>> _forIntegerLiteral = [];
  final List<_Subscription<InterpolationExpression>>
      _forInterpolationExpression = [];
  final List<_Subscription<InterpolationString>> _forInterpolationString = [];
  final List<_Subscription<IsExpression>> _forIsExpression = [];
  final List<_Subscription<Label>> _forLabel = [];
  final List<_Subscription<LabeledStatement>> _forLabeledStatement = [];
  final List<_Subscription<LibraryDirective>> _forLibraryDirective = [];
  final List<_Subscription<LibraryIdentifier>> _forLibraryIdentifier = [];
  final List<_Subscription<ListLiteral>> _forListLiteral = [];
  final List<_Subscription<ListPattern>> _forListPattern = [];
  final List<_Subscription<LogicalAndPattern>> _forLogicalAndPattern = [];
  final List<_Subscription<LogicalOrPattern>> _forLogicalOrPattern = [];
  final List<_Subscription<MapLiteralEntry>> _forMapLiteralEntry = [];
  final List<_Subscription<MapPatternEntry>> _forMapPatternEntry = [];
  final List<_Subscription<MapPattern>> _forMapPattern = [];
  final List<_Subscription<MethodDeclaration>> _forMethodDeclaration = [];
  final List<_Subscription<MethodInvocation>> _forMethodInvocation = [];
  final List<_Subscription<MixinDeclaration>> _forMixinDeclaration = [];
  final List<_Subscription<MixinOnClause>> _forMixinOnClause = [];
  final List<_Subscription<NamedExpression>> _forNamedExpression = [];
  final List<_Subscription<NamedType>> _forNamedType = [];
  final List<_Subscription<NativeClause>> _forNativeClause = [];
  final List<_Subscription<NativeFunctionBody>> _forNativeFunctionBody = [];
  final List<_Subscription<NullAssertPattern>> _forNullAssertPattern = [];
  final List<_Subscription<NullAwareElement>> _forNullAwareElement = [];
  final List<_Subscription<NullCheckPattern>> _forNullCheckPattern = [];
  final List<_Subscription<NullLiteral>> _forNullLiteral = [];
  final List<_Subscription<ParenthesizedExpression>>
      _forParenthesizedExpression = [];
  final List<_Subscription<ParenthesizedPattern>> _forParenthesizedPattern = [];
  final List<_Subscription<PartDirective>> _forPartDirective = [];
  final List<_Subscription<PartOfDirective>> _forPartOfDirective = [];
  final List<_Subscription<PatternAssignment>> _forPatternAssignment = [];
  final List<_Subscription<PatternField>> _forPatternField = [];
  final List<_Subscription<PatternFieldName>> _forPatternFieldName = [];
  final List<_Subscription<PatternVariableDeclaration>>
      _forPatternVariableDeclaration = [];
  final List<_Subscription<PatternVariableDeclarationStatement>>
      _forPatternVariableDeclarationStatement = [];
  final List<_Subscription<PostfixExpression>> _forPostfixExpression = [];
  final List<_Subscription<PrefixedIdentifier>> _forPrefixedIdentifier = [];
  final List<_Subscription<PrefixExpression>> _forPrefixExpression = [];
  final List<_Subscription<PropertyAccess>> _forPropertyAccess = [];
  final List<_Subscription<RecordLiteral>> _forRecordLiterals = [];
  final List<_Subscription<RecordPattern>> _forRecordPattern = [];
  final List<_Subscription<RecordTypeAnnotation>> _forRecordTypeAnnotation = [];
  final List<_Subscription<RecordTypeAnnotationNamedField>>
      _forRecordTypeAnnotationNamedField = [];
  final List<_Subscription<RecordTypeAnnotationNamedFields>>
      _forRecordTypeAnnotationNamedFields = [];
  final List<_Subscription<RecordTypeAnnotationPositionalField>>
      _forRecordTypeAnnotationPositionalField = [];
  final List<_Subscription<RedirectingConstructorInvocation>>
      _forRedirectingConstructorInvocation = [];
  final List<_Subscription<RelationalPattern>> _forRelationalPattern = [];
  final List<_Subscription<RestPatternElement>> _forRestPatternElement = [];
  final List<_Subscription<RethrowExpression>> _forRethrowExpression = [];
  final List<_Subscription<ReturnStatement>> _forReturnStatement = [];
  final List<_Subscription<RepresentationConstructorName>>
      _forRepresentationConstructorName = [];
  final List<_Subscription<RepresentationDeclaration>>
      _forRepresentationDeclaration = [];
  final List<_Subscription<ScriptTag>> _forScriptTag = [];
  final List<_Subscription<SetOrMapLiteral>> _forSetOrMapLiteral = [];
  final List<_Subscription<ShowCombinator>> _forShowCombinator = [];
  final List<_Subscription<SimpleFormalParameter>> _forSimpleFormalParameter =
      [];
  final List<_Subscription<SimpleIdentifier>> _forSimpleIdentifier = [];
  final List<_Subscription<SimpleStringLiteral>> _forSimpleStringLiteral = [];
  final List<_Subscription<SpreadElement>> _forSpreadElement = [];
  final List<_Subscription<StringInterpolation>> _forStringInterpolation = [];
  final List<_Subscription<SuperConstructorInvocation>>
      _forSuperConstructorInvocation = [];
  final List<_Subscription<SuperExpression>> _forSuperExpression = [];
  final List<_Subscription<SuperFormalParameter>> _forSuperFormalParameter = [];
  final List<_Subscription<SwitchCase>> _forSwitchCase = [];
  final List<_Subscription<SwitchDefault>> _forSwitchDefault = [];
  final List<_Subscription<SwitchExpressionCase>> _forSwitchExpressionCase = [];
  final List<_Subscription<SwitchExpression>> _forSwitchExpression = [];
  final List<_Subscription<SwitchPatternCase>> _forSwitchPatternCase = [];
  final List<_Subscription<SwitchStatement>> _forSwitchStatement = [];
  final List<_Subscription<SymbolLiteral>> _forSymbolLiteral = [];
  final List<_Subscription<ThisExpression>> _forThisExpression = [];
  final List<_Subscription<ThrowExpression>> _forThrowExpression = [];
  final List<_Subscription<TopLevelVariableDeclaration>>
      _forTopLevelVariableDeclaration = [];
  final List<_Subscription<TryStatement>> _forTryStatement = [];
  final List<_Subscription<TypeArgumentList>> _forTypeArgumentList = [];
  final List<_Subscription<TypeLiteral>> _forTypeLiteral = [];
  final List<_Subscription<TypeParameter>> _forTypeParameter = [];
  final List<_Subscription<TypeParameterList>> _forTypeParameterList = [];
  final List<_Subscription<VariableDeclaration>> _forVariableDeclaration = [];
  final List<_Subscription<VariableDeclarationList>>
      _forVariableDeclarationList = [];
  final List<_Subscription<VariableDeclarationStatement>>
      _forVariableDeclarationStatement = [];
  final List<_Subscription<WhenClause>> _forWhenClause = [];
  final List<_Subscription<WhileStatement>> _forWhileStatement = [];
  final List<_Subscription<WildcardPattern>> _forWildcardPattern = [];
  final List<_Subscription<WithClause>> _forWithClause = [];
  final List<_Subscription<YieldStatement>> _forYieldStatement = [];

  NodeLintRegistry({required bool enableTiming}) : _enableTiming = enableTiming;

  void addAdjacentStrings(AnalysisRule rule, AstVisitor visitor) {
    _forAdjacentStrings.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAnnotation(AnalysisRule rule, AstVisitor visitor) {
    _forAnnotation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addArgumentList(AnalysisRule rule, AstVisitor visitor) {
    _forArgumentList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAsExpression(AnalysisRule rule, AstVisitor visitor) {
    _forAsExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAssertInitializer(AnalysisRule rule, AstVisitor visitor) {
    _forAssertInitializer.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAssertStatement(AnalysisRule rule, AstVisitor visitor) {
    _forAssertStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAssignedVariablePattern(AnalysisRule rule, AstVisitor visitor) {
    _forAssignedVariablePattern
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAssignmentExpression(AnalysisRule rule, AstVisitor visitor) {
    _forAssignmentExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAugmentedExpression(AnalysisRule rule, AstVisitor visitor) {
    _forAugmentedExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAugmentedInvocation(AnalysisRule rule, AstVisitor visitor) {
    _forAugmentedInvocation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addAwaitExpression(AnalysisRule rule, AstVisitor visitor) {
    _forAwaitExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addBinaryExpression(AnalysisRule rule, AstVisitor visitor) {
    _forBinaryExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addBlock(AnalysisRule rule, AstVisitor visitor) {
    _forBlock.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addBlockFunctionBody(AnalysisRule rule, AstVisitor visitor) {
    _forBlockFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addBooleanLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forBooleanLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addBreakStatement(AnalysisRule rule, AstVisitor visitor) {
    _forBreakStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCascadeExpression(AnalysisRule rule, AstVisitor visitor) {
    _forCascadeExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCaseClause(AnalysisRule rule, AstVisitor visitor) {
    _forCaseClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCastPattern(AnalysisRule rule, AstVisitor visitor) {
    _forCastPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCatchClause(AnalysisRule rule, AstVisitor visitor) {
    _forCatchClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCatchClauseParameter(AnalysisRule rule, AstVisitor visitor) {
    _forCatchClauseParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addClassDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forClassDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addClassTypeAlias(AnalysisRule rule, AstVisitor visitor) {
    _forClassTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addComment(AnalysisRule rule, AstVisitor visitor) {
    _forComment.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCommentReference(AnalysisRule rule, AstVisitor visitor) {
    _forCommentReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addCompilationUnit(AnalysisRule rule, AstVisitor visitor) {
    _forCompilationUnit.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConditionalExpression(AnalysisRule rule, AstVisitor visitor) {
    _forConditionalExpression
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConfiguration(AnalysisRule rule, AstVisitor visitor) {
    _forConfiguration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstantPattern(AnalysisRule rule, AstVisitor visitor) {
    _forConstantPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstructorDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forConstructorDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstructorFieldInitializer(AnalysisRule rule, AstVisitor visitor) {
    _forConstructorFieldInitializer
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstructorName(AnalysisRule rule, AstVisitor visitor) {
    _forConstructorName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstructorReference(AnalysisRule rule, AstVisitor visitor) {
    _forConstructorReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addConstructorSelector(AnalysisRule rule, AstVisitor visitor) {
    _forConstructorSelector.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addContinueStatement(AnalysisRule rule, AstVisitor visitor) {
    _forContinueStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDeclaredIdentifier(AnalysisRule rule, AstVisitor visitor) {
    _forDeclaredIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDeclaredVariablePattern(AnalysisRule rule, AstVisitor visitor) {
    _forDeclaredVariablePattern
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDefaultFormalParameter(AnalysisRule rule, AstVisitor visitor) {
    _forDefaultFormalParameter
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDoStatement(AnalysisRule rule, AstVisitor visitor) {
    _forDoStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDottedName(AnalysisRule rule, AstVisitor visitor) {
    _forDottedName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addDoubleLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forDoubleLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addEmptyFunctionBody(AnalysisRule rule, AstVisitor visitor) {
    _forEmptyFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addEmptyStatement(AnalysisRule rule, AstVisitor visitor) {
    _forEmptyStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addEnumConstantArguments(AnalysisRule rule, AstVisitor visitor) {
    _forEnumConstantArguments
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addEnumConstantDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forEnumConstantDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addEnumDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forEnumDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExportDirective(AnalysisRule rule, AstVisitor visitor) {
    _forExportDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExpressionFunctionBody(AnalysisRule rule, AstVisitor visitor) {
    _forExpressionFunctionBody
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExpressionStatement(AnalysisRule rule, AstVisitor visitor) {
    _forExpressionStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExtendsClause(AnalysisRule rule, AstVisitor visitor) {
    _forExtendsClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExtensionDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forExtensionDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExtensionOnClause(AnalysisRule rule, AstVisitor visitor) {
    _forExtensionOnClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExtensionOverride(AnalysisRule rule, AstVisitor visitor) {
    _forExtensionOverride.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addExtensionTypeDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forExtensionTypeDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFieldDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forFieldDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFieldFormalParameter(AnalysisRule rule, AstVisitor visitor) {
    _forFieldFormalParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForEachPartsWithDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forForEachPartsWithDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForEachPartsWithIdentifier(AnalysisRule rule, AstVisitor visitor) {
    _forForEachPartsWithIdentifier
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForEachPartsWithPattern(AnalysisRule rule, AstVisitor visitor) {
    _forForEachPartsWithPattern
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForElement(AnalysisRule rule, AstVisitor visitor) {
    _forForElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFormalParameterList(AnalysisRule rule, AstVisitor visitor) {
    _forFormalParameterList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForPartsWithDeclarations(AnalysisRule rule, AstVisitor visitor) {
    _forForPartsWithDeclarations
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForPartsWithExpression(AnalysisRule rule, AstVisitor visitor) {
    _forForPartsWithExpression
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForPartsWithPattern(AnalysisRule rule, AstVisitor visitor) {
    _forForPartsWithPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addForStatement(AnalysisRule rule, AstVisitor visitor) {
    _forForStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionDeclarationStatement(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionDeclarationStatement
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionExpression(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionExpressionInvocation(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionExpressionInvocation
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionReference(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionTypeAlias(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addFunctionTypedFormalParameter(AnalysisRule rule, AstVisitor visitor) {
    _forFunctionTypedFormalParameter
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addGenericFunctionType(AnalysisRule rule, AstVisitor visitor) {
    _forGenericFunctionType.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addGenericTypeAlias(AnalysisRule rule, AstVisitor visitor) {
    _forGenericTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addGuardedPattern(AnalysisRule rule, AstVisitor visitor) {
    _forGuardedPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addHideCombinator(AnalysisRule rule, AstVisitor visitor) {
    _forHideCombinator.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addIfElement(AnalysisRule rule, AstVisitor visitor) {
    _forIfElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addIfStatement(AnalysisRule rule, AstVisitor visitor) {
    _forIfStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addImplementsClause(AnalysisRule rule, AstVisitor visitor) {
    _forImplementsClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addImplicitCallReference(AnalysisRule rule, AstVisitor visitor) {
    _forImplicitCallReference
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addImportDirective(AnalysisRule rule, AstVisitor visitor) {
    _forImportDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addImportPrefixReference(AnalysisRule rule, AstVisitor visitor) {
    _forImportPrefixReference
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addIndexExpression(AnalysisRule rule, AstVisitor visitor) {
    _forIndexExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addInstanceCreationExpression(AnalysisRule rule, AstVisitor visitor) {
    _forInstanceCreationExpression
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addIntegerLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forIntegerLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addInterpolationExpression(AnalysisRule rule, AstVisitor visitor) {
    _forInterpolationExpression
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addInterpolationString(AnalysisRule rule, AstVisitor visitor) {
    _forInterpolationString.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addIsExpression(AnalysisRule rule, AstVisitor visitor) {
    _forIsExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLabel(AnalysisRule rule, AstVisitor visitor) {
    _forLabel.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLabeledStatement(AnalysisRule rule, AstVisitor visitor) {
    _forLabeledStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLibraryDirective(AnalysisRule rule, AstVisitor visitor) {
    _forLibraryDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLibraryIdentifier(AnalysisRule rule, AstVisitor visitor) {
    _forLibraryIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addListLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forListLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addListPattern(AnalysisRule rule, AstVisitor visitor) {
    _forListPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLogicalAndPattern(AnalysisRule rule, AstVisitor visitor) {
    _forLogicalAndPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addLogicalOrPattern(AnalysisRule rule, AstVisitor visitor) {
    _forLogicalOrPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMapLiteralEntry(AnalysisRule rule, AstVisitor visitor) {
    _forMapLiteralEntry.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMapPattern(AnalysisRule rule, AstVisitor visitor) {
    _forMapPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMapPatternEntry(AnalysisRule rule, AstVisitor visitor) {
    _forMapPatternEntry.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMethodDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forMethodDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMethodInvocation(AnalysisRule rule, AstVisitor visitor) {
    _forMethodInvocation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMixinDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forMixinDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addMixinOnClause(AnalysisRule rule, AstVisitor visitor) {
    _forMixinOnClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNamedExpression(AnalysisRule rule, AstVisitor visitor) {
    _forNamedExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNamedType(AnalysisRule rule, AstVisitor visitor) {
    _forNamedType.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNativeClause(AnalysisRule rule, AstVisitor visitor) {
    _forNativeClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNativeFunctionBody(AnalysisRule rule, AstVisitor visitor) {
    _forNativeFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNullAssertPattern(AnalysisRule rule, AstVisitor visitor) {
    _forNullAssertPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNullCheckPattern(AnalysisRule rule, AstVisitor visitor) {
    _forNullCheckPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addNullLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forNullLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addObjectPattern(AnalysisRule rule, AstVisitor visitor) {
    _forObjectPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addParenthesizedExpression(AnalysisRule rule, AstVisitor visitor) {
    _forParenthesizedExpression
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addParenthesizedPattern(AnalysisRule rule, AstVisitor visitor) {
    _forParenthesizedPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPartDirective(AnalysisRule rule, AstVisitor visitor) {
    _forPartDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPartOfDirective(AnalysisRule rule, AstVisitor visitor) {
    _forPartOfDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPatternAssignment(AnalysisRule rule, AstVisitor visitor) {
    _forPatternAssignment.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPatternField(AnalysisRule rule, AstVisitor visitor) {
    _forPatternField.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPatternFieldName(AnalysisRule rule, AstVisitor visitor) {
    _forPatternFieldName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPatternVariableDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forPatternVariableDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPatternVariableDeclarationStatement(
      AnalysisRule rule, AstVisitor visitor) {
    _forPatternVariableDeclarationStatement
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPostfixExpression(AnalysisRule rule, AstVisitor visitor) {
    _forPostfixExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPrefixedIdentifier(AnalysisRule rule, AstVisitor visitor) {
    _forPrefixedIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPrefixExpression(AnalysisRule rule, AstVisitor visitor) {
    _forPrefixExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addPropertyAccess(AnalysisRule rule, AstVisitor visitor) {
    _forPropertyAccess.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRecordLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forRecordLiterals.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRecordPattern(AnalysisRule rule, AstVisitor visitor) {
    _forRecordPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRecordTypeAnnotation(AnalysisRule rule, AstVisitor visitor) {
    _forRecordTypeAnnotation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRedirectingConstructorInvocation(
      AnalysisRule rule, AstVisitor visitor) {
    _forRedirectingConstructorInvocation
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRelationalPattern(AnalysisRule rule, AstVisitor visitor) {
    _forRelationalPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRepresentationConstructorName(AnalysisRule rule, AstVisitor visitor) {
    _forRepresentationConstructorName
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRepresentationDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forRepresentationDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRestPatternElement(AnalysisRule rule, AstVisitor visitor) {
    _forRestPatternElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addRethrowExpression(AnalysisRule rule, AstVisitor visitor) {
    _forRethrowExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addReturnStatement(AnalysisRule rule, AstVisitor visitor) {
    _forReturnStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addScriptTag(AnalysisRule rule, AstVisitor visitor) {
    _forScriptTag.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSetOrMapLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forSetOrMapLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addShowCombinator(AnalysisRule rule, AstVisitor visitor) {
    _forShowCombinator.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSimpleFormalParameter(AnalysisRule rule, AstVisitor visitor) {
    _forSimpleFormalParameter
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSimpleIdentifier(AnalysisRule rule, AstVisitor visitor) {
    _forSimpleIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSimpleStringLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forSimpleStringLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSpreadElement(AnalysisRule rule, AstVisitor visitor) {
    _forSpreadElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addStringInterpolation(AnalysisRule rule, AstVisitor visitor) {
    _forStringInterpolation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSuperConstructorInvocation(AnalysisRule rule, AstVisitor visitor) {
    _forSuperConstructorInvocation
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSuperExpression(AnalysisRule rule, AstVisitor visitor) {
    _forSuperExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSuperFormalParameter(AnalysisRule rule, AstVisitor visitor) {
    _forSuperFormalParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchCase(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchDefault(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchDefault.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchExpression(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchExpressionCase(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchExpressionCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchPatternCase(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchPatternCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSwitchStatement(AnalysisRule rule, AstVisitor visitor) {
    _forSwitchStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addSymbolLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forSymbolLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addThisExpression(AnalysisRule rule, AstVisitor visitor) {
    _forThisExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addThrowExpression(AnalysisRule rule, AstVisitor visitor) {
    _forThrowExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTopLevelVariableDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forTopLevelVariableDeclaration
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTryStatement(AnalysisRule rule, AstVisitor visitor) {
    _forTryStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTypeArgumentList(AnalysisRule rule, AstVisitor visitor) {
    _forTypeArgumentList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTypeLiteral(AnalysisRule rule, AstVisitor visitor) {
    _forTypeLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTypeParameter(AnalysisRule rule, AstVisitor visitor) {
    _forTypeParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addTypeParameterList(AnalysisRule rule, AstVisitor visitor) {
    _forTypeParameterList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addVariableDeclaration(AnalysisRule rule, AstVisitor visitor) {
    _forVariableDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addVariableDeclarationList(AnalysisRule rule, AstVisitor visitor) {
    _forVariableDeclarationList
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addVariableDeclarationStatement(AnalysisRule rule, AstVisitor visitor) {
    _forVariableDeclarationStatement
        .add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addWhenClause(AnalysisRule rule, AstVisitor visitor) {
    _forWhenClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addWhileStatement(AnalysisRule rule, AstVisitor visitor) {
    _forWhileStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addWithClause(AnalysisRule rule, AstVisitor visitor) {
    _forWithClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void addYieldStatement(AnalysisRule rule, AstVisitor visitor) {
    _forYieldStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  void afterLibrary(AnalysisRule rule, void Function() callback) {
    _afterLibrary
        .add(_AfterLibrarySubscription(rule, callback, _getTimer(rule)));
  }

  /// Get the timer associated with the given [rule].
  Stopwatch? _getTimer(AnalysisRule rule) {
    if (_enableTiming) {
      return analysisRuleTimers.getTimer(rule);
    } else {
      return null;
    }
  }
}

class _AfterLibrarySubscription {
  final AnalysisRule rule;
  final void Function() callback;
  final Stopwatch? timer;

  _AfterLibrarySubscription(this.rule, this.callback, this.timer);
}

/// A single subscription for a node type, by the specified [rule].
class _Subscription<T> {
  final AnalysisRule rule;
  final AstVisitor visitor;
  final Stopwatch? timer;

  _Subscription(this.rule, this.visitor, this.timer);
}
