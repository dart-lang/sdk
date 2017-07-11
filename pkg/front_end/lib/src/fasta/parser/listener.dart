// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.listener;

import '../fasta_codes.dart' show Message;

import '../../scanner/token.dart' show BeginToken, Token, TokenType;

import '../util/link.dart' show Link;

import 'parser.dart' show Assert, FormalParameterType, MemberKind;

import 'identifier_context.dart' show IdentifierContext;

/// A parser event listener that does nothing except throw exceptions
/// on parser errors.
///
/// Events are methods that begin with one of: `begin`, `end`, or `handle`.
///
/// Events starting with `begin` and `end` come in pairs. Normally, a
/// `beginFoo` event is followed by an `endFoo` event. There's a few exceptions
/// documented below.
///
/// Events starting with `handle` are used when isn't possible to have a begin
/// event.
class Listener {
  final List<ParserError> recoverableErrors = <ParserError>[];

  Uri get uri => null;

  void logEvent(String name) {}

  set suppressParseErrors(bool value) {}

  void beginArguments(Token token) {}

  void endArguments(int count, Token beginToken, Token endToken) {
    logEvent("Arguments");
  }

  /// Handle async modifiers `async`, `async*`, `sync`.
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    logEvent("AsyncModifier");
  }

  void beginAwaitExpression(Token token) {}

  void endAwaitExpression(Token beginToken, Token endToken) {
    logEvent("AwaitExpression");
  }

  void beginBlock(Token token) {}

  void endBlock(int count, Token beginToken, Token endToken) {
    logEvent("Block");
  }

  void beginCascade(Token token) {}

  void endCascade() {
    logEvent("Cascade");
  }

  void beginCaseExpression(Token caseKeyword) {}

  void endCaseExpression(Token colon) {
    logEvent("CaseExpression");
  }

  void beginClassBody(Token token) {}

  /// Handle the end of the body of a class declaration.  The only substructures
  /// are the class members.
  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    logEvent("ClassBody");
  }

  /// Called before parsing a class or named mixin application.
  void beginClassOrNamedMixinApplication(Token token) {}

  void beginClassDeclaration(Token beginToken, Token name) {}

  /// Handle the end of a class declaration.  Substructures:
  /// - metadata
  /// - modifiers
  /// - class name
  /// - type variables
  /// - supertype (may be a mixin application)
  /// - implemented types
  /// - class body
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    logEvent("ClassDeclaration");
  }

  void beginCombinators(Token token) {}

  void endCombinators(int count) {
    logEvent("Combinators");
  }

  void beginCompilationUnit(Token token) {}

  void endCompilationUnit(int count, Token token) {
    logEvent("CompilationUnit");
  }

  void beginConstLiteral(Token token) {}

  void endConstLiteral(Token token) {
    logEvent("ConstLiteral");
  }

  void beginConstructorReference(Token start) {}

  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    logEvent("ConstructorReference");
  }

  void beginDoWhileStatement(Token token) {}

  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    logEvent("DoWhileStatement");
  }

  void beginDoWhileStatementBody(Token token) {}

  void endDoWhileStatementBody(Token token) {
    logEvent("DoWhileStatementBody");
  }

  void beginWhileStatementBody(Token token) {}

  void endWhileStatementBody(Token token) {
    logEvent("WhileStatementBody");
  }

  void beginEnum(Token enumKeyword) {}

  /// Handle the end of an enum declaration.  Substructures:
  /// - Metadata
  /// - Enum name (identifier)
  /// - [count] times:
  ///   - Enum value (identifier)
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    logEvent("Enum");
  }

  void beginExport(Token token) {}

  /// Handle the end of an export directive.  Substructures:
  /// - metadata
  /// - uri
  /// - conditional uris
  /// - combinators
  void endExport(Token exportKeyword, Token semicolon) {
    logEvent("Export");
  }

  void beginExpression(Token token) {}

  void beginExpressionStatement(Token token) {}

  /// Called by [ClassMemberParser] after skipping an expression as error
  /// recovery. For a stack-based listener, the suggested action is to push
  /// `null` or a synthetic erroneous expression.
  void handleRecoverExpression(Token token, Message message) {
    logEvent("RecoverExpression");
  }

  /// Called by [Parser] after parsing an extraneous expression as error
  /// recovery. For a stack-based listener, the suggested action is to discard
  /// an expression from the stack.
  void handleExtraneousExpression(Token token, Message message) {
    logEvent("ExtraneousExpression");
  }

  void endExpressionStatement(Token token) {
    logEvent("ExpressionStatement");
  }

  void beginFactoryMethod(Token token) {}

  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    logEvent("FactoryMethod");
  }

  void beginFormalParameter(Token token, MemberKind kind) {}

  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterType kind, MemberKind memberKind) {
    logEvent("FormalParameter");
  }

  void handleNoFormalParameters(Token token, MemberKind kind) {
    logEvent("NoFormalParameters");
  }

  void beginFormalParameters(Token token, MemberKind kind) {}

  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    logEvent("FormalParameters");
  }

  /// Handle the end of a field declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Variable declarations (count times)
  ///
  /// Doesn't have a corresponding begin event, use [beginMember] instead.
  void endFields(int count, Token beginToken, Token endToken) {
    logEvent("Fields");
  }

  void beginForStatement(Token token) {}

  void endForStatement(Token forKeyword, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    logEvent("ForStatement");
  }

  void beginForStatementBody(Token token) {}

  void endForStatementBody(Token token) {
    logEvent("ForStatementBody");
  }

  void endForIn(Token awaitToken, Token forToken, Token leftParenthesis,
      Token inKeyword, Token rightParenthesis, Token endToken) {
    logEvent("ForIn");
  }

  void beginForInExpression(Token token) {}

  void endForInExpression(Token token) {
    logEvent("ForInExpression");
  }

  void beginForInBody(Token token) {}

  void endForInBody(Token token) {
    logEvent("ForInBody");
  }

  void beginNamedFunctionExpression(Token token) {}

  /// A named function expression which isn't legal syntax in Dart.
  /// Useful for recovering from Javascript code being pasted into a Dart
  /// proram, as it will interpret `function foo() {}` as a named function
  /// expression with return type `function` and name `foo`.
  ///
  /// Substructures:
  /// - Modifiers
  /// - Return type
  /// - Name
  /// - Type variables
  /// - Formals
  /// - Initializers
  /// - Async modifier
  /// - Function body (block or arrow expression).
  void endNamedFunctionExpression(Token endToken) {
    logEvent("NamedFunctionExpression");
  }

  void beginFunctionDeclaration(Token token) {}

  /// A function declaration.
  ///
  /// Substructures:
  /// - Modifiers
  /// - Return type
  /// - Name
  /// - Type variables
  /// - Formals
  /// - Initializers
  /// - Async modifier
  /// - Function body (block or arrow expression).
  void endFunctionDeclaration(Token endToken) {
    logEvent("FunctionDeclaration");
  }

  /// This method is invoked when the parser sees that a function has a
  /// block function body.  This method is not invoked for empty or expression
  /// function bodies, see the corresponding methods [handleEmptyFunctionBody]
  /// and [handleExpressionFunctionBody].
  void beginBlockFunctionBody(Token token) {}

  /// This method is invoked by the parser after it finished parsing a block
  /// function body.  This method is not invoked for empty or expression
  /// function bodies, see the corresponding methods [handleEmptyFunctionBody]
  /// and [handleExpressionFunctionBody].  The [beginToken] is the '{' token,
  /// and the [endToken] is the '}' token of the block.  The number of
  /// statements is given as the [count] parameter.
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    logEvent("BlockFunctionBody");
  }

  void handleNoFunctionBody(Token token) {
    logEvent("NoFunctionBody");
  }

  /// Handle the end of a function body that was skipped by the parser.
  ///
  /// The boolean [isExpressionBody] indicates whether the function body that
  /// was skipped used "=>" syntax.
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {}

  void beginFunctionName(Token token) {}

  void endFunctionName(Token beginToken, Token token) {
    logEvent("FunctionName");
  }

  void beginFunctionTypeAlias(Token token) {}

  /// Handle the end of a typedef declaration.
  ///
  /// If [equals] is null, then we have the following substructures:
  /// - Metadata
  /// - Return type
  /// - Name (identifier)
  /// - Template variables (type variables to the template)
  /// - Formal parameters
  ///
  /// If [equals] is not null, then the have the following substructures:
  /// - Metadata
  /// - Name (identifier)
  /// - Template variables (type variables to the template)
  /// - Type (FunctionTypeAnnotation)
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    logEvent("FunctionTypeAlias");
  }

  void beginMixinApplication(Token token) {}

  /// Handle the end of a mixin application construct (e.g. "A with B, C").
  /// Substructures:
  /// - supertype
  /// - mixin types (TypeList)
  void endMixinApplication(Token withKeyword) {
    logEvent("MixinApplication");
  }

  void beginNamedMixinApplication(Token beginToken, Token name) {}

  /// Handle the end of a named mixin declaration.  Substructures:
  /// - metadata
  /// - modifiers
  /// - class name
  /// - type variables
  /// - mixin application
  /// - implemented types (TypeList)
  ///
  /// TODO(paulberry,ahe): it seems inconsistent that for a named mixin
  /// application, the implemented types are a TypeList, whereas for a class
  /// declaration, each implemented type is listed separately on the stack, and
  /// the number of implemented types is passed as a parameter.
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    logEvent("NamedMixinApplication");
  }

  void beginHide(Token hideKeyword) {}

  /// Handle the end of a "hide" combinator.  Substructures:
  /// - hidden names (IdentifierList)
  void endHide(Token hideKeyword) {
    logEvent("Hide");
  }

  void beginIdentifierList(Token token) {}

  void endIdentifierList(int count) {
    logEvent("IdentifierList");
  }

  void beginTypeList(Token token) {}

  void endTypeList(int count) {
    logEvent("TypeList");
  }

  void beginIfStatement(Token token) {}

  void endIfStatement(Token ifToken, Token elseToken) {
    logEvent("IfStatement");
  }

  void beginThenStatement(Token token) {}

  void endThenStatement(Token token) {
    logEvent("ThenStatement");
  }

  void beginElseStatement(Token token) {}

  void endElseStatement(Token token) {
    logEvent("ElseStatement");
  }

  void beginImport(Token importKeyword) {}

  /// Handle the end of an import directive.  Substructures:
  /// - metadata
  /// - uri
  /// - conditional uris
  /// - prefix identifier (only if asKeyword != null)
  /// - combinators
  void endImport(Token importKeyword, Token DeferredKeyword, Token asKeyword,
      Token semicolon) {
    logEvent("Import");
  }

  void beginConditionalUris(Token token) {}

  void endConditionalUris(int count) {
    logEvent("ConditionalUris");
  }

  void beginConditionalUri(Token ifKeyword) {}

  /// Handle the end of a conditional URI construct.  Substructures:
  /// - Dotted name
  /// - Condition (literal string; only present if [equalitySign] is not `null`)
  /// - URI (literal string)
  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    logEvent("ConditionalUri");
  }

  void beginDottedName(Token token) {}

  void endDottedName(int count, Token firstIdentifier) {
    logEvent("DottedName");
  }

  void beginInitializedIdentifier(Token token) {}

  void endInitializedIdentifier(Token nameToken) {
    logEvent("InitializedIdentifier");
  }

  void beginFieldInitializer(Token token) {}

  /// Handle the end of a field initializer.  Substructures:
  /// - Initializer expression
  void endFieldInitializer(Token assignment, Token token) {
    logEvent("FieldInitializer");
  }

  /// Handle the lack of a field initializer.
  void handleNoFieldInitializer(Token token) {
    logEvent("NoFieldInitializer");
  }

  void beginVariableInitializer(Token token) {}

  /// Handle the end of a variable initializer. Substructures:
  /// - Initializer expression.
  void endVariableInitializer(Token assignmentOperator) {
    logEvent("VariableInitializer");
  }

  /// Used when a variable has no initializer.
  void handleNoVariableInitializer(Token token) {
    logEvent("NoVariableInitializer");
  }

  void beginInitializer(Token token) {}

  void endInitializer(Token token) {
    logEvent("ConstructorInitializer");
  }

  void beginInitializers(Token token) {}

  void endInitializers(int count, Token beginToken, Token endToken) {
    logEvent("Initializers");
  }

  void handleNoInitializers() {
    logEvent("NoInitializers");
  }

  /// Called after the listener has recovered from an invalid expression. The
  /// parser will resume parsing from [token]. Exactly where the parser will
  /// resume parsing is unspecified.
  void handleInvalidExpression(Token token) {
    logEvent("InvalidExpression");
  }

  /// Called after the listener has recovered from an invalid function
  /// body. The parser expected an open curly brace `{` and will resume parsing
  /// from [token] as if a function body had preceeded it.
  void handleInvalidFunctionBody(Token token) {
    logEvent("InvalidFunctionBody");
  }

  /// Called after the listener has recovered from an invalid type. The parser
  /// expected an identifier, and will resume parsing type arguments from
  /// [token].
  void handleInvalidTypeReference(Token token) {
    logEvent("InvalidTypeReference");
  }

  void handleLabel(Token token) {
    logEvent("Label");
  }

  void beginLabeledStatement(Token token, int labelCount) {}

  void endLabeledStatement(int labelCount) {
    logEvent("LabeledStatement");
  }

  void beginLibraryName(Token token) {}

  /// Handle the end of a library directive.  Substructures:
  /// - Metadata
  /// - Library name (a qualified identifier)
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    logEvent("LibraryName");
  }

  void beginLiteralMapEntry(Token token) {}

  void endLiteralMapEntry(Token colon, Token endToken) {
    logEvent("LiteralMapEntry");
  }

  void beginLiteralString(Token token) {}

  void endLiteralString(int interpolationCount, Token endToken) {
    logEvent("LiteralString");
  }

  void handleStringJuxtaposition(int literalCount) {
    logEvent("StringJuxtaposition");
  }

  void beginMember(Token token) {}

  /// This event is added for convenience. Normally, one should override
  /// [endMethod] or [endFields] instead.
  void endMember() {
    logEvent("Member");
  }

  /// This event can be used to support non-compliant (with respect to Dart
  /// Language Specification) Dart VM native clauses. See
  /// [native_support.dart].
  Link<Token> handleMemberName(Link<Token> identifiers) => identifiers;

  void beginMethod(Token token, Token name) {}

  /// Handle the end of a method declaration.  Substructures:
  /// - metadata
  /// - modifiers
  /// - return type
  /// - method name (identifier, possibly qualified)
  /// - type variables
  /// - formal parameters
  /// - initializers
  /// - async marker
  /// - body
  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    logEvent("Method");
  }

  void beginMetadataStar(Token token) {}

  void endMetadataStar(int count, bool forParameter) {
    logEvent("MetadataStar");
  }

  void beginMetadata(Token token) {}

  /// Handle the end of a metadata annotation.  Substructures:
  /// - Identifier
  /// - Type arguments
  /// - Constructor name (only if [periodBeforeName] is not `null`)
  /// - Arguments
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    logEvent("Metadata");
  }

  void beginOptionalFormalParameters(Token token) {}

  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    logEvent("OptionalFormalParameters");
  }

  void beginPart(Token token) {}

  /// Handle the end of a part directive.  Substructures:
  /// - metadata
  /// - uri
  void endPart(Token partKeyword, Token semicolon) {
    logEvent("Part");
  }

  void beginPartOf(Token token) {}

  /// Handle the end of a "part of" directive.  Substructures:
  /// - Metadata
  /// - Library name (a qualified identifier)
  ///
  /// If [hasName] is true, this part refers to its library by name, otherwise,
  /// by URI.
  void endPartOf(Token partKeyword, Token semicolon, bool hasName) {
    logEvent("PartOf");
  }

  void beginRedirectingFactoryBody(Token token) {}

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    logEvent("RedirectingFactoryBody");
  }

  void beginReturnStatement(Token token) {}

  /// This method is invoked when a function has the empty body.
  void handleEmptyFunctionBody(Token semicolon) {
    logEvent("EmptyFunctionBody");
  }

  /// This method is invoked when parser finishes parsing the corresponding
  /// expression of the expression function body.
  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    logEvent("ExpressionFunctionBody");
  }

  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    logEvent("ReturnStatement");
  }

  void beginSend(Token token) {}

  void endSend(Token beginToken, Token endToken) {
    logEvent("Send");
  }

  void beginShow(Token showKeyword) {}

  /// Handle the end of a "show" combinator.  Substructures:
  /// - shown names (IdentifierList)
  void endShow(Token showKeyword) {
    logEvent("Show");
  }

  void beginSwitchStatement(Token token) {}

  void endSwitchStatement(Token switchKeyword, Token endToken) {
    logEvent("SwitchStatement");
  }

  void beginSwitchBlock(Token token) {}

  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    logEvent("SwitchBlock");
  }

  void beginLiteralSymbol(Token token) {}

  void endLiteralSymbol(Token hashToken, int identifierCount) {
    logEvent("LiteralSymbol");
  }

  void beginThrowExpression(Token token) {}

  void endThrowExpression(Token throwToken, Token endToken) {
    logEvent("ThrowExpression");
  }

  void beginRethrowStatement(Token token) {}

  void endRethrowStatement(Token rethrowToken, Token endToken) {
    logEvent("RethrowStatement");
  }

  /// This event is added for convenience. Normally, one should use
  /// [endClassDeclaration], [endNamedMixinApplication], [endEnum],
  /// [endFunctionTypeAlias], [endLibraryName], [endImport], [endExport],
  /// [endPart], [endPartOf], [endTopLevelFields], or [endTopLevelMethod].
  void endTopLevelDeclaration(Token token) {
    logEvent("TopLevelDeclaration");
  }

  void beginTopLevelMember(Token token) {}

  /// Handle the end of a top level variable declaration.  Substructures:
  /// - Metadata
  /// - Modifiers
  /// - Type
  /// - Repeated [count] times:
  ///   - Variable name (identifier)
  ///   - Field initializer
  /// Doesn't have a corresponding begin event, use [beginTopLevelMember]
  /// instead.
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    logEvent("TopLevelFields");
  }

  void beginTopLevelMethod(Token token, Token name) {}

  /// Handle the end of a top level method.  Substructures:
  /// - metadata
  /// - modifiers
  /// - return type
  /// - identifier
  /// - type variables
  /// - formal parameters
  /// - async marker
  /// - body
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    logEvent("TopLevelMethod");
  }

  void beginTryStatement(Token token) {}

  void handleCaseMatch(Token caseKeyword, Token colon) {
    logEvent("CaseMatch");
  }

  void beginCatchClause(Token token) {}

  void endCatchClause(Token token) {
    logEvent("CatchClause");
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    logEvent("CatchBlock");
  }

  void handleFinallyBlock(Token finallyKeyword) {
    logEvent("FinallyBlock");
  }

  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    logEvent("TryStatement");
  }

  void handleType(Token beginToken, Token endToken) {
    logEvent("Type");
  }

  void handleNoName(Token token) {
    logEvent("NoName");
  }

  void beginFunctionType(Token beginToken) {}

  /// Handle the end of a generic function type declaration.
  ///
  /// Substructures:
  /// - Type variables
  /// - Return type
  /// - Formal parameters
  void endFunctionType(Token functionToken, Token endToken) {
    logEvent("FunctionType");
  }

  void beginTypeArguments(Token token) {}

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    logEvent("TypeArguments");
  }

  void handleNoTypeArguments(Token token) {
    logEvent("NoTypeArguments");
  }

  void beginTypeVariable(Token token) {}

  /// Handle the end of a type formal parameter (e.g. "X extends Y").
  /// Substructures:
  /// - Metadata
  /// - Name (identifier)
  /// - Type bound
  void endTypeVariable(Token token, Token extendsOrSuper) {
    logEvent("TypeVariable");
  }

  void beginTypeVariables(Token token) {}

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    logEvent("TypeVariables");
  }

  void beginFunctionExpression(Token token) {}

  /// Handle the end of a function expression (e.g. "() { ... }").
  /// Substructures:
  /// - Type variables
  /// - Formal parameters
  /// - Async marker
  /// - Body
  void endFunctionExpression(Token beginToken, Token token) {
    logEvent("FunctionExpression");
  }

  void beginVariablesDeclaration(Token token) {}

  void endVariablesDeclaration(int count, Token endToken) {
    logEvent("VariablesDeclaration");
  }

  void beginWhileStatement(Token token) {}

  void endWhileStatement(Token whileKeyword, Token endToken) {
    logEvent("WhileStatement");
  }

  void handleAsOperator(Token operator, Token endToken) {
    logEvent("AsOperator");
  }

  void handleAssignmentExpression(Token token) {
    logEvent("AssignmentExpression");
  }

  void handleBinaryExpression(Token token) {
    logEvent("BinaryExpression");
  }

  void handleConditionalExpression(Token question, Token colon) {
    logEvent("ConditionalExpression");
  }

  void beginConstExpression(Token constKeyword) {}

  void endConstExpression(Token token) {
    logEvent("ConstExpression");
  }

  /// Handle the start of a function typed formal parameter.  Substructures:
  /// - type variables
  void beginFunctionTypedFormalParameter(Token token) {}

  /// Handle the end of a function typed formal parameter.  Substructures:
  /// - type variables
  /// - return type
  /// - formal parameters
  void endFunctionTypedFormalParameter() {
    logEvent("FunctionTypedFormalParameter");
  }

  /// Handle an identifier token.
  ///
  /// [context] indicates what kind of construct the identifier appears in.
  void handleIdentifier(Token token, IdentifierContext context) {
    logEvent("Identifier");
  }

  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    logEvent("IndexedExpression");
  }

  void handleIsOperator(Token operator, Token not, Token endToken) {
    logEvent("IsOperator");
  }

  void handleLiteralBool(Token token) {
    logEvent("LiteralBool");
  }

  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    logEvent("BreakStatement");
  }

  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    logEvent("ContinueStatement");
  }

  void handleEmptyStatement(Token token) {
    logEvent("EmptyStatement");
  }

  void beginAssert(Token assertKeyword, Assert kind) {}

  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token rightParenthesis, Token semicolonToken) {
    logEvent("Assert");
  }

  /** Called with either the token containing a double literal, or
    * an immediately preceding "unary plus" token.
    */
  void handleLiteralDouble(Token token) {
    logEvent("LiteralDouble");
  }

  /** Called with either the token containing an integer literal,
    * or an immediately preceding "unary plus" token.
    */
  void handleLiteralInt(Token token) {
    logEvent("LiteralInt");
  }

  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    logEvent("LiteralList");
  }

  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    logEvent("LiteralMap");
  }

  void handleLiteralNull(Token token) {
    logEvent("LiteralNull");
  }

  void handleModifier(Token token) {
    logEvent("Modifier");
  }

  void handleModifiers(int count) {
    logEvent("Modifiers");
  }

  void handleNamedArgument(Token colon) {
    logEvent("NamedArgument");
  }

  void beginNewExpression(Token token) {}

  void endNewExpression(Token token) {
    logEvent("NewExpression");
  }

  void handleNoArguments(Token token) {
    logEvent("NoArguments");
  }

  void handleNoExpression(Token token) {
    logEvent("NoExpression");
  }

  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    logEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  void handleNoType(Token token) {
    logEvent("NoType");
  }

  void handleNoTypeVariables(Token token) {
    logEvent("NoTypeVariables");
  }

  void handleOperator(Token token) {
    logEvent("Operator");
  }

  void handleSymbolVoid(Token token) {
    logEvent("SymbolVoid");
  }

  /// Handle the end of a construct of the form "operator <token>".
  void handleOperatorName(Token operatorKeyword, Token token) {
    logEvent("OperatorName");
  }

  void handleParenthesizedExpression(BeginToken token) {
    logEvent("ParenthesizedExpression");
  }

  /// Handle a construct of the form "identifier.identifier" occurring in a part
  /// of the grammar where expressions in general are not allowed.
  /// Substructures:
  /// - Qualified identifier (before the period)
  /// - Identifier (after the period)
  void handleQualified(Token period) {
    logEvent("Qualified");
  }

  void handleStringPart(Token token) {
    logEvent("StringPart");
  }

  void handleSuperExpression(Token token, IdentifierContext context) {
    logEvent("SuperExpression");
  }

  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {}

  void handleSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      int statementCount,
      Token firstToken,
      Token endToken) {
    logEvent("SwitchCase");
  }

  void handleThisExpression(Token token, IdentifierContext context) {
    logEvent("ThisExpression");
  }

  void handleUnaryPostfixAssignmentExpression(Token token) {
    logEvent("UnaryPostfixAssignmentExpression");
  }

  void handleUnaryPrefixExpression(Token token) {
    logEvent("UnaryPrefixExpression");
  }

  void handleUnaryPrefixAssignmentExpression(Token token) {
    logEvent("UnaryPrefixAssignmentExpression");
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    logEvent("ValuedFormalParameter");
  }

  void handleFormalParameterWithoutValue(Token token) {
    logEvent("FormalParameterWithoutValue");
  }

  void handleVoidKeyword(Token token) {
    logEvent("VoidKeyword");
  }

  void beginYieldStatement(Token token) {}

  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    logEvent("YieldStatement");
  }

  /// An unrecoverable error is an error that the parser can't recover from
  /// itself, and recovery is left to the listener. If the listener can
  /// recover, it should return a non-null continuation token whose `next`
  /// pointer is the token the parser should continue from. Error recovery
  /// is tightly coupled to the parser implementation, so to recover from an
  /// error, one must carefully examine the code in the parser that generates
  /// the error.
  ///
  /// If the listener can't recover, it can throw an exception or return
  /// `null`. In the latter case, the parser simply skips to EOF which will
  /// often result in additional parser errors as the parser returns from its
  /// recursive state.
  Token handleUnrecoverableError(Token token, Message message) {
    throw new ParserError.fromTokens(token, token, message);
  }

  /// The parser noticed a syntax error, but was able to recover from it.
  void handleRecoverableError(Token token, Message message) {
    recoverableErrors.add(new ParserError.fromTokens(token, token, message));
  }

  void handleScript(Token token) {
    logEvent("Script");
  }

  /// Matches a generic comment type substitution and injects it into the token
  /// stream before the given [token].
  Token injectGenericCommentTypeAssign(Token token) {
    return token;
  }

  /// Matches a generic comment type variables or type arguments and injects
  /// them into the token stream before the given [token].
  Token injectGenericCommentTypeList(Token token) {
    return token;
  }

  /// If the [tokenWithComment] has a type substitution comment /*=T*/, then
  /// the comment should be scanned into new tokens, and these tokens inserted
  /// instead of tokens from the [tokenToStartReplacing] to the
  /// [tokenWithComment]. Returns the first newly inserted token, or the
  /// original [tokenWithComment].
  Token replaceTokenWithGenericCommentTypeAssign(
      Token tokenToStartReplacing, Token tokenWithComment) {
    return tokenToStartReplacing;
  }

  /// A type has been just parsed, and the parser noticed that the next token
  /// has a type substitution comment /*=T*. So, the type that has been just
  /// parsed should be discarded, and a new type should be parsed instead.
  void discardTypeReplacedWithCommentTypeAssign() {}

  /// Creates a new synthetic token whose `next` pointer points to [next].
  ///
  /// If [next] is `null`, `null` is returned.
  Token newSyntheticToken(Token next) {
    if (next == null) return null;
    return new Token(TokenType.RECOVERY, next.charOffset)..next = next;
  }
}

class ParserError {
  /// Character offset from the beginning of file where this error starts.
  final int beginOffset;

  /// Character offset from the beginning of file where this error ends.
  final int endOffset;

  final Message message;

  ParserError(this.beginOffset, this.endOffset, this.message);

  ParserError.fromTokens(Token begin, Token end, Message message)
      : this(begin.charOffset, end.charOffset + end.charCount, message);

  String toString() => "@${beginOffset}: ${message.message}\n${message.tip}";
}
