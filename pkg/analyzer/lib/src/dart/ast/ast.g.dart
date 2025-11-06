// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'ast.dart';

/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// - SimpleAstVisitor which implements every visit method by doing nothing,
/// - RecursiveAstVisitor which causes every node in a structure to be visited,
///   and
/// - ThrowingAstVisitor which implements every visit method by throwing an
///   exception.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract class AstVisitor<R> {
  R? visitAdjacentStrings(AdjacentStrings node);

  R? visitAnnotation(Annotation node);

  R? visitArgumentList(ArgumentList node);

  R? visitAsExpression(AsExpression node);

  R? visitAssertInitializer(AssertInitializer node);

  R? visitAssertStatement(AssertStatement node);

  R? visitAssignedVariablePattern(AssignedVariablePattern node);

  R? visitAssignmentExpression(AssignmentExpression node);

  R? visitAwaitExpression(AwaitExpression node);

  R? visitBinaryExpression(BinaryExpression node);

  R? visitBlock(Block node);

  R? visitBlockFunctionBody(BlockFunctionBody node);

  R? visitBooleanLiteral(BooleanLiteral node);

  R? visitBreakStatement(BreakStatement node);

  R? visitCascadeExpression(CascadeExpression node);

  R? visitCaseClause(CaseClause node);

  R? visitCastPattern(CastPattern node);

  R? visitCatchClause(CatchClause node);

  R? visitCatchClauseParameter(CatchClauseParameter node);

  R? visitClassDeclaration(ClassDeclaration node);

  R? visitClassTypeAlias(ClassTypeAlias node);

  R? visitComment(Comment node);

  R? visitCommentReference(CommentReference node);

  R? visitCompilationUnit(CompilationUnit node);

  R? visitConditionalExpression(ConditionalExpression node);

  R? visitConfiguration(Configuration node);

  R? visitConstantPattern(ConstantPattern node);

  R? visitConstructorDeclaration(ConstructorDeclaration node);

  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node);

  R? visitConstructorName(ConstructorName node);

  R? visitConstructorReference(ConstructorReference node);

  R? visitConstructorSelector(ConstructorSelector node);

  R? visitContinueStatement(ContinueStatement node);

  R? visitDeclaredIdentifier(DeclaredIdentifier node);

  R? visitDeclaredVariablePattern(DeclaredVariablePattern node);

  R? visitDefaultFormalParameter(DefaultFormalParameter node);

  R? visitDoStatement(DoStatement node);

  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  );

  R? visitDotShorthandInvocation(DotShorthandInvocation node);

  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node);

  R? visitDottedName(DottedName node);

  R? visitDoubleLiteral(DoubleLiteral node);

  R? visitEmptyFunctionBody(EmptyFunctionBody node);

  R? visitEmptyStatement(EmptyStatement node);

  R? visitEnumConstantArguments(EnumConstantArguments node);

  R? visitEnumConstantDeclaration(EnumConstantDeclaration node);

  R? visitEnumDeclaration(EnumDeclaration node);

  R? visitExportDirective(ExportDirective node);

  R? visitExpressionFunctionBody(ExpressionFunctionBody node);

  R? visitExpressionStatement(ExpressionStatement node);

  R? visitExtendsClause(ExtendsClause node);

  R? visitExtensionDeclaration(ExtensionDeclaration node);

  R? visitExtensionOnClause(ExtensionOnClause node);

  R? visitExtensionOverride(ExtensionOverride node);

  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node);

  R? visitFieldDeclaration(FieldDeclaration node);

  R? visitFieldFormalParameter(FieldFormalParameter node);

  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node);

  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node);

  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node);

  R? visitForElement(ForElement node);

  R? visitFormalParameterList(FormalParameterList node);

  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node);

  R? visitForPartsWithExpression(ForPartsWithExpression node);

  R? visitForPartsWithPattern(ForPartsWithPattern node);

  R? visitForStatement(ForStatement node);

  R? visitFunctionDeclaration(FunctionDeclaration node);

  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node);

  R? visitFunctionExpression(FunctionExpression node);

  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node);

  R? visitFunctionReference(FunctionReference node);

  R? visitFunctionTypeAlias(FunctionTypeAlias node);

  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node);

  R? visitGenericFunctionType(GenericFunctionType node);

  R? visitGenericTypeAlias(GenericTypeAlias node);

  R? visitGuardedPattern(GuardedPattern node);

  R? visitHideCombinator(HideCombinator node);

  R? visitIfElement(IfElement node);

  R? visitIfStatement(IfStatement node);

  R? visitImplementsClause(ImplementsClause node);

  R? visitImplicitCallReference(ImplicitCallReference node);

  R? visitImportDirective(ImportDirective node);

  R? visitImportPrefixReference(ImportPrefixReference node);

  R? visitIndexExpression(IndexExpression node);

  R? visitInstanceCreationExpression(InstanceCreationExpression node);

  R? visitIntegerLiteral(IntegerLiteral node);

  R? visitInterpolationExpression(InterpolationExpression node);

  R? visitInterpolationString(InterpolationString node);

  R? visitIsExpression(IsExpression node);

  R? visitLabel(Label node);

  R? visitLabeledStatement(LabeledStatement node);

  R? visitLibraryDirective(LibraryDirective node);

  R? visitLibraryIdentifier(LibraryIdentifier node);

  R? visitListLiteral(ListLiteral node);

  R? visitListPattern(ListPattern node);

  R? visitLogicalAndPattern(LogicalAndPattern node);

  R? visitLogicalOrPattern(LogicalOrPattern node);

  R? visitMapLiteralEntry(MapLiteralEntry node);

  R? visitMapPattern(MapPattern node);

  R? visitMapPatternEntry(MapPatternEntry node);

  R? visitMethodDeclaration(MethodDeclaration node);

  R? visitMethodInvocation(MethodInvocation node);

  R? visitMixinDeclaration(MixinDeclaration node);

  R? visitMixinOnClause(MixinOnClause node);

  R? visitNamedExpression(NamedExpression node);

  R? visitNamedType(NamedType node);

  R? visitNativeClause(NativeClause node);

  R? visitNativeFunctionBody(NativeFunctionBody node);

  R? visitNullAssertPattern(NullAssertPattern node);

  R? visitNullAwareElement(NullAwareElement node);

  R? visitNullCheckPattern(NullCheckPattern node);

  R? visitNullLiteral(NullLiteral node);

  R? visitObjectPattern(ObjectPattern node);

  R? visitParenthesizedExpression(ParenthesizedExpression node);

  R? visitParenthesizedPattern(ParenthesizedPattern node);

  R? visitPartDirective(PartDirective node);

  R? visitPartOfDirective(PartOfDirective node);

  R? visitPatternAssignment(PatternAssignment node);

  R? visitPatternField(PatternField node);

  R? visitPatternFieldName(PatternFieldName node);

  R? visitPatternVariableDeclaration(PatternVariableDeclaration node);

  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  );

  R? visitPostfixExpression(PostfixExpression node);

  R? visitPrefixedIdentifier(PrefixedIdentifier node);

  R? visitPrefixExpression(PrefixExpression node);

  R? visitPropertyAccess(PropertyAccess node);

  R? visitRecordLiteral(RecordLiteral node);

  R? visitRecordPattern(RecordPattern node);

  R? visitRecordTypeAnnotation(RecordTypeAnnotation node);

  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node);

  R? visitRecordTypeAnnotationNamedFields(RecordTypeAnnotationNamedFields node);

  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  );

  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  );

  R? visitRelationalPattern(RelationalPattern node);

  R? visitRepresentationConstructorName(RepresentationConstructorName node);

  R? visitRepresentationDeclaration(RepresentationDeclaration node);

  R? visitRestPatternElement(RestPatternElement node);

  R? visitRethrowExpression(RethrowExpression node);

  R? visitReturnStatement(ReturnStatement node);

  R? visitScriptTag(ScriptTag node);

  R? visitSetOrMapLiteral(SetOrMapLiteral node);

  R? visitShowCombinator(ShowCombinator node);

  R? visitSimpleFormalParameter(SimpleFormalParameter node);

  R? visitSimpleIdentifier(SimpleIdentifier node);

  R? visitSimpleStringLiteral(SimpleStringLiteral node);

  R? visitSpreadElement(SpreadElement node);

  R? visitStringInterpolation(StringInterpolation node);

  R? visitSuperConstructorInvocation(SuperConstructorInvocation node);

  R? visitSuperExpression(SuperExpression node);

  R? visitSuperFormalParameter(SuperFormalParameter node);

  R? visitSwitchCase(SwitchCase node);

  R? visitSwitchDefault(SwitchDefault node);

  R? visitSwitchExpression(SwitchExpression node);

  R? visitSwitchExpressionCase(SwitchExpressionCase node);

  R? visitSwitchPatternCase(SwitchPatternCase node);

  R? visitSwitchStatement(SwitchStatement node);

  R? visitSymbolLiteral(SymbolLiteral node);

  R? visitThisExpression(ThisExpression node);

  R? visitThrowExpression(ThrowExpression node);

  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node);

  R? visitTryStatement(TryStatement node);

  R? visitTypeArgumentList(TypeArgumentList node);

  R? visitTypeLiteral(TypeLiteral node);

  R? visitTypeParameter(TypeParameter node);

  R? visitTypeParameterList(TypeParameterList node);

  R? visitVariableDeclaration(VariableDeclaration node);

  R? visitVariableDeclarationList(VariableDeclarationList node);

  R? visitVariableDeclarationStatement(VariableDeclarationStatement node);

  R? visitWhenClause(WhenClause node);

  R? visitWhileStatement(WhileStatement node);

  R? visitWildcardPattern(WildcardPattern node);

  R? visitWithClause(WithClause node);

  R? visitYieldStatement(YieldStatement node);
}
