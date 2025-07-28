// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'visitor.dart';

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the block to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Clients may extend this class.
class RecursiveAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const RecursiveAstVisitor();

  @override
  R? visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAnnotation(Annotation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAsExpression(AsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAssertInitializer(AssertInitializer node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAssignedVariablePattern(AssignedVariablePattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitAwaitExpression(AwaitExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitBlock(Block node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCaseClause(CaseClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCastPattern(CastPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCatchClause(CatchClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCatchClauseParameter(CatchClauseParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitComment(Comment node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCommentReference(CommentReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConfiguration(Configuration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstantPattern(ConstantPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorReference(ConstructorReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorSelector(ConstructorSelector node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDoStatement(DoStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDotShorthandInvocation(DotShorthandInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDottedName(DottedName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumConstantArguments(EnumConstantArguments node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumDeclaration(EnumDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExportDirective(ExportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionDeclaration(ExtensionDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionOnClause(ExtensionOnClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionOverride(ExtensionOverride node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForElement(ForElement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForPartsWithExpression(ForPartsWithExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForPartsWithPattern(ForPartsWithPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitForStatement(ForStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionReference(FunctionReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitGenericFunctionType(GenericFunctionType node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitGenericTypeAlias(GenericTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitGuardedPattern(GuardedPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitHideCombinator(HideCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitIfElement(IfElement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitIfStatement(IfStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitImplicitCallReference(ImplicitCallReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitImportDirective(ImportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitImportPrefixReference(ImportPrefixReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitInterpolationString(InterpolationString node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitIsExpression(IsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLabel(Label node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitListPattern(ListPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLogicalAndPattern(LogicalAndPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitLogicalOrPattern(LogicalOrPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMapPattern(MapPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMapPatternEntry(MapPatternEntry node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMixinDeclaration(MixinDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitMixinOnClause(MixinOnClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNamedType(NamedType node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNativeClause(NativeClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNullAssertPattern(NullAssertPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNullAwareElement(NullAwareElement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNullCheckPattern(NullCheckPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNullLiteral(NullLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitObjectPattern(ObjectPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitParenthesizedPattern(ParenthesizedPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPartDirective(PartDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPatternAssignment(PatternAssignment node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPatternField(PatternField node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPatternFieldName(PatternFieldName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordLiteral(RecordLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordPattern(RecordPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRelationalPattern(RelationalPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRepresentationConstructorName(RepresentationConstructorName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRepresentationDeclaration(RepresentationDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRestPatternElement(RestPatternElement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitScriptTag(ScriptTag node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSetOrMapLiteral(SetOrMapLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSpreadElement(SpreadElement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSuperExpression(SuperExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSuperFormalParameter(SuperFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchExpression(SwitchExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchExpressionCase(SwitchExpressionCase node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchPatternCase(SwitchPatternCase node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitSymbolLiteral(SymbolLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitThisExpression(ThisExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTryStatement(TryStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeLiteral(TypeLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitWhenClause(WhenClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitWildcardPattern(WildcardPattern node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitWithClause(WithClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitYieldStatement(YieldStatement node) {
    node.visitChildren(this);
    return null;
  }
}

/// An AST visitor that will do nothing when visiting an AST node. It is
/// intended to be a superclass for classes that use the visitor pattern
/// primarily as a dispatch mechanism (and hence don't need to recursively visit
/// a whole structure) and that only need to visit a small number of node types.
///
/// Clients may extend this class.
class SimpleAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const SimpleAstVisitor();
  @override
  R? visitAdjacentStrings(AdjacentStrings node) => null;

  @override
  R? visitAnnotation(Annotation node) => null;

  @override
  R? visitArgumentList(ArgumentList node) => null;

  @override
  R? visitAsExpression(AsExpression node) => null;

  @override
  R? visitAssertInitializer(AssertInitializer node) => null;

  @override
  R? visitAssertStatement(AssertStatement node) => null;

  @override
  R? visitAssignedVariablePattern(AssignedVariablePattern node) => null;

  @override
  R? visitAssignmentExpression(AssignmentExpression node) => null;

  @override
  R? visitAwaitExpression(AwaitExpression node) => null;

  @override
  R? visitBinaryExpression(BinaryExpression node) => null;

  @override
  R? visitBlock(Block node) => null;

  @override
  R? visitBlockFunctionBody(BlockFunctionBody node) => null;

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => null;

  @override
  R? visitBreakStatement(BreakStatement node) => null;

  @override
  R? visitCascadeExpression(CascadeExpression node) => null;

  @override
  R? visitCaseClause(CaseClause node) => null;

  @override
  R? visitCastPattern(CastPattern node) => null;

  @override
  R? visitCatchClause(CatchClause node) => null;

  @override
  R? visitCatchClauseParameter(CatchClauseParameter node) => null;

  @override
  R? visitClassDeclaration(ClassDeclaration node) => null;

  @override
  R? visitClassTypeAlias(ClassTypeAlias node) => null;

  @override
  R? visitComment(Comment node) => null;

  @override
  R? visitCommentReference(CommentReference node) => null;

  @override
  R? visitCompilationUnit(CompilationUnit node) => null;

  @override
  R? visitConditionalExpression(ConditionalExpression node) => null;

  @override
  R? visitConfiguration(Configuration node) => null;

  @override
  R? visitConstantPattern(ConstantPattern node) => null;

  @override
  R? visitConstructorDeclaration(ConstructorDeclaration node) => null;

  @override
  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node) => null;

  @override
  R? visitConstructorName(ConstructorName node) => null;

  @override
  R? visitConstructorReference(ConstructorReference node) => null;

  @override
  R? visitConstructorSelector(ConstructorSelector node) => null;

  @override
  R? visitContinueStatement(ContinueStatement node) => null;

  @override
  R? visitDeclaredIdentifier(DeclaredIdentifier node) => null;

  @override
  R? visitDeclaredVariablePattern(DeclaredVariablePattern node) => null;

  @override
  R? visitDefaultFormalParameter(DefaultFormalParameter node) => null;

  @override
  R? visitDoStatement(DoStatement node) => null;

  @override
  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => null;

  @override
  R? visitDotShorthandInvocation(DotShorthandInvocation node) => null;

  @override
  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) => null;

  @override
  R? visitDottedName(DottedName node) => null;

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => null;

  @override
  R? visitEmptyFunctionBody(EmptyFunctionBody node) => null;

  @override
  R? visitEmptyStatement(EmptyStatement node) => null;

  @override
  R? visitEnumConstantArguments(EnumConstantArguments node) => null;

  @override
  R? visitEnumConstantDeclaration(EnumConstantDeclaration node) => null;

  @override
  R? visitEnumDeclaration(EnumDeclaration node) => null;

  @override
  R? visitExportDirective(ExportDirective node) => null;

  @override
  R? visitExpressionFunctionBody(ExpressionFunctionBody node) => null;

  @override
  R? visitExpressionStatement(ExpressionStatement node) => null;

  @override
  R? visitExtendsClause(ExtendsClause node) => null;

  @override
  R? visitExtensionDeclaration(ExtensionDeclaration node) => null;

  @override
  R? visitExtensionOnClause(ExtensionOnClause node) => null;

  @override
  R? visitExtensionOverride(ExtensionOverride node) => null;

  @override
  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) => null;

  @override
  R? visitFieldDeclaration(FieldDeclaration node) => null;

  @override
  R? visitFieldFormalParameter(FieldFormalParameter node) => null;

  @override
  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) => null;

  @override
  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) => null;

  @override
  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node) => null;

  @override
  R? visitForElement(ForElement node) => null;

  @override
  R? visitFormalParameterList(FormalParameterList node) => null;

  @override
  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node) => null;

  @override
  R? visitForPartsWithExpression(ForPartsWithExpression node) => null;

  @override
  R? visitForPartsWithPattern(ForPartsWithPattern node) => null;

  @override
  R? visitForStatement(ForStatement node) => null;

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) => null;

  @override
  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      null;

  @override
  R? visitFunctionExpression(FunctionExpression node) => null;

  @override
  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      null;

  @override
  R? visitFunctionReference(FunctionReference node) => null;

  @override
  R? visitFunctionTypeAlias(FunctionTypeAlias node) => null;

  @override
  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      null;

  @override
  R? visitGenericFunctionType(GenericFunctionType node) => null;

  @override
  R? visitGenericTypeAlias(GenericTypeAlias node) => null;

  @override
  R? visitGuardedPattern(GuardedPattern node) => null;

  @override
  R? visitHideCombinator(HideCombinator node) => null;

  @override
  R? visitIfElement(IfElement node) => null;

  @override
  R? visitIfStatement(IfStatement node) => null;

  @override
  R? visitImplementsClause(ImplementsClause node) => null;

  @override
  R? visitImplicitCallReference(ImplicitCallReference node) => null;

  @override
  R? visitImportDirective(ImportDirective node) => null;

  @override
  R? visitImportPrefixReference(ImportPrefixReference node) => null;

  @override
  R? visitIndexExpression(IndexExpression node) => null;

  @override
  R? visitInstanceCreationExpression(InstanceCreationExpression node) => null;

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => null;

  @override
  R? visitInterpolationExpression(InterpolationExpression node) => null;

  @override
  R? visitInterpolationString(InterpolationString node) => null;

  @override
  R? visitIsExpression(IsExpression node) => null;

  @override
  R? visitLabel(Label node) => null;

  @override
  R? visitLabeledStatement(LabeledStatement node) => null;

  @override
  R? visitLibraryDirective(LibraryDirective node) => null;

  @override
  R? visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  R? visitListLiteral(ListLiteral node) => null;

  @override
  R? visitListPattern(ListPattern node) => null;

  @override
  R? visitLogicalAndPattern(LogicalAndPattern node) => null;

  @override
  R? visitLogicalOrPattern(LogicalOrPattern node) => null;

  @override
  R? visitMapLiteralEntry(MapLiteralEntry node) => null;

  @override
  R? visitMapPattern(MapPattern node) => null;

  @override
  R? visitMapPatternEntry(MapPatternEntry node) => null;

  @override
  R? visitMethodDeclaration(MethodDeclaration node) => null;

  @override
  R? visitMethodInvocation(MethodInvocation node) => null;

  @override
  R? visitMixinDeclaration(MixinDeclaration node) => null;

  @override
  R? visitMixinOnClause(MixinOnClause node) => null;

  @override
  R? visitNamedExpression(NamedExpression node) => null;

  @override
  R? visitNamedType(NamedType node) => null;

  @override
  R? visitNativeClause(NativeClause node) => null;

  @override
  R? visitNativeFunctionBody(NativeFunctionBody node) => null;

  @override
  R? visitNullAssertPattern(NullAssertPattern node) => null;

  @override
  R? visitNullAwareElement(NullAwareElement node) => null;

  @override
  R? visitNullCheckPattern(NullCheckPattern node) => null;

  @override
  R? visitNullLiteral(NullLiteral node) => null;

  @override
  R? visitObjectPattern(ObjectPattern node) => null;

  @override
  R? visitParenthesizedExpression(ParenthesizedExpression node) => null;

  @override
  R? visitParenthesizedPattern(ParenthesizedPattern node) => null;

  @override
  R? visitPartDirective(PartDirective node) => null;

  @override
  R? visitPartOfDirective(PartOfDirective node) => null;

  @override
  R? visitPatternAssignment(PatternAssignment node) => null;

  @override
  R? visitPatternField(PatternField node) => null;

  @override
  R? visitPatternFieldName(PatternFieldName node) => null;

  @override
  R? visitPatternVariableDeclaration(PatternVariableDeclaration node) => null;

  @override
  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) => null;

  @override
  R? visitPostfixExpression(PostfixExpression node) => null;

  @override
  R? visitPrefixedIdentifier(PrefixedIdentifier node) => null;

  @override
  R? visitPrefixExpression(PrefixExpression node) => null;

  @override
  R? visitPropertyAccess(PropertyAccess node) => null;

  @override
  R? visitRecordLiteral(RecordLiteral node) => null;

  @override
  R? visitRecordPattern(RecordPattern node) => null;

  @override
  R? visitRecordTypeAnnotation(RecordTypeAnnotation node) => null;

  @override
  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) =>
      null;

  @override
  R? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) => null;

  @override
  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) => null;

  @override
  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) => null;

  @override
  R? visitRelationalPattern(RelationalPattern node) => null;

  @override
  R? visitRepresentationConstructorName(RepresentationConstructorName node) =>
      null;

  @override
  R? visitRepresentationDeclaration(RepresentationDeclaration node) => null;

  @override
  R? visitRestPatternElement(RestPatternElement node) => null;

  @override
  R? visitRethrowExpression(RethrowExpression node) => null;

  @override
  R? visitReturnStatement(ReturnStatement node) => null;

  @override
  R? visitScriptTag(ScriptTag node) => null;

  @override
  R? visitSetOrMapLiteral(SetOrMapLiteral node) => null;

  @override
  R? visitShowCombinator(ShowCombinator node) => null;

  @override
  R? visitSimpleFormalParameter(SimpleFormalParameter node) => null;

  @override
  R? visitSimpleIdentifier(SimpleIdentifier node) => null;

  @override
  R? visitSimpleStringLiteral(SimpleStringLiteral node) => null;

  @override
  R? visitSpreadElement(SpreadElement node) => null;

  @override
  R? visitStringInterpolation(StringInterpolation node) => null;

  @override
  R? visitSuperConstructorInvocation(SuperConstructorInvocation node) => null;

  @override
  R? visitSuperExpression(SuperExpression node) => null;

  @override
  R? visitSuperFormalParameter(SuperFormalParameter node) => null;

  @override
  R? visitSwitchCase(SwitchCase node) => null;

  @override
  R? visitSwitchDefault(SwitchDefault node) => null;

  @override
  R? visitSwitchExpression(SwitchExpression node) => null;

  @override
  R? visitSwitchExpressionCase(SwitchExpressionCase node) => null;

  @override
  R? visitSwitchPatternCase(SwitchPatternCase node) => null;

  @override
  R? visitSwitchStatement(SwitchStatement node) => null;

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => null;

  @override
  R? visitThisExpression(ThisExpression node) => null;

  @override
  R? visitThrowExpression(ThrowExpression node) => null;

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => null;

  @override
  R? visitTryStatement(TryStatement node) => null;

  @override
  R? visitTypeArgumentList(TypeArgumentList node) => null;

  @override
  R? visitTypeLiteral(TypeLiteral node) => null;

  @override
  R? visitTypeParameter(TypeParameter node) => null;

  @override
  R? visitTypeParameterList(TypeParameterList node) => null;

  @override
  R? visitVariableDeclaration(VariableDeclaration node) => null;

  @override
  R? visitVariableDeclarationList(VariableDeclarationList node) => null;

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      null;

  @override
  R? visitWhenClause(WhenClause node) => null;

  @override
  R? visitWhileStatement(WhileStatement node) => null;

  @override
  R? visitWildcardPattern(WildcardPattern node) => null;

  @override
  R? visitWithClause(WithClause node) => null;

  @override
  R? visitYieldStatement(YieldStatement node) => null;
}

/// An AST visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden. It is intended to be a superclass for
/// classes that implement the visitor pattern and need to (a) override all of
/// the visit methods or (b) need to override a subset of the visit method and
/// want to catch when any other visit methods have been invoked.
///
/// Clients may extend this class.
class ThrowingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const ThrowingAstVisitor();

  @override
  R? visitAdjacentStrings(AdjacentStrings node) => _throw(node);

  @override
  R? visitAnnotation(Annotation node) => _throw(node);

  @override
  R? visitArgumentList(ArgumentList node) => _throw(node);

  @override
  R? visitAsExpression(AsExpression node) => _throw(node);

  @override
  R? visitAssertInitializer(AssertInitializer node) => _throw(node);

  @override
  R? visitAssertStatement(AssertStatement node) => _throw(node);

  @override
  R? visitAssignedVariablePattern(AssignedVariablePattern node) => _throw(node);

  @override
  R? visitAssignmentExpression(AssignmentExpression node) => _throw(node);

  @override
  R? visitAwaitExpression(AwaitExpression node) => _throw(node);

  @override
  R? visitBinaryExpression(BinaryExpression node) => _throw(node);

  @override
  R? visitBlock(Block node) => _throw(node);

  @override
  R? visitBlockFunctionBody(BlockFunctionBody node) => _throw(node);

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => _throw(node);

  @override
  R? visitBreakStatement(BreakStatement node) => _throw(node);

  @override
  R? visitCascadeExpression(CascadeExpression node) => _throw(node);

  @override
  R? visitCaseClause(CaseClause node) => _throw(node);

  @override
  R? visitCastPattern(CastPattern node) => _throw(node);

  @override
  R? visitCatchClause(CatchClause node) => _throw(node);

  @override
  R? visitCatchClauseParameter(CatchClauseParameter node) => _throw(node);

  @override
  R? visitClassDeclaration(ClassDeclaration node) => _throw(node);

  @override
  R? visitClassTypeAlias(ClassTypeAlias node) => _throw(node);

  @override
  R? visitComment(Comment node) => _throw(node);

  @override
  R? visitCommentReference(CommentReference node) => _throw(node);

  @override
  R? visitCompilationUnit(CompilationUnit node) => _throw(node);

  @override
  R? visitConditionalExpression(ConditionalExpression node) => _throw(node);

  @override
  R? visitConfiguration(Configuration node) => _throw(node);

  @override
  R? visitConstantPattern(ConstantPattern node) => _throw(node);

  @override
  R? visitConstructorDeclaration(ConstructorDeclaration node) => _throw(node);

  @override
  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      _throw(node);

  @override
  R? visitConstructorName(ConstructorName node) => _throw(node);

  @override
  R? visitConstructorReference(ConstructorReference node) => _throw(node);

  @override
  R? visitConstructorSelector(ConstructorSelector node) => _throw(node);

  @override
  R? visitContinueStatement(ContinueStatement node) => _throw(node);

  @override
  R? visitDeclaredIdentifier(DeclaredIdentifier node) => _throw(node);

  @override
  R? visitDeclaredVariablePattern(DeclaredVariablePattern node) => _throw(node);

  @override
  R? visitDefaultFormalParameter(DefaultFormalParameter node) => _throw(node);

  @override
  R? visitDoStatement(DoStatement node) => _throw(node);

  @override
  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _throw(node);

  @override
  R? visitDotShorthandInvocation(DotShorthandInvocation node) => _throw(node);

  @override
  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      _throw(node);

  @override
  R? visitDottedName(DottedName node) => _throw(node);

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => _throw(node);

  @override
  R? visitEmptyFunctionBody(EmptyFunctionBody node) => _throw(node);

  @override
  R? visitEmptyStatement(EmptyStatement node) => _throw(node);

  @override
  R? visitEnumConstantArguments(EnumConstantArguments node) => _throw(node);

  @override
  R? visitEnumConstantDeclaration(EnumConstantDeclaration node) => _throw(node);

  @override
  R? visitEnumDeclaration(EnumDeclaration node) => _throw(node);

  @override
  R? visitExportDirective(ExportDirective node) => _throw(node);

  @override
  R? visitExpressionFunctionBody(ExpressionFunctionBody node) => _throw(node);

  @override
  R? visitExpressionStatement(ExpressionStatement node) => _throw(node);

  @override
  R? visitExtendsClause(ExtendsClause node) => _throw(node);

  @override
  R? visitExtensionDeclaration(ExtensionDeclaration node) => _throw(node);

  @override
  R? visitExtensionOnClause(ExtensionOnClause node) => _throw(node);

  @override
  R? visitExtensionOverride(ExtensionOverride node) => _throw(node);

  @override
  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _throw(node);

  @override
  R? visitFieldDeclaration(FieldDeclaration node) => _throw(node);

  @override
  R? visitFieldFormalParameter(FieldFormalParameter node) => _throw(node);

  @override
  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) =>
      _throw(node);

  @override
  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) =>
      _throw(node);

  @override
  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node) => _throw(node);

  @override
  R? visitForElement(ForElement node) => _throw(node);

  @override
  R? visitFormalParameterList(FormalParameterList node) => _throw(node);

  @override
  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node) =>
      _throw(node);

  @override
  R? visitForPartsWithExpression(ForPartsWithExpression node) => _throw(node);

  @override
  R? visitForPartsWithPattern(ForPartsWithPattern node) => _throw(node);

  @override
  R? visitForStatement(ForStatement node) => _throw(node);

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) => _throw(node);

  @override
  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      _throw(node);

  @override
  R? visitFunctionExpression(FunctionExpression node) => _throw(node);

  @override
  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _throw(node);

  @override
  R? visitFunctionReference(FunctionReference node) => _throw(node);

  @override
  R? visitFunctionTypeAlias(FunctionTypeAlias node) => _throw(node);

  @override
  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      _throw(node);

  @override
  R? visitGenericFunctionType(GenericFunctionType node) => _throw(node);

  @override
  R? visitGenericTypeAlias(GenericTypeAlias node) => _throw(node);

  @override
  R? visitGuardedPattern(GuardedPattern node) => _throw(node);

  @override
  R? visitHideCombinator(HideCombinator node) => _throw(node);

  @override
  R? visitIfElement(IfElement node) => _throw(node);

  @override
  R? visitIfStatement(IfStatement node) => _throw(node);

  @override
  R? visitImplementsClause(ImplementsClause node) => _throw(node);

  @override
  R? visitImplicitCallReference(ImplicitCallReference node) => _throw(node);

  @override
  R? visitImportDirective(ImportDirective node) => _throw(node);

  @override
  R? visitImportPrefixReference(ImportPrefixReference node) => _throw(node);

  @override
  R? visitIndexExpression(IndexExpression node) => _throw(node);

  @override
  R? visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _throw(node);

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => _throw(node);

  @override
  R? visitInterpolationExpression(InterpolationExpression node) => _throw(node);

  @override
  R? visitInterpolationString(InterpolationString node) => _throw(node);

  @override
  R? visitIsExpression(IsExpression node) => _throw(node);

  @override
  R? visitLabel(Label node) => _throw(node);

  @override
  R? visitLabeledStatement(LabeledStatement node) => _throw(node);

  @override
  R? visitLibraryDirective(LibraryDirective node) => _throw(node);

  @override
  R? visitLibraryIdentifier(LibraryIdentifier node) => _throw(node);

  @override
  R? visitListLiteral(ListLiteral node) => _throw(node);

  @override
  R? visitListPattern(ListPattern node) => _throw(node);

  @override
  R? visitLogicalAndPattern(LogicalAndPattern node) => _throw(node);

  @override
  R? visitLogicalOrPattern(LogicalOrPattern node) => _throw(node);

  @override
  R? visitMapLiteralEntry(MapLiteralEntry node) => _throw(node);

  @override
  R? visitMapPattern(MapPattern node) => _throw(node);

  @override
  R? visitMapPatternEntry(MapPatternEntry node) => _throw(node);

  @override
  R? visitMethodDeclaration(MethodDeclaration node) => _throw(node);

  @override
  R? visitMethodInvocation(MethodInvocation node) => _throw(node);

  @override
  R? visitMixinDeclaration(MixinDeclaration node) => _throw(node);

  @override
  R? visitMixinOnClause(MixinOnClause node) => _throw(node);

  @override
  R? visitNamedExpression(NamedExpression node) => _throw(node);

  @override
  R? visitNamedType(NamedType node) => _throw(node);

  @override
  R? visitNativeClause(NativeClause node) => _throw(node);

  @override
  R? visitNativeFunctionBody(NativeFunctionBody node) => _throw(node);

  @override
  R? visitNullAssertPattern(NullAssertPattern node) => _throw(node);

  @override
  R? visitNullAwareElement(NullAwareElement node) => _throw(node);

  @override
  R? visitNullCheckPattern(NullCheckPattern node) => _throw(node);

  @override
  R? visitNullLiteral(NullLiteral node) => _throw(node);

  @override
  R? visitObjectPattern(ObjectPattern node) => _throw(node);

  @override
  R? visitParenthesizedExpression(ParenthesizedExpression node) => _throw(node);

  @override
  R? visitParenthesizedPattern(ParenthesizedPattern node) => _throw(node);

  @override
  R? visitPartDirective(PartDirective node) => _throw(node);

  @override
  R? visitPartOfDirective(PartOfDirective node) => _throw(node);

  @override
  R? visitPatternAssignment(PatternAssignment node) => _throw(node);

  @override
  R? visitPatternField(PatternField node) => _throw(node);

  @override
  R? visitPatternFieldName(PatternFieldName node) => _throw(node);

  @override
  R? visitPatternVariableDeclaration(PatternVariableDeclaration node) =>
      _throw(node);

  @override
  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) => _throw(node);

  @override
  R? visitPostfixExpression(PostfixExpression node) => _throw(node);

  @override
  R? visitPrefixedIdentifier(PrefixedIdentifier node) => _throw(node);

  @override
  R? visitPrefixExpression(PrefixExpression node) => _throw(node);

  @override
  R? visitPropertyAccess(PropertyAccess node) => _throw(node);

  @override
  R? visitRecordLiteral(RecordLiteral node) => _throw(node);

  @override
  R? visitRecordPattern(RecordPattern node) => _throw(node);

  @override
  R? visitRecordTypeAnnotation(RecordTypeAnnotation node) => _throw(node);

  @override
  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) =>
      _throw(node);

  @override
  R? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) => _throw(node);

  @override
  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) => _throw(node);

  @override
  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) => _throw(node);

  @override
  R? visitRelationalPattern(RelationalPattern node) => _throw(node);

  @override
  R? visitRepresentationConstructorName(RepresentationConstructorName node) =>
      _throw(node);

  @override
  R? visitRepresentationDeclaration(RepresentationDeclaration node) =>
      _throw(node);

  @override
  R? visitRestPatternElement(RestPatternElement node) => _throw(node);

  @override
  R? visitRethrowExpression(RethrowExpression node) => _throw(node);

  @override
  R? visitReturnStatement(ReturnStatement node) => _throw(node);

  @override
  R? visitScriptTag(ScriptTag node) => _throw(node);

  @override
  R? visitSetOrMapLiteral(SetOrMapLiteral node) => _throw(node);

  @override
  R? visitShowCombinator(ShowCombinator node) => _throw(node);

  @override
  R? visitSimpleFormalParameter(SimpleFormalParameter node) => _throw(node);

  @override
  R? visitSimpleIdentifier(SimpleIdentifier node) => _throw(node);

  @override
  R? visitSimpleStringLiteral(SimpleStringLiteral node) => _throw(node);

  @override
  R? visitSpreadElement(SpreadElement node) => _throw(node);

  @override
  R? visitStringInterpolation(StringInterpolation node) => _throw(node);

  @override
  R? visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      _throw(node);

  @override
  R? visitSuperExpression(SuperExpression node) => _throw(node);

  @override
  R? visitSuperFormalParameter(SuperFormalParameter node) => _throw(node);

  @override
  R? visitSwitchCase(SwitchCase node) => _throw(node);

  @override
  R? visitSwitchDefault(SwitchDefault node) => _throw(node);

  @override
  R? visitSwitchExpression(SwitchExpression node) => _throw(node);

  @override
  R? visitSwitchExpressionCase(SwitchExpressionCase node) => _throw(node);

  @override
  R? visitSwitchPatternCase(SwitchPatternCase node) => _throw(node);

  @override
  R? visitSwitchStatement(SwitchStatement node) => _throw(node);

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => _throw(node);

  @override
  R? visitThisExpression(ThisExpression node) => _throw(node);

  @override
  R? visitThrowExpression(ThrowExpression node) => _throw(node);

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _throw(node);

  @override
  R? visitTryStatement(TryStatement node) => _throw(node);

  @override
  R? visitTypeArgumentList(TypeArgumentList node) => _throw(node);

  @override
  R? visitTypeLiteral(TypeLiteral node) => _throw(node);

  @override
  R? visitTypeParameter(TypeParameter node) => _throw(node);

  @override
  R? visitTypeParameterList(TypeParameterList node) => _throw(node);

  @override
  R? visitVariableDeclaration(VariableDeclaration node) => _throw(node);

  @override
  R? visitVariableDeclarationList(VariableDeclarationList node) => _throw(node);

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      _throw(node);

  @override
  R? visitWhenClause(WhenClause node) => _throw(node);

  @override
  R? visitWhileStatement(WhileStatement node) => _throw(node);

  @override
  R? visitWildcardPattern(WildcardPattern node) => _throw(node);

  @override
  R? visitWithClause(WithClause node) => _throw(node);

  @override
  R? visitYieldStatement(YieldStatement node) => _throw(node);

  Never _throw(AstNode node) {
    var typeName = node.runtimeType.toString();
    if (typeName.endsWith('Impl')) {
      typeName = typeName.substring(0, typeName.length - 4);
    }
    throw Exception('Missing implementation of visit$typeName');
  }
}

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor]). In addition,
/// every node will also be visited by using a single unified [visitNode]
/// method.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general [visitNode] method.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Clients may extend this class.
class UnifyingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const UnifyingAstVisitor();

  @override
  R? visitAdjacentStrings(AdjacentStrings node) => visitNode(node);

  @override
  R? visitAnnotation(Annotation node) => visitNode(node);

  @override
  R? visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R? visitAsExpression(AsExpression node) => visitNode(node);

  @override
  R? visitAssertInitializer(AssertInitializer node) => visitNode(node);

  @override
  R? visitAssertStatement(AssertStatement node) => visitNode(node);

  @override
  R? visitAssignedVariablePattern(AssignedVariablePattern node) =>
      visitNode(node);

  @override
  R? visitAssignmentExpression(AssignmentExpression node) => visitNode(node);

  @override
  R? visitAwaitExpression(AwaitExpression node) => visitNode(node);

  @override
  R? visitBinaryExpression(BinaryExpression node) => visitNode(node);

  @override
  R? visitBlock(Block node) => visitNode(node);

  @override
  R? visitBlockFunctionBody(BlockFunctionBody node) => visitNode(node);

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  R? visitBreakStatement(BreakStatement node) => visitNode(node);

  @override
  R? visitCascadeExpression(CascadeExpression node) => visitNode(node);

  @override
  R? visitCaseClause(CaseClause node) => visitNode(node);

  @override
  R? visitCastPattern(CastPattern node) => visitNode(node);

  @override
  R? visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R? visitCatchClauseParameter(CatchClauseParameter node) => visitNode(node);

  @override
  R? visitClassDeclaration(ClassDeclaration node) => visitNode(node);

  @override
  R? visitClassTypeAlias(ClassTypeAlias node) => visitNode(node);

  @override
  R? visitComment(Comment node) => visitNode(node);

  @override
  R? visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R? visitCompilationUnit(CompilationUnit node) => visitNode(node);

  @override
  R? visitConditionalExpression(ConditionalExpression node) => visitNode(node);

  @override
  R? visitConfiguration(Configuration node) => visitNode(node);

  @override
  R? visitConstantPattern(ConstantPattern node) => visitNode(node);

  @override
  R? visitConstructorDeclaration(ConstructorDeclaration node) =>
      visitNode(node);

  @override
  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitNode(node);

  @override
  R? visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R? visitConstructorReference(ConstructorReference node) => visitNode(node);

  @override
  R? visitConstructorSelector(ConstructorSelector node) => visitNode(node);

  @override
  R? visitContinueStatement(ContinueStatement node) => visitNode(node);

  @override
  R? visitDeclaredIdentifier(DeclaredIdentifier node) => visitNode(node);

  @override
  R? visitDeclaredVariablePattern(DeclaredVariablePattern node) =>
      visitNode(node);

  @override
  R? visitDefaultFormalParameter(DefaultFormalParameter node) =>
      visitNode(node);

  @override
  R? visitDoStatement(DoStatement node) => visitNode(node);

  @override
  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => visitNode(node);

  @override
  R? visitDotShorthandInvocation(DotShorthandInvocation node) =>
      visitNode(node);

  @override
  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      visitNode(node);

  @override
  R? visitDottedName(DottedName node) => visitNode(node);

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  R? visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  R? visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  R? visitEnumConstantArguments(EnumConstantArguments node) => visitNode(node);

  @override
  R? visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitNode(node);

  @override
  R? visitEnumDeclaration(EnumDeclaration node) => visitNode(node);

  @override
  R? visitExportDirective(ExportDirective node) => visitNode(node);

  @override
  R? visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      visitNode(node);

  @override
  R? visitExpressionStatement(ExpressionStatement node) => visitNode(node);

  @override
  R? visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R? visitExtensionDeclaration(ExtensionDeclaration node) => visitNode(node);

  @override
  R? visitExtensionOnClause(ExtensionOnClause node) => visitNode(node);

  @override
  R? visitExtensionOverride(ExtensionOverride node) => visitNode(node);

  @override
  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      visitNode(node);

  @override
  R? visitFieldDeclaration(FieldDeclaration node) => visitNode(node);

  @override
  R? visitFieldFormalParameter(FieldFormalParameter node) => visitNode(node);

  @override
  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) =>
      visitNode(node);

  @override
  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) =>
      visitNode(node);

  @override
  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node) =>
      visitNode(node);

  @override
  R? visitForElement(ForElement node) => visitNode(node);

  @override
  R? visitFormalParameterList(FormalParameterList node) => visitNode(node);

  @override
  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node) =>
      visitNode(node);

  @override
  R? visitForPartsWithExpression(ForPartsWithExpression node) =>
      visitNode(node);

  @override
  R? visitForPartsWithPattern(ForPartsWithPattern node) => visitNode(node);

  @override
  R? visitForStatement(ForStatement node) => visitNode(node);

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) => visitNode(node);

  @override
  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitNode(node);

  @override
  R? visitFunctionExpression(FunctionExpression node) => visitNode(node);

  @override
  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitNode(node);

  @override
  R? visitFunctionReference(FunctionReference node) => visitNode(node);

  @override
  R? visitFunctionTypeAlias(FunctionTypeAlias node) => visitNode(node);

  @override
  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNode(node);

  @override
  R? visitGenericFunctionType(GenericFunctionType node) => visitNode(node);

  @override
  R? visitGenericTypeAlias(GenericTypeAlias node) => visitNode(node);

  @override
  R? visitGuardedPattern(GuardedPattern node) => visitNode(node);

  @override
  R? visitHideCombinator(HideCombinator node) => visitNode(node);

  @override
  R? visitIfElement(IfElement node) => visitNode(node);

  @override
  R? visitIfStatement(IfStatement node) => visitNode(node);

  @override
  R? visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R? visitImplicitCallReference(ImplicitCallReference node) => visitNode(node);

  @override
  R? visitImportDirective(ImportDirective node) => visitNode(node);

  @override
  R? visitImportPrefixReference(ImportPrefixReference node) => visitNode(node);

  @override
  R? visitIndexExpression(IndexExpression node) => visitNode(node);

  @override
  R? visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitNode(node);

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  R? visitInterpolationExpression(InterpolationExpression node) =>
      visitNode(node);

  @override
  R? visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  R? visitIsExpression(IsExpression node) => visitNode(node);

  @override
  R? visitLabel(Label node) => visitNode(node);

  @override
  R? visitLabeledStatement(LabeledStatement node) => visitNode(node);

  @override
  R? visitLibraryDirective(LibraryDirective node) => visitNode(node);

  @override
  R? visitLibraryIdentifier(LibraryIdentifier node) => visitNode(node);

  @override
  R? visitListLiteral(ListLiteral node) => visitNode(node);

  @override
  R? visitListPattern(ListPattern node) => visitNode(node);

  @override
  R? visitLogicalAndPattern(LogicalAndPattern node) => visitNode(node);

  @override
  R? visitLogicalOrPattern(LogicalOrPattern node) => visitNode(node);

  @override
  R? visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  @override
  R? visitMapPattern(MapPattern node) => visitNode(node);

  @override
  R? visitMapPatternEntry(MapPatternEntry node) => visitNode(node);

  @override
  R? visitMethodDeclaration(MethodDeclaration node) => visitNode(node);

  @override
  R? visitMethodInvocation(MethodInvocation node) => visitNode(node);

  @override
  R? visitMixinDeclaration(MixinDeclaration node) => visitNode(node);

  @override
  R? visitMixinOnClause(MixinOnClause node) => visitNode(node);

  @override
  R? visitNamedExpression(NamedExpression node) => visitNode(node);

  @override
  R? visitNamedType(NamedType node) => visitNode(node);

  @override
  R? visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R? visitNativeFunctionBody(NativeFunctionBody node) => visitNode(node);

  R? visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R? visitNullAssertPattern(NullAssertPattern node) => visitNode(node);

  @override
  R? visitNullAwareElement(NullAwareElement node) => visitNode(node);

  @override
  R? visitNullCheckPattern(NullCheckPattern node) => visitNode(node);

  @override
  R? visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  R? visitObjectPattern(ObjectPattern node) => visitNode(node);

  @override
  R? visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitNode(node);

  @override
  R? visitParenthesizedPattern(ParenthesizedPattern node) => visitNode(node);

  @override
  R? visitPartDirective(PartDirective node) => visitNode(node);

  @override
  R? visitPartOfDirective(PartOfDirective node) => visitNode(node);

  @override
  R? visitPatternAssignment(PatternAssignment node) => visitNode(node);

  @override
  R? visitPatternField(PatternField node) => visitNode(node);

  @override
  R? visitPatternFieldName(PatternFieldName node) => visitNode(node);

  @override
  R? visitPatternVariableDeclaration(PatternVariableDeclaration node) =>
      visitNode(node);

  @override
  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) => visitNode(node);

  @override
  R? visitPostfixExpression(PostfixExpression node) => visitNode(node);

  @override
  R? visitPrefixedIdentifier(PrefixedIdentifier node) => visitNode(node);

  @override
  R? visitPrefixExpression(PrefixExpression node) => visitNode(node);

  @override
  R? visitPropertyAccess(PropertyAccess node) => visitNode(node);

  @override
  R? visitRecordLiteral(RecordLiteral node) => visitNode(node);

  @override
  R? visitRecordPattern(RecordPattern node) => visitNode(node);

  @override
  R? visitRecordTypeAnnotation(RecordTypeAnnotation node) => visitNode(node);

  @override
  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) =>
      visitNode(node);

  @override
  R? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) => visitNode(node);

  @override
  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) => visitNode(node);

  @override
  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) => visitNode(node);

  @override
  R? visitRelationalPattern(RelationalPattern node) => visitNode(node);

  @override
  R? visitRepresentationConstructorName(RepresentationConstructorName node) =>
      visitNode(node);

  @override
  R? visitRepresentationDeclaration(RepresentationDeclaration node) =>
      visitNode(node);

  @override
  R? visitRestPatternElement(RestPatternElement node) => visitNode(node);

  @override
  R? visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  R? visitReturnStatement(ReturnStatement node) => visitNode(node);

  @override
  R? visitScriptTag(ScriptTag node) => visitNode(node);

  @override
  R? visitSetOrMapLiteral(SetOrMapLiteral node) => visitNode(node);

  @override
  R? visitShowCombinator(ShowCombinator node) => visitNode(node);

  @override
  R? visitSimpleFormalParameter(SimpleFormalParameter node) => visitNode(node);

  @override
  R? visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  R? visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  R? visitSpreadElement(SpreadElement node) => visitNode(node);

  @override
  R? visitStringInterpolation(StringInterpolation node) => visitNode(node);

  @override
  R? visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitNode(node);

  @override
  R? visitSuperExpression(SuperExpression node) => visitNode(node);

  @override
  R? visitSuperFormalParameter(SuperFormalParameter node) => visitNode(node);

  @override
  R? visitSwitchCase(SwitchCase node) => visitNode(node);

  @override
  R? visitSwitchDefault(SwitchDefault node) => visitNode(node);

  @override
  R? visitSwitchExpression(SwitchExpression node) => visitNode(node);

  @override
  R? visitSwitchExpressionCase(SwitchExpressionCase node) => visitNode(node);

  @override
  R? visitSwitchPatternCase(SwitchPatternCase node) => visitNode(node);

  @override
  R? visitSwitchStatement(SwitchStatement node) => visitNode(node);

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  R? visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  R? visitThrowExpression(ThrowExpression node) => visitNode(node);

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitNode(node);

  @override
  R? visitTryStatement(TryStatement node) => visitNode(node);

  @override
  R? visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  @override
  R? visitTypeLiteral(TypeLiteral node) => visitNode(node);

  @override
  R? visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R? visitTypeParameterList(TypeParameterList node) => visitNode(node);

  @override
  R? visitVariableDeclaration(VariableDeclaration node) => visitNode(node);

  @override
  R? visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitNode(node);

  @override
  R? visitWhenClause(WhenClause node) => visitNode(node);

  @override
  R? visitWhileStatement(WhileStatement node) => visitNode(node);

  @override
  R? visitWildcardPattern(WildcardPattern node) => visitNode(node);

  @override
  R? visitWithClause(WithClause node) => visitNode(node);

  @override
  R? visitYieldStatement(YieldStatement node) => visitNode(node);
}
