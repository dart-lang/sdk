// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/analyzer/tool/ast/generate.dart' to update.

part of 'rule_visitor_registry.dart';

/// The container to register visitors for separate AST node types.
///
/// Source files are visited by the Dart analysis server recursively. Only the
/// visitors that are registered to visit a given node type will visit such
/// nodes. Each analysis rule overrides
/// [AbstractAnalysisRule.registerNodeProcessors] and calls `add*` for each of
/// the node types it needs to visit with an [AstVisitor], which registers that
/// visitor.
abstract class RuleVisitorRegistry {
  void addAdjacentStrings(AbstractAnalysisRule rule, AstVisitor visitor);
  void addAnnotation(AbstractAnalysisRule rule, AstVisitor visitor);

  @experimental
  void addAnonymousBlockBody(AbstractAnalysisRule rule, AstVisitor visitor);

  @experimental
  void addAnonymousExpressionBody(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  @experimental
  void addAnonymousMethodInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addArgumentList(AbstractAnalysisRule rule, AstVisitor visitor);

  void addAsExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addAssertInitializer(AbstractAnalysisRule rule, AstVisitor visitor);

  void addAssertStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addAssignedVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addAssignmentExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addAwaitExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBinaryExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBlock(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBlockClassBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBlockEnumBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBlockFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBooleanLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addBreakStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCascadeExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCaseClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCastPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCatchClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCatchClauseParameter(AbstractAnalysisRule rule, AstVisitor visitor);

  void addClassDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addClassTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor);

  void addComment(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCommentReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addCompilationUnit(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConditionalExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConfiguration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConstantPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConstructorDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConstructorFieldInitializer(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addConstructorName(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConstructorReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addConstructorSelector(AbstractAnalysisRule rule, AstVisitor visitor);

  void addContinueStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addDeclaredIdentifier(AbstractAnalysisRule rule, AstVisitor visitor);

  void addDeclaredVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addDoStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addDotShorthandConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addDotShorthandInvocation(AbstractAnalysisRule rule, AstVisitor visitor);

  void addDotShorthandPropertyAccess(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addDottedName(AbstractAnalysisRule rule, AstVisitor visitor);

  void addDoubleLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEmptyClassBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEmptyEnumBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEmptyFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEmptyStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEnumConstantArguments(AbstractAnalysisRule rule, AstVisitor visitor);

  void addEnumConstantDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addEnumDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExportDirective(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExpressionFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExpressionStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExtendsClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExtensionDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExtensionOnClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExtensionOverride(AbstractAnalysisRule rule, AstVisitor visitor);

  void addExtensionTypeDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addFieldDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFieldFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor);

  void addForEachPartsWithDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addForEachPartsWithIdentifier(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addForEachPartsWithPattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addForElement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFormalParameterDefaultClause(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addFormalParameterList(AbstractAnalysisRule rule, AstVisitor visitor);

  void addForPartsWithDeclarations(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addForPartsWithExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addForPartsWithPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addForStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFunctionDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFunctionDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addFunctionExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFunctionExpressionInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addFunctionReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFunctionTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor);

  void addFunctionTypedFormalParameterSuffix(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addGenericFunctionType(AbstractAnalysisRule rule, AstVisitor visitor);

  void addGenericTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor);

  void addGuardedPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addHideCombinator(AbstractAnalysisRule rule, AstVisitor visitor);

  void addIfElement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addIfStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addImplementsClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addImplicitCallReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addImportDirective(AbstractAnalysisRule rule, AstVisitor visitor);

  void addImportPrefixReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addIndexExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addInstanceCreationExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addIntegerLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addInterpolationExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addInterpolationString(AbstractAnalysisRule rule, AstVisitor visitor);

  void addIsExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLabel(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLabeledStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLabelReference(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLibraryDirective(AbstractAnalysisRule rule, AstVisitor visitor);

  void addListLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addListPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLogicalAndPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addLogicalOrPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMapLiteralEntry(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMapPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMapPatternEntry(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMethodDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMethodInvocation(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMixinDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addMixinOnClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNamedArgument(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNamedType(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNameWithTypeParameters(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNativeClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNativeFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNullAssertPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNullAwareElement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNullCheckPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addNullLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addObjectPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addParenthesizedExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addParenthesizedPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPartDirective(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPartOfDirective(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPatternAssignment(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPatternField(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPatternFieldName(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPatternVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addPatternVariableDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addPostfixExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPrefixedIdentifier(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPrefixExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPrimaryConstructorBody(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPrimaryConstructorDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addPrimaryConstructorName(AbstractAnalysisRule rule, AstVisitor visitor);

  void addPropertyAccess(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRecordLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRecordLiteralNamedField(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addRecordPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRecordTypeAnnotation(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRecordTypeAnnotationNamedField(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addRecordTypeAnnotationNamedFields(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addRecordTypeAnnotationPositionalField(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addRedirectingConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addRegularFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRelationalPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRestPatternElement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addRethrowExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addReturnStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addScriptTag(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSetOrMapLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addShowCombinator(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSimpleIdentifier(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSimpleStringLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSpreadElement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addStringInterpolation(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSuperConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addSuperExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSuperFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchCase(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchDefault(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchExpressionCase(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchPatternCase(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSwitchStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addSymbolLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addThisExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addThrowExpression(AbstractAnalysisRule rule, AstVisitor visitor);

  void addTopLevelVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addTryStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addTypeArgumentList(AbstractAnalysisRule rule, AstVisitor visitor);

  void addTypeLiteral(AbstractAnalysisRule rule, AstVisitor visitor);

  void addTypeParameter(AbstractAnalysisRule rule, AstVisitor visitor);

  void addTypeParameterList(AbstractAnalysisRule rule, AstVisitor visitor);

  void addVariableDeclaration(AbstractAnalysisRule rule, AstVisitor visitor);

  void addVariableDeclarationList(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addVariableDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  );

  void addWhenClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addWhileStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void addWildcardPattern(AbstractAnalysisRule rule, AstVisitor visitor);

  void addWithClause(AbstractAnalysisRule rule, AstVisitor visitor);

  void addYieldStatement(AbstractAnalysisRule rule, AstVisitor visitor);

  void afterLibrary(AbstractAnalysisRule rule, void Function() callback);
}

/// The container to register [AstVisitor2]s for separate AST node types.
///
/// Each analysis rule using this visitor API overrides
/// [AbstractAnalysisRule.registerNodeProcessors2] and calls `add*` for each
/// node type it needs to visit with an [AstVisitor2].
@experimental
abstract class RuleVisitorRegistry2 {
  void addAdjacentStrings(AbstractAnalysisRule rule, AstVisitor2 visitor);
  void addAnnotation(AbstractAnalysisRule rule, AstVisitor2 visitor);

  @experimental
  void addAnonymousBlockBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  @experimental
  void addAnonymousExpressionBody(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  @experimental
  void addAnonymousMethodInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addArgumentList(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addAsExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addAssertInitializer(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addAssertStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addAssignedVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addAssignmentExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addAwaitExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBinaryExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBlock(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBlockClassBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBlockEnumBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBlockFunctionBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBooleanLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addBreakStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCascadeExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCaseClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCastPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCatchClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCatchClauseParameter(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addClassDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addClassTypeAlias(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addComment(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCommentReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addCompilationUnit(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConditionalExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConfiguration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConstantPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConstructorDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addConstructorFieldInitializer(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addConstructorName(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConstructorReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addConstructorSelector(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addContinueStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addDeclaredIdentifier(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addDeclaredVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addDoStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addDotShorthandConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addDotShorthandInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addDotShorthandPropertyAccess(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addDottedName(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addDoubleLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEmptyClassBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEmptyEnumBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEmptyFunctionBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEmptyStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEnumConstantArguments(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addEnumConstantDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addEnumDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExportDirective(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExpressionFunctionBody(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addExpressionStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExtendsClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExtensionDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExtensionOnClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExtensionOverride(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addExtensionTypeDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addFieldDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFieldFormalParameter(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addForEachPartsWithDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addForEachPartsWithIdentifier(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addForEachPartsWithPattern(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addForElement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFormalParameterDefaultClause(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addFormalParameterList(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addForPartsWithDeclarations(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addForPartsWithExpression(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addForPartsWithPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addForStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFunctionDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFunctionDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addFunctionExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFunctionExpressionInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addFunctionReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFunctionTypeAlias(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addFunctionTypedFormalParameterSuffix(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addGenericFunctionType(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addGenericTypeAlias(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addGuardedPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addHideCombinator(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addIfElement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addIfStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addImplementsClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addImplicitCallReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addImportDirective(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addImportPrefixReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addIndexExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addInstanceCreationExpression(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addIntegerLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addInterpolationExpression(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addInterpolationString(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addIsExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLabel(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLabeledStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLabelReference(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLibraryDirective(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addListLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addListPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLogicalAndPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addLogicalOrPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMapLiteralEntry(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMapPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMapPatternEntry(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMethodDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMethodInvocation(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMixinDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addMixinOnClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNamedArgument(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNamedType(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNameWithTypeParameters(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addNativeClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNativeFunctionBody(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNullAssertPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNullAwareElement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNullCheckPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addNullLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addObjectPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addParenthesizedExpression(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addParenthesizedPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPartDirective(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPartOfDirective(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPatternAssignment(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPatternField(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPatternFieldName(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPatternVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addPatternVariableDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addPostfixExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPrefixedIdentifier(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPrefixExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addPrimaryConstructorBody(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addPrimaryConstructorDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addPrimaryConstructorName(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addPropertyAccess(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRecordLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRecordLiteralNamedField(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRecordPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRecordTypeAnnotation(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRecordTypeAnnotationNamedField(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRecordTypeAnnotationNamedFields(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRecordTypeAnnotationPositionalField(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRedirectingConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRegularFormalParameter(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addRelationalPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRestPatternElement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addRethrowExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addReturnStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addScriptTag(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSetOrMapLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addShowCombinator(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSimpleIdentifier(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSimpleStringLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSpreadElement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addStringInterpolation(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSuperConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addSuperExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSuperFormalParameter(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchCase(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchDefault(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchExpressionCase(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchPatternCase(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSwitchStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addSymbolLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addThisExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addThrowExpression(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addTopLevelVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addTryStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addTypeArgumentList(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addTypeLiteral(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addTypeParameter(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addTypeParameterList(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addVariableDeclaration(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addVariableDeclarationList(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addVariableDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor2 visitor,
  );

  void addWhenClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addWhileStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addWildcardPattern(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addWithClause(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void addYieldStatement(AbstractAnalysisRule rule, AstVisitor2 visitor);

  void afterLibrary(AbstractAnalysisRule rule, void Function() callback);
}
