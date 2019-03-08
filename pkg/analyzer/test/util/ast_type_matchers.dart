// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

const isAdjacentStrings = const TypeMatcher<AdjacentStrings>();

const isAnnotatedNode = const TypeMatcher<AnnotatedNode>();

const isAnnotation = const TypeMatcher<Annotation>();

const isArgumentList = const TypeMatcher<ArgumentList>();

const isAsExpression = const TypeMatcher<AsExpression>();

const isAssertInitializer = const TypeMatcher<AssertInitializer>();

const isAssertion = const TypeMatcher<Assertion>();

const isAssertStatement = const TypeMatcher<AssertStatement>();

const isAssignmentExpression = const TypeMatcher<AssignmentExpression>();

const isAwaitExpression = const TypeMatcher<AwaitExpression>();

const isBinaryExpression = const TypeMatcher<BinaryExpression>();

const isBlock = const TypeMatcher<Block>();

const isBlockFunctionBody = const TypeMatcher<BlockFunctionBody>();

const isBooleanLiteral = const TypeMatcher<BooleanLiteral>();

const isBreakStatement = const TypeMatcher<BreakStatement>();

const isCascadeExpression = const TypeMatcher<CascadeExpression>();

const isCatchClause = const TypeMatcher<CatchClause>();

const isClassDeclaration = const TypeMatcher<ClassDeclaration>();

const isClassMember = const TypeMatcher<ClassMember>();

const isClassOrMixinDeclaration = const TypeMatcher<ClassOrMixinDeclaration>();

const isClassTypeAlias = const TypeMatcher<ClassTypeAlias>();

const isCombinator = const TypeMatcher<Combinator>();

const isComment = const TypeMatcher<Comment>();

const isCommentReference = const TypeMatcher<CommentReference>();

const isCompilationUnit = const TypeMatcher<CompilationUnit>();

const isCompilationUnitMember = const TypeMatcher<CompilationUnitMember>();

const isConditionalExpression = const TypeMatcher<ConditionalExpression>();

const isConfiguration = const TypeMatcher<Configuration>();

const isConstructorDeclaration = const TypeMatcher<ConstructorDeclaration>();

const isConstructorFieldInitializer =
    const TypeMatcher<ConstructorFieldInitializer>();

const isConstructorInitializer = const TypeMatcher<ConstructorInitializer>();

const isConstructorName = const TypeMatcher<ConstructorName>();

const isConstructorReferenceNode =
    const TypeMatcher<ConstructorReferenceNode>();

const isContinueStatement = const TypeMatcher<ContinueStatement>();

const isDeclaration = const TypeMatcher<Declaration>();

const isDeclaredIdentifier = const TypeMatcher<DeclaredIdentifier>();

const isDefaultFormalParameter = const TypeMatcher<DefaultFormalParameter>();

const isDirective = const TypeMatcher<Directive>();

const isDoStatement = const TypeMatcher<DoStatement>();

const isDottedName = const TypeMatcher<DottedName>();

const isDoubleLiteral = const TypeMatcher<DoubleLiteral>();

const isEmptyFunctionBody = const TypeMatcher<EmptyFunctionBody>();

const isEmptyStatement = const TypeMatcher<EmptyStatement>();

const isEnumConstantDeclaration = const TypeMatcher<EnumConstantDeclaration>();

const isEnumDeclaration = const TypeMatcher<EnumDeclaration>();

const isExportDirective = const TypeMatcher<ExportDirective>();

const isExpression = const TypeMatcher<Expression>();

const isExpressionFunctionBody = const TypeMatcher<ExpressionFunctionBody>();

const isExpressionStatement = const TypeMatcher<ExpressionStatement>();

const isExtendsClause = const TypeMatcher<ExtendsClause>();

const isFieldDeclaration = const TypeMatcher<FieldDeclaration>();

const isFieldFormalParameter = const TypeMatcher<FieldFormalParameter>();

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isForEachStatement = predicate(
    (Object o) => o is ForStatement2 && o.forLoopParts is ForEachParts);

const isFormalParameter = const TypeMatcher<FormalParameter>();

const isFormalParameterList = const TypeMatcher<FormalParameterList>();

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isForStatement =
    predicate((Object o) => o is ForStatement2 && o.forLoopParts is ForParts);

const isFunctionBody = const TypeMatcher<FunctionBody>();

const isFunctionDeclaration = const TypeMatcher<FunctionDeclaration>();

const isFunctionDeclarationStatement =
    const TypeMatcher<FunctionDeclarationStatement>();

const isFunctionExpression = const TypeMatcher<FunctionExpression>();

const isFunctionExpressionInvocation =
    const TypeMatcher<FunctionExpressionInvocation>();

const isFunctionTypeAlias = const TypeMatcher<FunctionTypeAlias>();

const isFunctionTypedFormalParameter =
    const TypeMatcher<FunctionTypedFormalParameter>();

const isGenericFunctionType = const TypeMatcher<GenericFunctionType>();

const isGenericTypeAlias = const TypeMatcher<GenericTypeAlias>();

const isHideCombinator = const TypeMatcher<HideCombinator>();

const isIdentifier = const TypeMatcher<Identifier>();

const isIfStatement = const TypeMatcher<IfStatement>();

const isImplementsClause = const TypeMatcher<ImplementsClause>();

const isImportDirective = const TypeMatcher<ImportDirective>();

const isIndexExpression = const TypeMatcher<IndexExpression>();

const isInstanceCreationExpression =
    const TypeMatcher<InstanceCreationExpression>();

const isIntegerLiteral = const TypeMatcher<IntegerLiteral>();

const isInterpolationElement = const TypeMatcher<InterpolationElement>();

const isInterpolationExpression = const TypeMatcher<InterpolationExpression>();

const isInterpolationString = const TypeMatcher<InterpolationString>();

const isInvocationExpression = const TypeMatcher<InvocationExpression>();

const isIsExpression = const TypeMatcher<IsExpression>();

const isLabel = const TypeMatcher<Label>();

const isLabeledStatement = const TypeMatcher<LabeledStatement>();

const isLibraryDirective = const TypeMatcher<LibraryDirective>();

const isLibraryIdentifier = const TypeMatcher<LibraryIdentifier>();

const isListLiteral = const TypeMatcher<ListLiteral>();

const isLiteral = const TypeMatcher<Literal>();

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isMapLiteral =
    predicate((Object o) => o is SetOrMapLiteral && o.isMap);

const isMapLiteralEntry = const TypeMatcher<MapLiteralEntry>();

const isMethodDeclaration = const TypeMatcher<MethodDeclaration>();

const isMethodInvocation = const TypeMatcher<MethodInvocation>();

const isMethodReferenceExpression =
    const TypeMatcher<MethodReferenceExpression>();

const isMixinDeclaration = const TypeMatcher<MixinDeclaration>();

const isNamedCompilationUnitMember =
    const TypeMatcher<NamedCompilationUnitMember>();

const isNamedExpression = const TypeMatcher<NamedExpression>();

const isNamedType = const TypeMatcher<NamedType>();

const isNamespaceDirective = const TypeMatcher<NamespaceDirective>();

const isNativeClause = const TypeMatcher<NativeClause>();

const isNativeFunctionBody = const TypeMatcher<NativeFunctionBody>();

const isNormalFormalParameter = const TypeMatcher<NormalFormalParameter>();

const isNullLiteral = const TypeMatcher<NullLiteral>();

const isOnClause = const TypeMatcher<OnClause>();

const isParenthesizedExpression = const TypeMatcher<ParenthesizedExpression>();

const isPartDirective = const TypeMatcher<PartDirective>();

const isPartOfDirective = const TypeMatcher<PartOfDirective>();

const isPostfixExpression = const TypeMatcher<PostfixExpression>();

const isPrefixedIdentifier = const TypeMatcher<PrefixedIdentifier>();

const isPrefixExpression = const TypeMatcher<PrefixExpression>();

const isPropertyAccess = const TypeMatcher<PropertyAccess>();

const isRedirectingConstructorInvocation =
    const TypeMatcher<RedirectingConstructorInvocation>();

const isRethrowExpression = const TypeMatcher<RethrowExpression>();

const isReturnStatement = const TypeMatcher<ReturnStatement>();

const isScriptTag = const TypeMatcher<ScriptTag>();

/// TODO(paulberry): remove the explicit type `Matcher` once an SDK has been
/// released that includes ba5644b76cb811e8f01ffb375b87d20d6295749c.
final Matcher isSetLiteral =
    predicate((Object o) => o is SetOrMapLiteral && o.isSet);

const isShowCombinator = const TypeMatcher<ShowCombinator>();

const isSimpleFormalParameter = const TypeMatcher<SimpleFormalParameter>();

const isSimpleIdentifier = const TypeMatcher<SimpleIdentifier>();

const isSimpleStringLiteral = const TypeMatcher<SimpleStringLiteral>();

const isSingleStringLiteral = const TypeMatcher<SingleStringLiteral>();

const isStatement = const TypeMatcher<Statement>();

const isStringInterpolation = const TypeMatcher<StringInterpolation>();

const isStringLiteral = const TypeMatcher<StringLiteral>();

const isSuperConstructorInvocation =
    const TypeMatcher<SuperConstructorInvocation>();

const isSuperExpression = const TypeMatcher<SuperExpression>();

const isSwitchCase = const TypeMatcher<SwitchCase>();

const isSwitchDefault = const TypeMatcher<SwitchDefault>();

const isSwitchMember = const TypeMatcher<SwitchMember>();

const isSwitchStatement = const TypeMatcher<SwitchStatement>();

const isSymbolLiteral = const TypeMatcher<SymbolLiteral>();

const isThisExpression = const TypeMatcher<ThisExpression>();

const isThrowExpression = const TypeMatcher<ThrowExpression>();

const isTopLevelVariableDeclaration =
    const TypeMatcher<TopLevelVariableDeclaration>();

const isTryStatement = const TypeMatcher<TryStatement>();

const isTypeAlias = const TypeMatcher<TypeAlias>();

const isTypeAnnotation = const TypeMatcher<TypeAnnotation>();

const isTypeArgumentList = const TypeMatcher<TypeArgumentList>();

const isTypedLiteral = const TypeMatcher<TypedLiteral>();

const isTypeName = const TypeMatcher<TypeName>();

const isTypeParameter = const TypeMatcher<TypeParameter>();

const isTypeParameterList = const TypeMatcher<TypeParameterList>();

const isUriBasedDirective = const TypeMatcher<UriBasedDirective>();

const isVariableDeclaration = const TypeMatcher<VariableDeclaration>();

const isVariableDeclarationList = const TypeMatcher<VariableDeclarationList>();

const isVariableDeclarationStatement =
    const TypeMatcher<VariableDeclarationStatement>();

const isWhileStatement = const TypeMatcher<WhileStatement>();

const isWithClause = const TypeMatcher<WithClause>();

const isYieldStatement = const TypeMatcher<YieldStatement>();
