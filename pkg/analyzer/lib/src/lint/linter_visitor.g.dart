// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'linter_visitor.dart';

/// The AST visitor that runs handlers for nodes from the [_registry].
class AnalysisRuleVisitor implements AstVisitor<void> {
  final RuleVisitorRegistryImpl _registry;

  /// Whether exceptions should be propagated (by rethrowing them).
  final bool _shouldPropagateExceptions;

  AnalysisRuleVisitor(this._registry, {bool shouldPropagateExceptions = false})
    : _shouldPropagateExceptions = shouldPropagateExceptions;

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
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _runSubscriptions(node, _registry._forDotShorthandConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _runSubscriptions(node, _registry._forDotShorthandInvocation);
    node.visitChildren(this);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    _runSubscriptions(node, _registry._forDotShorthandPropertyAccess);
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
    _runSubscriptions(node, _registry._forGuardedPattern);
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
    PatternVariableDeclarationStatement node,
  ) {
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
    _runSubscriptions(node, _registry._forRecordLiteral);
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
    RecordTypeAnnotationNamedField node,
  ) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationNamedField);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationNamedFields);
    node.visitChildren(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    _runSubscriptions(node, _registry._forRecordTypeAnnotationPositionalField);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
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
  void _logException(
    AstNode node,
    AbstractAnalysisRule visitor,
    Object exception,
    StackTrace stackTrace,
  ) {
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
      SilentException(buffer.toString(), exception, stackTrace),
    );
  }

  void _runAfterLibrarySubscriptions(
    List<_AfterLibrarySubscription> subscriptions,
  ) {
    for (var subscription in subscriptions) {
      var timer = subscription.timer;
      timer?.start();
      subscription.callback();
      timer?.stop();
    }
  }

  void _runSubscriptions<T extends AstNode>(
    T node,
    List<_Subscription<T>> subscriptions,
  ) {
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
