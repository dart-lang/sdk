// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart'
    show Message, Template, templateExpectedIdentifier, templateExpectedType;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import 'identifier_context_impl.dart';

import 'parser.dart' show Parser;

/// Information about the parser state that is passed to the listener at the
/// time an identifier is encountered. It is also used by the parser for error
/// recovery when a recovery template is defined.
///
/// This can be used by the listener to determine the context in which the
/// identifier appears; that in turn can help the listener decide how to resolve
/// the identifier (if the listener is doing resolution).
class IdentifierContext {
  /// Identifier is being declared as the name of an import prefix (i.e. `Foo`
  /// in `import "..." as Foo;`)
  static const importPrefixDeclaration = const IdentifierContext(
      'importPrefixDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the start of a dotted name in a conditional import or
  /// export.
  static const dottedName = const IdentifierContext('dottedName');

  /// Identifier is part of a dotted name in a conditional import or export, but
  /// it's not the first identifier of the dotted name.
  static const dottedNameContinuation =
      const IdentifierContext('dottedNameContinuation', isContinuation: true);

  /// Identifier is one of the shown/hidden names in an import/export
  /// combinator.
  static const combinator = const IdentifierContext('combinator');

  /// Identifier is the start of a name in an annotation that precedes a
  /// declaration (i.e. it appears directly after an `@`).
  static const metadataReference =
      const IdentifierContext('metadataReference', isScopeReference: true);

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it's not the first identifier in the name.
  static const metadataContinuation =
      const IdentifierContext('metadataContinuation', isContinuation: true);

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it appears after type parameters (e.g. `foo` in `@X<Y>.foo()`).
  static const metadataContinuationAfterTypeArguments = const IdentifierContext(
      'metadataContinuationAfterTypeArguments',
      isContinuation: true);

  /// Identifier is the name being declared by a typedef declaration.
  static const typedefDeclaration = const IdentifierContext(
      'typedefDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is a field initializer in a formal parameter list (i.e. it
  /// appears directly after `this.`).
  static const fieldInitializer =
      const IdentifierContext('fieldInitializer', isContinuation: true);

  /// Identifier is a formal parameter being declared as part of a function,
  /// method, or typedef declaration.
  static const formalParameterDeclaration = const IdentifierContext(
      'formalParameterDeclaration',
      inDeclaration: true);

  /// Identifier is the start of a library name (e.g. `foo` in the directive
  /// 'library foo;`).
  static const libraryName = const LibraryIdentifierContext();

  /// Identifier is part of a library name, but it's not the first identifier in
  /// the name.
  static const libraryNameContinuation =
      const LibraryIdentifierContext.continuation();

  /// Identifier is the start of a library name referenced by a `part of`
  /// directive (e.g. `foo` in the directive `part of foo;`).
  static const partName =
      const IdentifierContext('partName', inLibraryOrPartOfDeclaration: true);

  /// Identifier is part of a library name referenced by a `part of` directive,
  /// but it's not the first identifier in the name.
  static const partNameContinuation = const IdentifierContext(
      'partNameContinuation',
      inLibraryOrPartOfDeclaration: true,
      isContinuation: true);

  /// Identifier is the type name being declared by an enum declaration.
  static const enumDeclaration = const IdentifierContext('enumDeclaration',
      inDeclaration: true, isBuiltInIdentifierAllowed: false);

  /// Identifier is an enumerated value name being declared by an enum
  /// declaration.
  static const enumValueDeclaration =
      const IdentifierContext('enumValueDeclaration', inDeclaration: true);

  /// Identifier is the name being declared by a class declaration or a named
  /// mixin application, for example, `Foo` in `class Foo = X with Y;`.
  static const classOrNamedMixinDeclaration = const IdentifierContext(
      'classOrNamedMixinDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the name of a type variable being declared (e.g. `Foo` in
  /// `class C<Foo extends num> {}`).
  static const typeVariableDeclaration = const IdentifierContext(
      'typeVariableDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the start of a reference to a type that starts with prefix.
  static const prefixedTypeReference = const IdentifierContext(
      'prefixedTypeReference',
      isScopeReference: true,
      isBuiltInIdentifierAllowed: true,
      recoveryTemplate: templateExpectedType);

  /// Identifier is the start of a reference to a type declared elsewhere.
  static const typeReference = const IdentifierContext('typeReference',
      isScopeReference: true,
      isBuiltInIdentifierAllowed: false,
      recoveryTemplate: templateExpectedType);

  /// Identifier is part of a reference to a type declared elsewhere, but it's
  /// not the first identifier of the reference.
  static const typeReferenceContinuation = const IdentifierContext(
      'typeReferenceContinuation',
      isContinuation: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is a name being declared by a top level variable declaration.
  static const topLevelVariableDeclaration = const IdentifierContext(
      'topLevelVariableDeclaration',
      inDeclaration: true);

  /// Identifier is a name being declared by a field declaration.
  static const fieldDeclaration =
      const IdentifierContext('fieldDeclaration', inDeclaration: true);

  /// Identifier is the name being declared by a top level function declaration.
  static const topLevelFunctionDeclaration = const IdentifierContext(
      'topLevelFunctionDeclaration',
      inDeclaration: true);

  /// Identifier is the start of the name being declared by a method
  /// declaration.
  static const methodDeclaration =
      const IdentifierContext('methodDeclaration', inDeclaration: true);

  /// Identifier is part of the name being declared by a method declaration,
  /// but it's not the first identifier of the name.
  ///
  /// In valid Dart, this can only happen if the identifier is the name of a
  /// named constructor which is being declared, e.g. `foo` in
  /// `class C { C.foo(); }`.
  static const methodDeclarationContinuation = const IdentifierContext(
      'methodDeclarationContinuation',
      inDeclaration: true,
      isContinuation: true);

  /// Identifier appears after the word `operator` in a method declaration.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use methodDeclaration.
  static const operatorName = const IdentifierContext('operatorName');

  /// Identifier is the name being declared by a local function declaration that
  /// uses a "get" or "set" keyword.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use localFunctionDeclaration.
  static const localAccessorDeclaration =
      const IdentifierContext('localAccessorDeclaration', inDeclaration: true);

  /// Identifier is the start of the name being declared by a local function
  /// declaration.
  static const localFunctionDeclaration =
      const IdentifierContext('localFunctionDeclaration', inDeclaration: true);

  /// Identifier is part of the name being declared by a local function
  /// declaration, but it's not the first identifier of the name.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?
  static const localFunctionDeclarationContinuation = const IdentifierContext(
      'localFunctionDeclarationContinuation',
      inDeclaration: true,
      isContinuation: true);

  /// Identifier is the name appearing in a function expression.
  ///
  /// TODO(paulberry,ahe): What is an example of valid Dart code where this
  /// would occur?
  static const functionExpressionName =
      const IdentifierContext('functionExpressionName');

  /// Identifier is the start of a reference to a constructor declared
  /// elsewhere.
  static const constructorReference =
      const IdentifierContext('constructorReference', isScopeReference: true);

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it's not the first identifier of the reference.
  static const constructorReferenceContinuation = const IdentifierContext(
      'constructorReferenceContinuation',
      isContinuation: true);

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it appears after type parameters (e.g. `foo` in `X<Y>.foo`).
  static const constructorReferenceContinuationAfterTypeArguments =
      const IdentifierContext(
          'constructorReferenceContinuationAfterTypeArguments',
          isContinuation: true);

  /// Identifier is the declaration of a label (i.e. it is followed by `:` and
  /// then a statement).
  static const labelDeclaration =
      const IdentifierContext('labelDeclaration', inDeclaration: true);

  /// Identifier is the start of a reference occurring in a literal symbol (e.g.
  /// `foo` in `#foo`).
  static const literalSymbol =
      const IdentifierContext('literalSymbol', inSymbol: true);

  /// Identifier is part of a reference occurring in a literal symbol, but it's
  /// not the first identifier of the reference (e.g. `foo` in `#prefix.foo`).
  static const literalSymbolContinuation = const IdentifierContext(
      'literalSymbolContinuation',
      inSymbol: true,
      isContinuation: true);

  /// Identifier appears in an expression, and it does not immediately follow a
  /// `.`.
  static const expression =
      const IdentifierContext('expression', isScopeReference: true);

  /// Identifier appears in an expression, and it immediately follows a `.`.
  static const expressionContinuation =
      const IdentifierContext('expressionContinuation', isContinuation: true);

  /// Identifier is a reference to a named argument of a function or method
  /// invocation (e.g. `foo` in `f(foo: 0);`.
  static const namedArgumentReference = const IdentifierContext(
      'namedArgumentReference',
      allowedInConstantExpression: true);

  /// Identifier is a name being declared by a local variable declaration.
  static const localVariableDeclaration =
      const IdentifierContext('localVariableDeclaration', inDeclaration: true);

  /// Identifier is a reference to a label (e.g. `foo` in `break foo;`).
  /// Labels have their own scope.
  static const labelReference = const IdentifierContext('labelReference');

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

  const IdentifierContext(this._name,
      {this.inDeclaration: false,
      this.inLibraryOrPartOfDeclaration: false,
      this.inSymbol: false,
      this.isContinuation: false,
      this.isScopeReference: false,
      this.isBuiltInIdentifierAllowed: true,
      bool allowedInConstantExpression,
      this.recoveryTemplate: templateExpectedIdentifier})
      : this.allowedInConstantExpression =
            // Generally, declarations are legal in constant expressions.  A
            // continuation doesn't affect constant expressions: if what it's
            // continuing is a problem, it has already been reported.
            allowedInConstantExpression ??
                (inDeclaration || isContinuation || inSymbol);

  String toString() => _name;

  /// Ensure that the next token is an identifier (or keyword which should be
  /// treated as an identifier) and return that identifier.
  /// Report errors as necessary via [parser].
  Token ensureIdentifier(Token token, Parser parser) {
    assert(token.next.kind != IDENTIFIER_TOKEN);
    // TODO(danrubel): Implement this method for each identifier context
    // such that they return a non-null value.
    return null;
  }
}

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);
