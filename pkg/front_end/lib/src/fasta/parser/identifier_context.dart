// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about the parser state which is passed to the listener at the
/// time an identifier is encountered.
///
/// This can be used by the listener to determine the context in which the
/// identifier appears; that in turn can help the listener decide how to resolve
/// the identifier (if the listener is doing resolution).
class IdentifierContext {
  /// Identifier is being declared as the name of an import prefix (i.e. `Foo`
  /// in `import "..." as Foo;`)
  static const importPrefixDeclaration = const IdentifierContext._(
      'importPrefixDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the start of a dotted name in a conditional import or
  /// export.
  static const dottedName = const IdentifierContext._('dottedName');

  /// Identifier is part of a dotted name in a conditional import or export, but
  /// it's not the first identifier of the dotted name.
  static const dottedNameContinuation =
      const IdentifierContext._('dottedNameContinuation', isContinuation: true);

  /// Identifier is one of the shown/hidden names in an import/export
  /// combinator.
  static const combinator = const IdentifierContext._('combinator');

  /// Identifier is the start of a name in an annotation that precedes a
  /// declaration (i.e. it appears directly after an `@`).
  static const metadataReference =
      const IdentifierContext._('metadataReference', isScopeReference: true);

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it's not the first identifier in the name.
  static const metadataContinuation =
      const IdentifierContext._('metadataContinuation', isContinuation: true);

  /// Identifier is part of a name in an annotation that precedes a declaration,
  /// but it appears after type parameters (e.g. `foo` in `@X<Y>.foo()`).
  static const metadataContinuationAfterTypeArguments =
      const IdentifierContext._('metadataContinuationAfterTypeArguments',
          isContinuation: true);

  /// Identifier is the name being declared by a typedef declaration.
  static const typedefDeclaration = const IdentifierContext._(
      'typedefDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is a field initializer in a formal parameter list (i.e. it
  /// appears directly after `this.`).
  static const fieldInitializer =
      const IdentifierContext._('fieldInitializer', isContinuation: true);

  /// Identifier is a formal parameter being declared as part of a function,
  /// method, or typedef declaration.
  static const formalParameterDeclaration = const IdentifierContext._(
      'formalParameterDeclaration',
      inDeclaration: true);

  /// Identifier is the start of a library name (e.g. `foo` in the directive
  /// 'library foo;`).
  static const libraryName = const IdentifierContext._('libraryName',
      inLibraryOrPartOfDeclaration: true);

  /// Identifier is part of a library name, but it's not the first identifier in
  /// the name.
  static const libraryNameContinuation = const IdentifierContext._(
      'libraryNameContinuation',
      inLibraryOrPartOfDeclaration: true,
      isContinuation: true);

  /// Identifier is the start of a library name referenced by a `part of`
  /// directive (e.g. `foo` in the directive `part of foo;`).
  static const partName =
      const IdentifierContext._('partName', inLibraryOrPartOfDeclaration: true);

  /// Identifier is part of a library name referenced by a `part of` directive,
  /// but it's not the first identifier in the name.
  static const partNameContinuation = const IdentifierContext._(
      'partNameContinuation',
      inLibraryOrPartOfDeclaration: true,
      isContinuation: true);

  /// Identifier is the type name being declared by an enum declaration.
  static const enumDeclaration = const IdentifierContext._('enumDeclaration',
      inDeclaration: true, isBuiltInIdentifierAllowed: false);

  /// Identifier is an enumerated value name being declared by an enum
  /// declaration.
  static const enumValueDeclaration =
      const IdentifierContext._('enumValueDeclaration', inDeclaration: true);

  /// Identifier is the name being declared by a named mixin declaration (e.g.
  /// `Foo` in `class Foo = X with Y;`).
  static const namedMixinDeclaration = const IdentifierContext._(
      'namedMixinDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the name being declared by a class declaration.
  static const classDeclaration = const IdentifierContext._('classDeclaration',
      inDeclaration: true, isBuiltInIdentifierAllowed: false);

  /// Identifier is the name of a type variable being declared (e.g. `Foo` in
  /// `class C<Foo extends num> {}`).
  static const typeVariableDeclaration = const IdentifierContext._(
      'typeVariableDeclaration',
      inDeclaration: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is the start of a reference to a type declared elsewhere.
  static const typeReference = const IdentifierContext._('typeReference',
      isScopeReference: true, isBuiltInIdentifierAllowed: false);

  /// Identifier is part of a reference to a type declared elsewhere, but it's
  /// not the first identifier of the reference.
  static const typeReferenceContinuation = const IdentifierContext._(
      'typeReferenceContinuation',
      isContinuation: true,
      isBuiltInIdentifierAllowed: false);

  /// Identifier is a name being declared by a top level variable declaration.
  static const topLevelVariableDeclaration = const IdentifierContext._(
      'topLevelVariableDeclaration',
      inDeclaration: true);

  /// Identifier is a name being declared by a field declaration.
  static const fieldDeclaration =
      const IdentifierContext._('fieldDeclaration', inDeclaration: true);

  /// Identifier is the name being declared by a top level function declaration.
  static const topLevelFunctionDeclaration = const IdentifierContext._(
      'topLevelFunctionDeclaration',
      inDeclaration: true);

  /// Identifier is the start of the name being declared by a method
  /// declaration.
  static const methodDeclaration =
      const IdentifierContext._('methodDeclaration', inDeclaration: true);

  /// Identifier is part of the name being declared by a method declaration,
  /// but it's not the first identifier of the name.
  ///
  /// In valid Dart, this can only happen if the identifier is the name of a
  /// named constructor which is being declared, e.g. `foo` in
  /// `class C { C.foo(); }`.
  static const methodDeclarationContinuation = const IdentifierContext._(
      'methodDeclarationContinuation',
      inDeclaration: true,
      isContinuation: true);

  /// Identifier appears after the word `operator` in a method declaration.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use methodDeclaration.
  static const operatorName = const IdentifierContext._('operatorName');

  /// Identifier is the name being declared by a local function declaration that
  /// uses a "get" or "set" keyword.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?  If it's only as part of error recovery,
  /// perhaps we should just re-use localFunctionDeclaration.
  static const localAccessorDeclaration = const IdentifierContext._(
      'localAccessorDeclaration',
      inDeclaration: true);

  /// Identifier is the start of the name being declared by a local function
  /// declaration.
  static const localFunctionDeclaration = const IdentifierContext._(
      'localFunctionDeclaration',
      inDeclaration: true);

  /// Identifier is part of the name being declared by a local function
  /// declaration, but it's not the first identifier of the name.
  ///
  /// TODO(paulberry,ahe): Does this ever occur in valid Dart, or does it only
  /// occur as part of error recovery?
  static const localFunctionDeclarationContinuation = const IdentifierContext._(
      'localFunctionDeclarationContinuation',
      inDeclaration: true,
      isContinuation: true);

  /// Identifier is the name appearing in a function expression.
  ///
  /// TODO(paulberry,ahe): What is an example of valid Dart code where this
  /// would occur?
  static const functionExpressionName =
      const IdentifierContext._('functionExpressionName');

  /// Identifier is the start of a reference to a constructor declared
  /// elsewhere.
  static const constructorReference =
      const IdentifierContext._('constructorReference', isScopeReference: true);

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it's not the first identifier of the reference.
  static const constructorReferenceContinuation = const IdentifierContext._(
      'constructorReferenceContinuation',
      isContinuation: true);

  /// Identifier is part of a reference to a constructor declared elsewhere, but
  /// it appears after type parameters (e.g. `foo` in `X<Y>.foo`).
  static const constructorReferenceContinuationAfterTypeArguments =
      const IdentifierContext._(
          'constructorReferenceContinuationAfterTypeArguments',
          isContinuation: true);

  /// Identifier is the declaration of a label (i.e. it is followed by `:` and
  /// then a statement).
  static const labelDeclaration =
      const IdentifierContext._('labelDeclaration', inDeclaration: true);

  /// Identifier is the start of a reference occurring in a literal symbol (e.g.
  /// `foo` in `#foo`).
  static const literalSymbol =
      const IdentifierContext._('literalSymbol', inSymbol: true);

  /// Identifier is part of a reference occurring in a literal symbol, but it's
  /// not the first identifier of the reference (e.g. `foo` in `#prefix.foo`).
  static const literalSymbolContinuation = const IdentifierContext._(
      'literalSymbolContinuation',
      inSymbol: true,
      isContinuation: true);

  /// Identifier appears in an expression, and it does not immediately follow a
  /// `.`.
  static const expression =
      const IdentifierContext._('expression', isScopeReference: true);

  /// Identifier appears in an expression, and it immediately follows a `.`.
  static const expressionContinuation =
      const IdentifierContext._('expressionContinuation', isContinuation: true);

  /// Identifier is a reference to a named argument of a function or method
  /// invocation (e.g. `foo` in `f(foo: 0);`.
  static const namedArgumentReference = const IdentifierContext._(
      'namedArgumentReference',
      allowedInConstantExpression: true);

  /// Identifier is a name being declared by a local variable declaration.
  static const localVariableDeclaration = const IdentifierContext._(
      'localVariableDeclaration',
      inDeclaration: true);

  /// Identifier is a reference to a label (e.g. `foo` in `break foo;`).
  /// Labels have their own scope.
  static const labelReference = const IdentifierContext._('labelReference');

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

  const IdentifierContext._(this._name,
      {this.inDeclaration: false,
      this.inLibraryOrPartOfDeclaration: false,
      this.inSymbol: false,
      this.isContinuation: false,
      this.isScopeReference: false,
      this.isBuiltInIdentifierAllowed: true,
      bool allowedInConstantExpression})
      : this.allowedInConstantExpression =
            // Generally, declarations are legal in constant expressions.  A
            // continuation doesn't affect constant expressions: if what it's
            // continuing is a problem, it has already been reported.
            allowedInConstantExpression ??
                (inDeclaration || isContinuation || inSymbol);

  String toString() => _name;
}
