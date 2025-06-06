// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart'
    show Message, Template, templateExpectedIdentifier;

import '../scanner/token.dart'
    show Keyword, Token, TokenIsAExtension, TokenType;

import 'identifier_context_impl.dart';

import 'parser_impl.dart' show Parser;

/// Information about the parser state that is passed to the listener at the
/// time an identifier is encountered. It is also used by the parser for error
/// recovery when a recovery template is defined.
///
/// This can be used by the listener to determine the context in which the
/// identifier appears; that in turn can help the listener decide how to resolve
/// the identifier (if the listener is doing resolution).
abstract class IdentifierContext {
  /// Identifier is being declared as the name of an import prefix (i.e. `Foo`
  /// in `import "..." as Foo;`)
  static const ImportPrefixIdentifierContext importPrefixDeclaration =
      const ImportPrefixIdentifierContext();

  /// Identifier is the start of a dotted name in a conditional import or
  /// export.
  static const DottedNameIdentifierContext dottedName =
      const DottedNameIdentifierContext();

  /// Identifier is part of a dotted name in a conditional import or export, but
  /// it's not the first identifier of the dotted name.
  static const DottedNameIdentifierContext dottedNameContinuation =
      const DottedNameIdentifierContext.continuation();

  /// Identifier is one of the shown/hidden names in an import/export
  /// combinator.
  static const CombinatorIdentifierContext combinator =
      const CombinatorIdentifierContext();

  /// Identifier is the start of a name in an annotation that precedes a
  /// declaration (i.e. it appears directly after an `@`).
  static const MetadataReferenceIdentifierContext metadataReference =
      const MetadataReferenceIdentifierContext();

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it's not the first identifier in the name.
  static const MetadataReferenceIdentifierContext metadataContinuation =
      const MetadataReferenceIdentifierContext.continuation();

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it appears after type parameters (e.g. `foo` in `@X<Y>.foo()`).
  static const MetadataReferenceIdentifierContext
  metadataContinuationAfterTypeArguments =
      const MetadataReferenceIdentifierContext.continuationAfterTypeArguments();

  /// Identifier is the name being declared by a typedef declaration.
  static const TypedefDeclarationIdentifierContext typedefDeclaration =
      const TypedefDeclarationIdentifierContext();

  /// Identifier is a field initializer in a formal parameter list (i.e. it
  /// appears directly after `this.`).
  static const FieldInitializerIdentifierContext fieldInitializer =
      const FieldInitializerIdentifierContext();

  /// Identifier is a formal parameter being declared as part of a function,
  /// method, or typedef declaration.
  static const FormalParameterDeclarationIdentifierContext
  formalParameterDeclaration =
      const FormalParameterDeclarationIdentifierContext();

  /// Identifier is a record field being declared as part of a record type
  /// declaration.
  static const RecordFieldDeclarationIdentifierContext recordFieldDeclaration =
      const RecordFieldDeclarationIdentifierContext();

  /// Identifier is a formal parameter being declared as part of a catch block
  /// in a try/catch/finally statement.
  static const CatchParameterIdentifierContext catchParameter =
      const CatchParameterIdentifierContext();

  /// Identifier is the start of a library name (e.g. `foo` in the directive
  /// 'library foo;`).
  static const LibraryIdentifierContext libraryName =
      const LibraryIdentifierContext();

  /// Identifier is part of a library name, but it's not the first identifier in
  /// the name.
  static const LibraryIdentifierContext libraryNameContinuation =
      const LibraryIdentifierContext.continuation();

  /// Identifier is the start of a library name referenced by a `part of`
  /// directive (e.g. `foo` in the directive `part of foo;`).
  static const LibraryIdentifierContext partName =
      const LibraryIdentifierContext.partName();

  /// Identifier is part of a library name referenced by a `part of` directive,
  /// but it's not the first identifier in the name.
  static const LibraryIdentifierContext partNameContinuation =
      const LibraryIdentifierContext.partNameContinuation();

  /// Identifier is the type name being declared by an enum declaration.
  static const EnumDeclarationIdentifierContext enumDeclaration =
      const EnumDeclarationIdentifierContext();

  /// Identifier is an enumerated value name being declared by an enum
  /// declaration.
  static const EnumValueDeclarationIdentifierContext enumValueDeclaration =
      const EnumValueDeclarationIdentifierContext();

  /// Identifier is the name being declared by a class declaration, a mixin
  /// declaration, or a named mixin application, for example,
  /// `Foo` in `class Foo = X with Y;`.
  static const ClassOrMixinOrExtensionIdentifierContext
  classOrMixinOrExtensionDeclaration =
      const ClassOrMixinOrExtensionIdentifierContext();

  /// Identifier is the name of a type variable being declared (e.g. `Foo` in
  /// `class C<Foo extends num> {}`).
  static const TypeVariableDeclarationIdentifierContext
  typeVariableDeclaration = const TypeVariableDeclarationIdentifierContext();

  /// Identifier is the start of a reference to a type that starts with prefix.
  static const TypeReferenceIdentifierContext prefixedTypeReference =
      const TypeReferenceIdentifierContext.prefixed();

  /// Identifier is the start of a reference to a type declared elsewhere.
  static const TypeReferenceIdentifierContext typeReference =
      const TypeReferenceIdentifierContext();

  /// Identifier is part of a reference to a type declared elsewhere, but it's
  /// not the first identifier of the reference.
  static const TypeReferenceIdentifierContext typeReferenceContinuation =
      const TypeReferenceIdentifierContext.continuation();

  /// Identifier is a name being declared by a top level variable declaration.
  static const TopLevelDeclarationIdentifierContext
  topLevelVariableDeclaration = const TopLevelDeclarationIdentifierContext(
    'topLevelVariableDeclaration',
    const [TokenType.SEMICOLON, TokenType.EQ, TokenType.COMMA, TokenType.EOF],
  );

  /// Identifier is a name being declared by a field declaration.
  static const FieldDeclarationIdentifierContext fieldDeclaration =
      const FieldDeclarationIdentifierContext();

  /// Identifier is the name being declared by a top level function declaration.
  static const TopLevelDeclarationIdentifierContext
  topLevelFunctionDeclaration = const TopLevelDeclarationIdentifierContext(
    'topLevelFunctionDeclaration',
    const [
      TokenType.LT,
      TokenType.OPEN_PAREN,
      TokenType.OPEN_CURLY_BRACKET,
      TokenType.FUNCTION,
      Keyword.ASYNC,
      Keyword.SYNC,
      TokenType.EOF,
    ],
  );

  /// Identifier is the start of the name being declared by a method
  /// declaration.
  static const MethodDeclarationIdentifierContext methodDeclaration =
      const MethodDeclarationIdentifierContext();

  /// Identifier is part of the name being declared by a method declaration,
  /// but it's not the first identifier of the name.
  ///
  /// In valid Dart, this can only happen if the identifier is the name of a
  /// named constructor which is being declared, e.g. `foo` in
  /// `class C { C.foo(); }`.
  static const MethodDeclarationIdentifierContext
  methodDeclarationContinuation =
      const MethodDeclarationIdentifierContext.continuation();

  /// Identifier appears after the word `operator` in a method declaration.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use methodDeclaration.
  static const MethodDeclarationIdentifierContext operatorName =
      const MethodDeclarationIdentifierContext.continuation();

  /// Identifier is the start of the name being declared by a local function
  /// declaration.
  static const LocalFunctionDeclarationIdentifierContext
  localFunctionDeclaration = const LocalFunctionDeclarationIdentifierContext();

  /// Identifier is part of the name being declared by a local function
  /// declaration, but it's not the first identifier of the name.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?
  static const LocalFunctionDeclarationIdentifierContext
  localFunctionDeclarationContinuation =
      const LocalFunctionDeclarationIdentifierContext.continuation();

  /// Identifier is the start of a reference to a constructor declared
  /// elsewhere.
  static const ConstructorReferenceIdentifierContext constructorReference =
      const ConstructorReferenceIdentifierContext();

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it's not the first identifier of the reference.
  static const ConstructorReferenceIdentifierContext
  constructorReferenceContinuation =
      const ConstructorReferenceIdentifierContext.continuation();

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it appears after type parameters (e.g. `foo` in `X<Y>.foo`).
  static const ConstructorReferenceIdentifierContext
  constructorReferenceContinuationAfterTypeArguments =
      // ignore: lines_longer_than_80_chars
      const ConstructorReferenceIdentifierContext.continuationAfterTypeArguments();

  /// Identifier is the name of a primary constructor declaration.
  static const IdentifierContext primaryConstructorDeclaration =
      const MethodDeclarationIdentifierContext.primaryConstructor();

  /// Identifier is the declaration of a label (i.e. it is followed by `:` and
  /// then a statement).
  static const LabelDeclarationIdentifierContext labelDeclaration =
      const LabelDeclarationIdentifierContext();

  /// Identifier is the start of a reference occurring in a literal symbol (e.g.
  /// `foo` in `#foo`).
  static const LiteralSymbolIdentifierContext literalSymbol =
      const LiteralSymbolIdentifierContext();

  /// Identifier is part of a reference occurring in a literal symbol, but it's
  /// not the first identifier of the reference (e.g. `foo` in `#prefix.foo`).
  static const LiteralSymbolIdentifierContext literalSymbolContinuation =
      const LiteralSymbolIdentifierContext.continuation();

  /// Identifier appears in an expression, and it does not immediately follow a
  /// `.`.
  static const ExpressionIdentifierContext expression =
      const ExpressionIdentifierContext();

  /// Identifier appears in an expression, and it immediately follows a `.`.
  static const ExpressionIdentifierContext expressionContinuation =
      const ExpressionIdentifierContext.continuation();

  /// Identifier is a reference to a named argument of a function or method
  /// invocation (e.g. `foo` in `f(foo: 0);`.
  static const NamedArgumentReferenceIdentifierContext namedArgumentReference =
      const NamedArgumentReferenceIdentifierContext();

  /// Identifier is a reference to a named record field
  /// (e.g. `foo` in `(42, foo: 42);`.
  static const NamedRecordFieldReferenceIdentifierContext
  namedRecordFieldReference =
      const NamedRecordFieldReferenceIdentifierContext();

  /// Identifier is a name being declared by a local variable declaration.
  static const LocalVariableDeclarationIdentifierContext
  localVariableDeclaration = const LocalVariableDeclarationIdentifierContext();

  /// Identifier is a reference to a label (e.g. `foo` in `break foo;`).
  /// Labels have their own scope.
  static const LabelReferenceIdentifierContext labelReference =
      const LabelReferenceIdentifierContext();

  final String _name;

  /// Indicates whether the identifier represents a name which is being
  /// declared.
  final bool inDeclaration;

  /// Indicates whether the identifier is within a `library` or `part of`
  /// declaration.
  final bool inLibraryOrPartOfDeclaration;

  /// Indicates whether the identifier is within a symbol literal.
  final bool inSymbol;

  /// Indicates whether the identifier follows a `.`.
  final bool isContinuation;

  /// Indicates whether the identifier should be looked up in the current scope.
  final bool isScopeReference;

  /// Indicates whether built-in identifiers are allowed in this context.
  final bool isBuiltInIdentifierAllowed;

  /// Indicated whether the identifier is allowed in a context where constant
  /// expressions are required.
  final bool allowedInConstantExpression;

  final Template<_MessageWithArgument<Token>> recoveryTemplate;

  const IdentifierContext(
    this._name, {
    this.inDeclaration = false,
    this.inLibraryOrPartOfDeclaration = false,
    this.inSymbol = false,
    this.isContinuation = false,
    this.isScopeReference = false,
    this.isBuiltInIdentifierAllowed = true,
    bool? allowedInConstantExpression,
    this.recoveryTemplate = templateExpectedIdentifier,
  }) : this.allowedInConstantExpression =
           // Generally, declarations are legal in constant expressions.  A
           // continuation doesn't affect constant expressions: if what it's
           // continuing is a problem, it has already been reported.
           allowedInConstantExpression ??
           (inDeclaration || isContinuation || inSymbol);

  @override
  String toString() => _name;

  /// Indicates whether the token `new` in this context should be treated as a
  /// valid identifier, under the rules of the "constructor tearoff" feature.
  /// Note that if the feature is disabled, such uses of `new` are still parsed
  /// as identifiers, however the parser will report an appropriate error; this
  /// should allow the best possible error recovery in the event that a user
  /// attempts to use the feature with a language version that doesn't permit
  /// it.
  bool get allowsNewAsIdentifier => false;

  /// Ensure that the next token is an identifier (or keyword which should be
  /// treated as an identifier) and return that identifier.
  /// Report errors as necessary via [parser].
  Token ensureIdentifier(Token token, Parser parser);

  /// Ensure that the next token is an identifier (or keyword which should be
  /// treated as an identifier) and return that identifier.
  /// Report errors as necessary via [parser].
  /// If [isRecovered] implementers could allow 'token' to be used as an
  /// identifier, even if it isn't a valid identifier.
  Token ensureIdentifierPotentiallyRecovered(
    Token token,
    Parser parser,
    bool isRecovered,
  ) => ensureIdentifier(token, parser);
}

/// Return `true` if [next] should be treated like the start of an expression
/// for the purposes of recovery.
bool looksLikeExpressionStart(Token next) =>
    next.isIdentifier ||
    next.isKeyword && !looksLikeStatementStart(next) ||
    next.isA(TokenType.DOUBLE) ||
    next.isA(TokenType.DOUBLE_WITH_SEPARATORS) ||
    next.isA(TokenType.HASH) ||
    next.isA(TokenType.HEXADECIMAL) ||
    next.isA(TokenType.HEXADECIMAL_WITH_SEPARATORS) ||
    next.isA(TokenType.IDENTIFIER) ||
    next.isA(TokenType.INT) ||
    next.isA(TokenType.INT_WITH_SEPARATORS) ||
    next.isA(TokenType.STRING) ||
    next.isA(TokenType.OPEN_CURLY_BRACKET) ||
    next.isA(TokenType.OPEN_PAREN) ||
    next.isA(TokenType.OPEN_SQUARE_BRACKET) ||
    next.isA(TokenType.INDEX) ||
    next.isA(TokenType.LT) ||
    next.isA(TokenType.BANG) ||
    next.isA(TokenType.MINUS) ||
    next.isA(TokenType.TILDE) ||
    next.isA(TokenType.PLUS_PLUS) ||
    next.isA(TokenType.MINUS_MINUS);

/// Returns `true` if [next] should be treated like the start of a pattern for
/// the purposes of recovery.
///
/// Note: since the syntax for patterns is very similar to that for expressions,
/// we mostly re-use [looksLikeExpressionStart].
bool looksLikePatternStart(Token next) =>
    next.isIdentifier ||
    next.isA(TokenType.DOUBLE) ||
    next.isA(TokenType.DOUBLE_WITH_SEPARATORS) ||
    next.isA(TokenType.HASH) ||
    next.isA(TokenType.HEXADECIMAL) ||
    next.isA(TokenType.HEXADECIMAL_WITH_SEPARATORS) ||
    next.isA(TokenType.IDENTIFIER) ||
    next.isA(TokenType.INT) ||
    next.isA(TokenType.INT_WITH_SEPARATORS) ||
    next.isA(TokenType.STRING) ||
    next.isA(Keyword.NULL) ||
    next.isA(Keyword.FALSE) ||
    next.isA(Keyword.TRUE) ||
    next.isA(TokenType.OPEN_CURLY_BRACKET) ||
    next.isA(TokenType.OPEN_PAREN) ||
    next.isA(TokenType.OPEN_SQUARE_BRACKET) ||
    next.isA(TokenType.INDEX) ||
    next.isA(TokenType.LT) ||
    next.isA(TokenType.LT_EQ) ||
    next.isA(TokenType.GT) ||
    next.isA(TokenType.GT_EQ) ||
    next.isA(TokenType.BANG_EQ) ||
    next.isA(TokenType.EQ_EQ) ||
    next.isA(Keyword.VAR) ||
    next.isA(Keyword.FINAL) ||
    next.isA(Keyword.CONST);

/// Return `true` if the given [token] should be treated like the start of
/// a new statement for the purposes of recovery.
bool looksLikeStatementStart(Token token) =>
    token.isA(TokenType.AT) ||
    token.isA(Keyword.ASSERT) ||
    token.isA(Keyword.BREAK) ||
    token.isA(Keyword.CONTINUE) ||
    token.isA(Keyword.DO) ||
    token.isA(Keyword.ELSE) ||
    token.isA(Keyword.FINAL) ||
    token.isA(Keyword.FOR) ||
    token.isA(Keyword.IF) ||
    token.isA(Keyword.RETURN) ||
    token.isA(Keyword.SWITCH) ||
    token.isA(Keyword.TRY) ||
    token.isA(Keyword.VAR) ||
    token.isA(Keyword.VOID) ||
    token.isA(Keyword.WHILE) ||
    token.isA(TokenType.EOF);

bool isOkNextValueInFormalParameter(Token token) =>
    token.isA(TokenType.EQ) ||
    token.isA(TokenType.COLON) ||
    token.isA(TokenType.COMMA) ||
    token.isA(TokenType.CLOSE_PAREN) ||
    token.isA(TokenType.CLOSE_SQUARE_BRACKET) ||
    token.isA(TokenType.CLOSE_CURLY_BRACKET);

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);
