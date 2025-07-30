// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/analysis_rule_timers.dart';
import 'package:analyzer/src/lint/linter.dart';

part 'linter_visitor.g.dart';

/// The soon-to-be-deprecated alias for a [RuleVisitorRegistry].
typedef NodeLintRegistry = RuleVisitorRegistry;

class RuleVisitorRegistryImpl implements RuleVisitorRegistry {
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
  final List<_Subscription<DotShorthandConstructorInvocation>>
  _forDotShorthandConstructorInvocation = [];
  final List<_Subscription<DotShorthandInvocation>> _forDotShorthandInvocation =
      [];
  final List<_Subscription<DotShorthandPropertyAccess>>
  _forDotShorthandPropertyAccess = [];
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
  final List<_Subscription<RecordLiteral>> _forRecordLiteral = [];
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

  RuleVisitorRegistryImpl({required bool enableTiming})
    : _enableTiming = enableTiming;

  @override
  void addAdjacentStrings(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAdjacentStrings.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAnnotation(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAnnotation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addArgumentList(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forArgumentList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAsExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAsExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAssertInitializer(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAssertInitializer.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAssertStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAssertStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAssignedVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forAssignedVariablePattern.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addAssignmentExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAssignmentExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addAwaitExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forAwaitExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addBinaryExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forBinaryExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addBlock(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forBlock.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addBlockFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forBlockFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addBooleanLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forBooleanLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addBreakStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forBreakStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCascadeExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCascadeExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCaseClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCaseClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCastPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCastPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCatchClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCatchClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCatchClauseParameter(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCatchClauseParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addClassDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forClassDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addClassTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forClassTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addComment(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forComment.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCommentReference(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCommentReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addCompilationUnit(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forCompilationUnit.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addConditionalExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConditionalExpression.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addConfiguration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConfiguration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addConstantPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConstantPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addConstructorDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forConstructorDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addConstructorFieldInitializer(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forConstructorFieldInitializer.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addConstructorName(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConstructorName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addConstructorReference(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConstructorReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addConstructorSelector(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forConstructorSelector.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addContinueStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forContinueStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addDeclaredIdentifier(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forDeclaredIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addDeclaredVariablePattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forDeclaredVariablePattern.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addDefaultFormalParameter(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forDefaultFormalParameter.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addDoStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forDoStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addDotShorthandConstructorInvocation(
    AnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forDotShorthandConstructorInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addDotShorthandInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forDotShorthandInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addDotShorthandPropertyAccess(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forDotShorthandInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addDottedName(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forDottedName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addDoubleLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forDoubleLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addEmptyFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forEmptyFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addEmptyStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forEmptyStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addEnumConstantArguments(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forEnumConstantArguments.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addEnumConstantDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forEnumConstantDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addEnumDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forEnumDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExportDirective(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExportDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExpressionFunctionBody(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forExpressionFunctionBody.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addExpressionStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExpressionStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExtendsClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExtendsClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExtensionDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExtensionDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExtensionOnClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExtensionOnClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExtensionOverride(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forExtensionOverride.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addExtensionTypeDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forExtensionTypeDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addFieldDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFieldDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFieldFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFieldFormalParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addForEachPartsWithDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forForEachPartsWithDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addForEachPartsWithIdentifier(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forForEachPartsWithIdentifier.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addForEachPartsWithPattern(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forForEachPartsWithPattern.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addForElement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forForElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFormalParameterList(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFormalParameterList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addForPartsWithDeclarations(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forForPartsWithDeclarations.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addForPartsWithExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forForPartsWithExpression.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addForPartsWithPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forForPartsWithPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addForStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forForStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFunctionDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFunctionDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFunctionDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forFunctionDeclarationStatement.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addFunctionExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFunctionExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFunctionExpressionInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forFunctionExpressionInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addFunctionReference(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFunctionReference.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFunctionTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forFunctionTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addFunctionTypedFormalParameter(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forFunctionTypedFormalParameter.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addGenericFunctionType(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forGenericFunctionType.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addGenericTypeAlias(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forGenericTypeAlias.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addGuardedPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forGuardedPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addHideCombinator(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forHideCombinator.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addIfElement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forIfElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addIfStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forIfStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addImplementsClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forImplementsClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addImplicitCallReference(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forImplicitCallReference.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addImportDirective(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forImportDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addImportPrefixReference(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forImportPrefixReference.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addIndexExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forIndexExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addInstanceCreationExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forInstanceCreationExpression.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addIntegerLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forIntegerLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addInterpolationExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forInterpolationExpression.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addInterpolationString(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forInterpolationString.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addIsExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forIsExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLabel(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLabel.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLabeledStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLabeledStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLibraryDirective(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLibraryDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLibraryIdentifier(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLibraryIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addListLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forListLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addListPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forListPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLogicalAndPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLogicalAndPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addLogicalOrPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forLogicalOrPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMapLiteralEntry(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMapLiteralEntry.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMapPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMapPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMapPatternEntry(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMapPatternEntry.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMethodDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMethodDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMethodInvocation(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMethodInvocation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMixinDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMixinDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addMixinOnClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forMixinOnClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNamedExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNamedExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNamedType(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNamedType.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNativeClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNativeClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNativeFunctionBody(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNativeFunctionBody.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNullAssertPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNullAssertPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNullCheckPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNullCheckPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addNullLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forNullLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addObjectPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forObjectPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addParenthesizedExpression(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forParenthesizedExpression.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addParenthesizedPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forParenthesizedPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPartDirective(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPartDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPartOfDirective(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPartOfDirective.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPatternAssignment(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPatternAssignment.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPatternField(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPatternField.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPatternFieldName(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPatternFieldName.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPatternVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forPatternVariableDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addPatternVariableDeclarationStatement(
    AnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forPatternVariableDeclarationStatement.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addPostfixExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPostfixExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPrefixedIdentifier(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPrefixedIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPrefixExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPrefixExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addPropertyAccess(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forPropertyAccess.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRecordLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRecordLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRecordPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRecordPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRecordTypeAnnotation(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRecordTypeAnnotation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRedirectingConstructorInvocation(
    AnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forRedirectingConstructorInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addRelationalPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRelationalPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRepresentationConstructorName(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forRepresentationConstructorName.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addRepresentationDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forRepresentationDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addRestPatternElement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRestPatternElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addRethrowExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forRethrowExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addReturnStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forReturnStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addScriptTag(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forScriptTag.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSetOrMapLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSetOrMapLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addShowCombinator(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forShowCombinator.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSimpleFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSimpleFormalParameter.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addSimpleIdentifier(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSimpleIdentifier.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSimpleStringLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSimpleStringLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSpreadElement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSpreadElement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addStringInterpolation(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forStringInterpolation.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSuperConstructorInvocation(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forSuperConstructorInvocation.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addSuperExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSuperExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSuperFormalParameter(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSuperFormalParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchCase(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchDefault(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchDefault.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchExpressionCase(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchExpressionCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchPatternCase(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchPatternCase.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSwitchStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSwitchStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addSymbolLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forSymbolLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addThisExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forThisExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addThrowExpression(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forThrowExpression.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addTopLevelVariableDeclaration(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forTopLevelVariableDeclaration.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addTryStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forTryStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addTypeArgumentList(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forTypeArgumentList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addTypeLiteral(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forTypeLiteral.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addTypeParameter(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forTypeParameter.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addTypeParameterList(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forTypeParameterList.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addVariableDeclaration(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forVariableDeclaration.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addVariableDeclarationList(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forVariableDeclarationList.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addVariableDeclarationStatement(
    AbstractAnalysisRule rule,
    AstVisitor visitor,
  ) {
    _forVariableDeclarationStatement.add(
      _Subscription(rule, visitor, _getTimer(rule)),
    );
  }

  @override
  void addWhenClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forWhenClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addWhileStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forWhileStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addWildcardPattern(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forWildcardPattern.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addWithClause(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forWithClause.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void addYieldStatement(AbstractAnalysisRule rule, AstVisitor visitor) {
    _forYieldStatement.add(_Subscription(rule, visitor, _getTimer(rule)));
  }

  @override
  void afterLibrary(AbstractAnalysisRule rule, void Function() callback) {
    _afterLibrary.add(
      _AfterLibrarySubscription(rule, callback, _getTimer(rule)),
    );
  }

  /// Get the timer associated with the given [rule].
  Stopwatch? _getTimer(AbstractAnalysisRule rule) {
    if (_enableTiming) {
      return analysisRuleTimers.getTimer(rule);
    } else {
      return null;
    }
  }
}

class _AfterLibrarySubscription {
  final AbstractAnalysisRule rule;
  final void Function() callback;
  final Stopwatch? timer;

  _AfterLibrarySubscription(this.rule, this.callback, this.timer);
}

/// A single subscription for a node type, by the specified [rule].
class _Subscription<T> {
  final AbstractAnalysisRule rule;
  final AstVisitor visitor;
  final Stopwatch? timer;

  _Subscription(this.rule, this.visitor, this.timer);
}
