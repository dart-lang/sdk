// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars

part of 'codes.dart';

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractClassMember = const MessageCode(
  "AbstractClassMember",
  sharedCode: SharedCode.AbstractClassMember,
  problemMessage: """Members of classes can't be declared to be 'abstract'.""",
  correctionMessage:
      """Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractExtensionField = const MessageCode(
  "AbstractExtensionField",
  pseudoSharedCode: PseudoSharedCode.abstractExtensionField,
  problemMessage: """Extension fields can't be declared 'abstract'.""",
  correctionMessage: """Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractExternalField = const MessageCode(
  "AbstractExternalField",
  sharedCode: SharedCode.AbstractExternalField,
  problemMessage:
      """Fields can't be declared both 'abstract' and 'external'.""",
  correctionMessage: """Try removing the 'abstract' or 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFinalBaseClass = const MessageCode(
  "AbstractFinalBaseClass",
  sharedCode: SharedCode.AbstractFinalBaseClass,
  problemMessage:
      """An 'abstract' class can't be declared as both 'final' and 'base'.""",
  correctionMessage: """Try removing either the 'final' or 'base' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFinalInterfaceClass = const MessageCode(
  "AbstractFinalInterfaceClass",
  sharedCode: SharedCode.AbstractFinalInterfaceClass,
  problemMessage:
      """An 'abstract' class can't be declared as both 'final' and 'interface'.""",
  correctionMessage:
      """Try removing either the 'final' or 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractLateField = const MessageCode(
  "AbstractLateField",
  sharedCode: SharedCode.AbstractLateField,
  problemMessage: """Abstract fields cannot be late.""",
  correctionMessage: """Try removing the 'abstract' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractNotSync = const MessageCode(
  "AbstractNotSync",
  pseudoSharedCode: PseudoSharedCode.nonSyncAbstractMethod,
  problemMessage:
      """Abstract methods can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractSealedClass = const MessageCode(
  "AbstractSealedClass",
  sharedCode: SharedCode.AbstractSealedClass,
  problemMessage:
      """A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.""",
  correctionMessage: """Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractStaticField = const MessageCode(
  "AbstractStaticField",
  sharedCode: SharedCode.AbstractStaticField,
  problemMessage: """Static fields can't be declared 'abstract'.""",
  correctionMessage: """Try removing the 'abstract' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAnnotationOnTypeArgument = const MessageCode(
  "AnnotationOnTypeArgument",
  sharedCode: SharedCode.AnnotationOnTypeArgument,
  problemMessage:
      """Type arguments can't have annotations because they aren't declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int character),
  Message Function({required int character})
>
codeAsciiControlCharacter = const Template(
  "AsciiControlCharacter",
  withArgumentsOld: _withArgumentsOldAsciiControlCharacter,
  withArguments: _withArgumentsAsciiControlCharacter,
  pseudoSharedCode: PseudoSharedCode.illegalCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter({required int character}) {
  var character_0 = conversions.codePointToUnicode(character);
  return new Message(
    codeAsciiControlCharacter,
    problemMessage:
        """The control character ${character_0} can only be used in strings and comments.""",
    arguments: {'character': character},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldAsciiControlCharacter(int character) =>
    _withArgumentsAsciiControlCharacter(character: character);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAssertAsExpression = const MessageCode(
  "AssertAsExpression",
  pseudoSharedCode: PseudoSharedCode.assertAsExpression,
  problemMessage: """`assert` can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitAsIdentifier = const MessageCode(
  "AwaitAsIdentifier",
  pseudoSharedCode: PseudoSharedCode.asyncKeywordUsedAsIdentifier,
  problemMessage:
      """'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitForNotAsync = const MessageCode(
  "AwaitForNotAsync",
  pseudoSharedCode: PseudoSharedCode.asyncForInWrongContext,
  problemMessage:
      """The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
  correctionMessage:
      """Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitNotAsync = const MessageCode(
  "AwaitNotAsync",
  pseudoSharedCode: PseudoSharedCode.awaitInWrongContext,
  problemMessage:
      """'await' can only be used in 'async' or 'async*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeBaseEnum = const MessageCode(
  "BaseEnum",
  sharedCode: SharedCode.BaseEnum,
  problemMessage: """Enums can't be declared to be 'base'.""",
  correctionMessage: """Try removing the keyword 'base'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeBinaryOperatorWrittenOut = const Template(
  "BinaryOperatorWrittenOut",
  withArgumentsOld: _withArgumentsOldBinaryOperatorWrittenOut,
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
  sharedCode: SharedCode.BinaryOperatorWrittenOut,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBinaryOperatorWrittenOut({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeBinaryOperatorWrittenOut,
    problemMessage:
        """Binary operator '${string_0}' is written as '${string2_0}' instead of the written out word.""",
    correctionMessage: """Try replacing '${string_0}' with '${string2_0}'.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBinaryOperatorWrittenOut(
  String string,
  String string2,
) => _withArgumentsBinaryOperatorWrittenOut(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeBreakOutsideOfLoop = const MessageCode(
  "BreakOutsideOfLoop",
  sharedCode: SharedCode.BreakOutsideOfLoop,
  problemMessage:
      """A break statement can't be used outside of a loop or switch statement.""",
  correctionMessage: """Try removing the break statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeBuiltInIdentifierAsType = const Template(
  "BuiltInIdentifierAsType",
  withArgumentsOld: _withArgumentsOldBuiltInIdentifierAsType,
  withArguments: _withArgumentsBuiltInIdentifierAsType,
  pseudoSharedCode: PseudoSharedCode.builtInIdentifierAsType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeBuiltInIdentifierAsType,
    problemMessage:
        """The built-in identifier '${lexeme_0}' can't be used as a type.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBuiltInIdentifierAsType(Token lexeme) =>
    _withArgumentsBuiltInIdentifierAsType(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeBuiltInIdentifierInDeclaration = const Template(
  "BuiltInIdentifierInDeclaration",
  withArgumentsOld: _withArgumentsOldBuiltInIdentifierInDeclaration,
  withArguments: _withArgumentsBuiltInIdentifierInDeclaration,
  pseudoSharedCode: PseudoSharedCode.builtInIdentifierInDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeBuiltInIdentifierInDeclaration,
    problemMessage: """Can't use '${lexeme_0}' as a name here.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldBuiltInIdentifierInDeclaration(Token lexeme) =>
    _withArgumentsBuiltInIdentifierInDeclaration(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCatchSyntax = const MessageCode(
  "CatchSyntax",
  sharedCode: SharedCode.CatchSyntax,
  problemMessage:
      """'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      """No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCatchSyntaxExtraParameters = const MessageCode(
  "CatchSyntaxExtraParameters",
  sharedCode: SharedCode.CatchSyntaxExtraParameters,
  problemMessage:
      """'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      """No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeClassInClass = const MessageCode(
  "ClassInClass",
  sharedCode: SharedCode.ClassInClass,
  problemMessage: """Classes can't be declared inside other classes.""",
  correctionMessage: """Try moving the class to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeColonInPlaceOfIn = const MessageCode(
  "ColonInPlaceOfIn",
  sharedCode: SharedCode.ColonInPlaceOfIn,
  problemMessage: """For-in loops use 'in' rather than a colon.""",
  correctionMessage: """Try replacing the colon with the keyword 'in'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeConflictingModifiers = const Template(
  "ConflictingModifiers",
  withArgumentsOld: _withArgumentsOldConflictingModifiers,
  withArguments: _withArgumentsConflictingModifiers,
  sharedCode: SharedCode.ConflictingModifiers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictingModifiers({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeConflictingModifiers,
    problemMessage:
        """Members can't be declared to be both '${string_0}' and '${string2_0}'.""",
    correctionMessage: """Try removing one of the keywords.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConflictingModifiers(String string, String string2) =>
    _withArgumentsConflictingModifiers(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstAndFinal = const MessageCode(
  "ConstAndFinal",
  sharedCode: SharedCode.ConstAndFinal,
  problemMessage:
      """Members can't be declared to be both 'const' and 'final'.""",
  correctionMessage: """Try removing either the 'const' or 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstClass = const MessageCode(
  "ConstClass",
  sharedCode: SharedCode.ConstClass,
  problemMessage: """Classes can't be declared to be 'const'.""",
  correctionMessage:
      """Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorWithBody = const MessageCode(
  "ConstConstructorWithBody",
  pseudoSharedCode: PseudoSharedCode.constConstructorWithBody,
  problemMessage: """A const constructor can't have a body.""",
  correctionMessage: """Try removing either the 'const' keyword or the body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstFactory = const MessageCode(
  "ConstFactory",
  sharedCode: SharedCode.ConstFactory,
  problemMessage:
      """Only redirecting factory constructors can be declared to be 'const'.""",
  correctionMessage:
      """Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstFieldWithoutInitializer = const Template(
  "ConstFieldWithoutInitializer",
  withArgumentsOld: _withArgumentsOldConstFieldWithoutInitializer,
  withArguments: _withArgumentsConstFieldWithoutInitializer,
  pseudoSharedCode: PseudoSharedCode.constNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeConstFieldWithoutInitializer,
    problemMessage: """The const variable '${name_0}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldConstFieldWithoutInitializer(String name) =>
    _withArgumentsConstFieldWithoutInitializer(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstMethod = const MessageCode(
  "ConstMethod",
  sharedCode: SharedCode.ConstMethod,
  problemMessage:
      """Getters, setters and methods can't be declared to be 'const'.""",
  correctionMessage: """Try removing the 'const' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithReturnType = const MessageCode(
  "ConstructorWithReturnType",
  sharedCode: SharedCode.ConstructorWithReturnType,
  problemMessage: """Constructors can't have a return type.""",
  correctionMessage: """Try removing the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithTypeArguments = const MessageCode(
  "ConstructorWithTypeArguments",
  sharedCode: SharedCode.ConstructorWithTypeArguments,
  problemMessage:
      """A constructor invocation can't have type arguments after the constructor name.""",
  correctionMessage:
      """Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithTypeParameters = const MessageCode(
  "ConstructorWithTypeParameters",
  sharedCode: SharedCode.ConstructorWithTypeParameters,
  problemMessage: """Constructors can't have type parameters.""",
  correctionMessage: """Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithWrongName = const MessageCode(
  "ConstructorWithWrongName",
  sharedCode: SharedCode.ConstructorWithWrongName,
  problemMessage:
      """The name of a constructor must match the name of the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeContinueOutsideOfLoop = const MessageCode(
  "ContinueOutsideOfLoop",
  sharedCode: SharedCode.ContinueOutsideOfLoop,
  problemMessage:
      """A continue statement can't be used outside of a loop or switch statement.""",
  correctionMessage: """Try removing the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeContinueWithoutLabelInCase = const MessageCode(
  "ContinueWithoutLabelInCase",
  sharedCode: SharedCode.ContinueWithoutLabelInCase,
  problemMessage:
      """A continue statement in a switch statement must have a label as a target.""",
  correctionMessage:
      """Try adding a label associated with one of the case clauses to the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCovariantAndStatic = const MessageCode(
  "CovariantAndStatic",
  sharedCode: SharedCode.CovariantAndStatic,
  problemMessage:
      """Members can't be declared to be both 'covariant' and 'static'.""",
  correctionMessage:
      """Try removing either the 'covariant' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCovariantMember = const MessageCode(
  "CovariantMember",
  sharedCode: SharedCode.CovariantMember,
  problemMessage:
      """Getters, setters and methods can't be declared to be 'covariant'.""",
  correctionMessage: """Try removing the 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDefaultInSwitchExpression = const MessageCode(
  "DefaultInSwitchExpression",
  sharedCode: SharedCode.DefaultInSwitchExpression,
  problemMessage: """A switch expression may not use the `default` keyword.""",
  correctionMessage: """Try replacing `default` with `_`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeferredAfterPrefix = const MessageCode(
  "DeferredAfterPrefix",
  sharedCode: SharedCode.DeferredAfterPrefix,
  problemMessage:
      """The deferred keyword should come immediately before the prefix ('as' clause).""",
  correctionMessage: """Try moving the deferred keyword before the prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDirectiveAfterDeclaration = const MessageCode(
  "DirectiveAfterDeclaration",
  sharedCode: SharedCode.DirectiveAfterDeclaration,
  problemMessage: """Directives must appear before any declarations.""",
  correctionMessage: """Try moving the directive before any declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDuplicateDeferred = const MessageCode(
  "DuplicateDeferred",
  sharedCode: SharedCode.DuplicateDeferred,
  problemMessage:
      """An import directive can only have one 'deferred' keyword.""",
  correctionMessage: """Try removing all but one 'deferred' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicateLabelInSwitchStatement = const Template(
  "DuplicateLabelInSwitchStatement",
  withArgumentsOld: _withArgumentsOldDuplicateLabelInSwitchStatement,
  withArguments: _withArgumentsDuplicateLabelInSwitchStatement,
  sharedCode: SharedCode.DuplicateLabelInSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeDuplicateLabelInSwitchStatement,
    problemMessage:
        """The label '${name_0}' was already used in this switch statement.""",
    correctionMessage: """Try choosing a different name for this label.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicateLabelInSwitchStatement(String name) =>
    _withArgumentsDuplicateLabelInSwitchStatement(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDuplicatePrefix = const MessageCode(
  "DuplicatePrefix",
  sharedCode: SharedCode.DuplicatePrefix,
  problemMessage:
      """An import directive can only have one prefix ('as' clause).""",
  correctionMessage: """Try removing all but one prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeDuplicatedModifier = const Template(
  "DuplicatedModifier",
  withArgumentsOld: _withArgumentsOldDuplicatedModifier,
  withArguments: _withArgumentsDuplicatedModifier,
  sharedCode: SharedCode.DuplicatedModifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeDuplicatedModifier,
    problemMessage: """The modifier '${lexeme_0}' was already specified.""",
    correctionMessage:
        """Try removing all but one occurrence of the modifier.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldDuplicatedModifier(Token lexeme) =>
    _withArgumentsDuplicatedModifier(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyNamedParameterList = const MessageCode(
  "EmptyNamedParameterList",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """Named parameter lists cannot be empty.""",
  correctionMessage: """Try adding a named parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyOptionalParameterList = const MessageCode(
  "EmptyOptionalParameterList",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """Optional parameter lists cannot be empty.""",
  correctionMessage: """Try adding an optional parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyRecordTypeNamedFieldsList = const MessageCode(
  "EmptyRecordTypeNamedFieldsList",
  sharedCode: SharedCode.EmptyRecordTypeNamedFieldsList,
  problemMessage:
      """The list of named fields in a record type can't be empty.""",
  correctionMessage: """Try adding a named field to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEncoding = const MessageCode(
  "Encoding",
  pseudoSharedCode: PseudoSharedCode.encoding,
  problemMessage: """Unable to decode bytes as UTF-8.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumInClass = const MessageCode(
  "EnumInClass",
  sharedCode: SharedCode.EnumInClass,
  problemMessage: """Enums can't be declared inside classes.""",
  correctionMessage: """Try moving the enum to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEqualityCannotBeEqualityOperand = const MessageCode(
  "EqualityCannotBeEqualityOperand",
  sharedCode: SharedCode.EqualityCannotBeEqualityOperand,
  problemMessage:
      """A comparison expression can't be an operand of another comparison expression.""",
  correctionMessage:
      """Try putting parentheses around one of the comparisons.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedAfterButGot = const Template(
  "ExpectedAfterButGot",
  withArgumentsOld: _withArgumentsOldExpectedAfterButGot,
  withArguments: _withArgumentsExpectedAfterButGot,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedAfterButGot({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExpectedAfterButGot,
    problemMessage: """Expected '${string_0}' after this.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedAfterButGot(String string) =>
    _withArgumentsExpectedAfterButGot(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedAnInitializer = const MessageCode(
  "ExpectedAnInitializer",
  sharedCode: SharedCode.ExpectedAnInitializer,
  problemMessage: """Expected an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedBody = const MessageCode(
  "ExpectedBody",
  pseudoSharedCode: PseudoSharedCode.missingFunctionBody,
  problemMessage: """Expected a function body or '=>'.""",
  correctionMessage: """Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedButGot = const Template(
  "ExpectedButGot",
  withArgumentsOld: _withArgumentsOldExpectedButGot,
  withArguments: _withArgumentsExpectedButGot,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExpectedButGot,
    problemMessage: """Expected '${string_0}' before this.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedButGot(String string) =>
    _withArgumentsExpectedButGot(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedCatchClauseBody = const MessageCode(
  "ExpectedCatchClauseBody",
  sharedCode: SharedCode.ExpectedCatchClauseBody,
  problemMessage: """A catch clause must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedClassBody = const MessageCode(
  "ExpectedClassBody",
  sharedCode: SharedCode.ExpectedClassBody,
  problemMessage:
      """A class declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedClassMember = const Template(
  "ExpectedClassMember",
  withArgumentsOld: _withArgumentsOldExpectedClassMember,
  withArguments: _withArgumentsExpectedClassMember,
  pseudoSharedCode: PseudoSharedCode.expectedClassMember,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedClassMember,
    problemMessage: """Expected a class member, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedClassMember(Token lexeme) =>
    _withArgumentsExpectedClassMember(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedDeclaration = const Template(
  "ExpectedDeclaration",
  withArgumentsOld: _withArgumentsOldExpectedDeclaration,
  withArguments: _withArgumentsExpectedDeclaration,
  pseudoSharedCode: PseudoSharedCode.expectedExecutable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedDeclaration,
    problemMessage: """Expected a declaration, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedDeclaration(Token lexeme) =>
    _withArgumentsExpectedDeclaration(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedElseOrComma = const MessageCode(
  "ExpectedElseOrComma",
  sharedCode: SharedCode.ExpectedElseOrComma,
  problemMessage: """Expected 'else' or comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedEnumBody = const Template(
  "ExpectedEnumBody",
  withArgumentsOld: _withArgumentsOldExpectedEnumBody,
  withArguments: _withArgumentsExpectedEnumBody,
  pseudoSharedCode: PseudoSharedCode.missingEnumBody,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedEnumBody({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedEnumBody,
    problemMessage: """Expected a enum body, but got '${lexeme_0}'.""",
    correctionMessage:
        """An enum definition must have a body with at least one constant name.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedEnumBody(Token lexeme) =>
    _withArgumentsExpectedEnumBody(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedExtensionBody = const MessageCode(
  "ExpectedExtensionBody",
  sharedCode: SharedCode.ExpectedExtensionBody,
  problemMessage:
      """An extension declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedExtensionTypeBody = const MessageCode(
  "ExpectedExtensionTypeBody",
  sharedCode: SharedCode.ExpectedExtensionTypeBody,
  problemMessage:
      """An extension type declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedFinallyClauseBody = const MessageCode(
  "ExpectedFinallyClauseBody",
  sharedCode: SharedCode.ExpectedFinallyClauseBody,
  problemMessage: """A finally clause must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedFunctionBody = const Template(
  "ExpectedFunctionBody",
  withArgumentsOld: _withArgumentsOldExpectedFunctionBody,
  withArguments: _withArgumentsExpectedFunctionBody,
  pseudoSharedCode: PseudoSharedCode.missingFunctionBody,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedFunctionBody,
    problemMessage: """Expected a function body, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedFunctionBody(Token lexeme) =>
    _withArgumentsExpectedFunctionBody(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedHexDigit = const MessageCode(
  "ExpectedHexDigit",
  pseudoSharedCode: PseudoSharedCode.missingHexDigit,
  problemMessage: """A hex digit (0-9 or A-F) must follow '0x'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedIdentifier = const Template(
  "ExpectedIdentifier",
  withArgumentsOld: _withArgumentsOldExpectedIdentifier,
  withArguments: _withArgumentsExpectedIdentifier,
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedIdentifier,
    problemMessage: """Expected an identifier, but got '${lexeme_0}'.""",
    correctionMessage: """Try inserting an identifier before '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedIdentifier(Token lexeme) =>
    _withArgumentsExpectedIdentifier(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedIdentifierButGotKeyword = const Template(
  "ExpectedIdentifierButGotKeyword",
  withArgumentsOld: _withArgumentsOldExpectedIdentifierButGotKeyword,
  withArguments: _withArgumentsExpectedIdentifierButGotKeyword,
  sharedCode: SharedCode.ExpectedIdentifierButGotKeyword,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifierButGotKeyword({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedIdentifierButGotKeyword,
    problemMessage:
        """'${lexeme_0}' can't be used as an identifier because it's a keyword.""",
    correctionMessage:
        """Try renaming this to be an identifier that isn't a keyword.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedIdentifierButGotKeyword(Token lexeme) =>
    _withArgumentsExpectedIdentifierButGotKeyword(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedInstead = const Template(
  "ExpectedInstead",
  withArgumentsOld: _withArgumentsOldExpectedInstead,
  withArguments: _withArgumentsExpectedInstead,
  sharedCode: SharedCode.ExpectedInstead,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedInstead({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExpectedInstead,
    problemMessage: """Expected '${string_0}' instead of this.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedInstead(String string) =>
    _withArgumentsExpectedInstead(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedMixinBody = const MessageCode(
  "ExpectedMixinBody",
  sharedCode: SharedCode.ExpectedMixinBody,
  problemMessage:
      """A mixin declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedStatement = const MessageCode(
  "ExpectedStatement",
  sharedCode: SharedCode.ExpectedStatement,
  problemMessage: """Expected a statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedString = const Template(
  "ExpectedString",
  withArgumentsOld: _withArgumentsOldExpectedString,
  withArguments: _withArgumentsExpectedString,
  pseudoSharedCode: PseudoSharedCode.expectedStringLiteral,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedString,
    problemMessage: """Expected a String, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedString(Token lexeme) =>
    _withArgumentsExpectedString(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedSwitchExpressionBody = const MessageCode(
  "ExpectedSwitchExpressionBody",
  sharedCode: SharedCode.ExpectedSwitchExpressionBody,
  problemMessage:
      """A switch expression must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedSwitchStatementBody = const MessageCode(
  "ExpectedSwitchStatementBody",
  sharedCode: SharedCode.ExpectedSwitchStatementBody,
  problemMessage:
      """A switch statement must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedToken = const Template(
  "ExpectedToken",
  withArgumentsOld: _withArgumentsOldExpectedToken,
  withArguments: _withArgumentsExpectedToken,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExpectedToken,
    problemMessage: """Expected to find '${string_0}'.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedToken(String string) =>
    _withArgumentsExpectedToken(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedTryStatementBody = const MessageCode(
  "ExpectedTryStatementBody",
  sharedCode: SharedCode.ExpectedTryStatementBody,
  problemMessage: """A try statement must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedType = const Template(
  "ExpectedType",
  withArgumentsOld: _withArgumentsOldExpectedType,
  withArguments: _withArgumentsExpectedType,
  pseudoSharedCode: PseudoSharedCode.expectedTypeName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExpectedType,
    problemMessage: """Expected a type, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExpectedType(Token lexeme) =>
    _withArgumentsExpectedType(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeExperimentNotEnabled = const Template(
  "ExperimentNotEnabled",
  withArgumentsOld: _withArgumentsOldExperimentNotEnabled,
  withArguments: _withArgumentsExperimentNotEnabled,
  sharedCode: SharedCode.ExperimentNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabled({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeExperimentNotEnabled,
    problemMessage:
        """This requires the '${string_0}' language feature to be enabled.""",
    correctionMessage:
        """Try updating your pubspec.yaml to set the minimum SDK constraint to ${string2_0} or higher, and running 'pub get'.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentNotEnabled(String string, String string2) =>
    _withArgumentsExperimentNotEnabled(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExperimentNotEnabledOffByDefault = const Template(
  "ExperimentNotEnabledOffByDefault",
  withArgumentsOld: _withArgumentsOldExperimentNotEnabledOffByDefault,
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
  sharedCode: SharedCode.ExperimentNotEnabledOffByDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabledOffByDefault({
  required String string,
}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeExperimentNotEnabledOffByDefault,
    problemMessage:
        """This requires the experimental '${string_0}' language feature to be enabled.""",
    correctionMessage:
        """Try passing the '--enable-experiment=${string_0}' command line option.""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExperimentNotEnabledOffByDefault(String string) =>
    _withArgumentsExperimentNotEnabledOffByDefault(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExportAfterPart = const MessageCode(
  "ExportAfterPart",
  sharedCode: SharedCode.ExportAfterPart,
  problemMessage: """Export directives must precede part directives.""",
  correctionMessage:
      """Try moving the export directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionAugmentationHasOnClause = const MessageCode(
  "ExtensionAugmentationHasOnClause",
  sharedCode: SharedCode.ExtensionAugmentationHasOnClause,
  problemMessage: """Extension augmentations can't have 'on' clauses.""",
  correctionMessage: """Try removing the 'on' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresAbstractMember = const MessageCode(
  "ExtensionDeclaresAbstractMember",
  sharedCode: SharedCode.ExtensionDeclaresAbstractMember,
  problemMessage: """Extensions can't declare abstract members.""",
  correctionMessage: """Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresConstructor = const MessageCode(
  "ExtensionDeclaresConstructor",
  sharedCode: SharedCode.ExtensionDeclaresConstructor,
  problemMessage: """Extensions can't declare constructors.""",
  correctionMessage: """Try removing the constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresInstanceField = const MessageCode(
  "ExtensionDeclaresInstanceField",
  pseudoSharedCode: PseudoSharedCode.extensionDeclaresInstanceField,
  problemMessage: """Extensions can't declare instance fields""",
  correctionMessage:
      """Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeDeclaresAbstractMember = const MessageCode(
  "ExtensionTypeDeclaresAbstractMember",
  pseudoSharedCode: PseudoSharedCode.extensionTypeWithAbstractMember,
  problemMessage: """Extension types can't declare abstract members.""",
  correctionMessage: """Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeDeclaresInstanceField = const MessageCode(
  "ExtensionTypeDeclaresInstanceField",
  pseudoSharedCode: PseudoSharedCode.extensionTypeDeclaresInstanceField,
  problemMessage: """Extension types can't declare instance fields""",
  correctionMessage:
      """Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeExtends = const MessageCode(
  "ExtensionTypeExtends",
  sharedCode: SharedCode.ExtensionTypeExtends,
  problemMessage:
      """An extension type declaration can't have an 'extends' clause.""",
  correctionMessage:
      """Try removing the 'extends' clause or replacing the 'extends' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeWith = const MessageCode(
  "ExtensionTypeWith",
  sharedCode: SharedCode.ExtensionTypeWith,
  problemMessage:
      """An extension type declaration can't have a 'with' clause.""",
  correctionMessage:
      """Try removing the 'with' clause or replacing the 'with' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalClass = const MessageCode(
  "ExternalClass",
  sharedCode: SharedCode.ExternalClass,
  problemMessage: """Classes can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeExternalConstructorWithFieldInitializers = const MessageCode(
  "ExternalConstructorWithFieldInitializers",
  sharedCode: SharedCode.ExternalConstructorWithFieldInitializers,
  problemMessage: """An external constructor can't initialize fields.""",
  correctionMessage:
      """Try removing the field initializers, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalConstructorWithInitializer = const MessageCode(
  "ExternalConstructorWithInitializer",
  sharedCode: SharedCode.ExternalConstructorWithInitializer,
  problemMessage: """An external constructor can't have any initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalEnum = const MessageCode(
  "ExternalEnum",
  sharedCode: SharedCode.ExternalEnum,
  problemMessage: """Enums can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalFactoryRedirection = const MessageCode(
  "ExternalFactoryRedirection",
  sharedCode: SharedCode.ExternalFactoryRedirection,
  problemMessage: """A redirecting factory can't be external.""",
  correctionMessage: """Try removing the 'external' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalFactoryWithBody = const MessageCode(
  "ExternalFactoryWithBody",
  sharedCode: SharedCode.ExternalFactoryWithBody,
  problemMessage: """External factories can't have a body.""",
  correctionMessage:
      """Try removing the body of the factory, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalLateField = const MessageCode(
  "ExternalLateField",
  sharedCode: SharedCode.ExternalLateField,
  problemMessage: """External fields cannot be late.""",
  correctionMessage: """Try removing the 'external' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalMethodWithBody = const MessageCode(
  "ExternalMethodWithBody",
  sharedCode: SharedCode.ExternalMethodWithBody,
  problemMessage: """An external or native method can't have a body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalTypedef = const MessageCode(
  "ExternalTypedef",
  sharedCode: SharedCode.ExternalTypedef,
  problemMessage: """Typedefs can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExtraneousModifier = const Template(
  "ExtraneousModifier",
  withArgumentsOld: _withArgumentsOldExtraneousModifier,
  withArguments: _withArgumentsExtraneousModifier,
  sharedCode: SharedCode.ExtraneousModifier,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExtraneousModifier,
    problemMessage: """Can't have modifier '${lexeme_0}' here.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtraneousModifier(Token lexeme) =>
    _withArgumentsExtraneousModifier(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExtraneousModifierInExtension = const Template(
  "ExtraneousModifierInExtension",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInExtension,
  withArguments: _withArgumentsExtraneousModifierInExtension,
  sharedCode: SharedCode.ExtraneousModifierInExtension,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtension({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExtraneousModifierInExtension,
    problemMessage: """Can't have modifier '${lexeme_0}' in an extension.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtraneousModifierInExtension(Token lexeme) =>
    _withArgumentsExtraneousModifierInExtension(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExtraneousModifierInExtensionType = const Template(
  "ExtraneousModifierInExtensionType",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInExtensionType,
  withArguments: _withArgumentsExtraneousModifierInExtensionType,
  sharedCode: SharedCode.ExtraneousModifierInExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtensionType({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExtraneousModifierInExtensionType,
    problemMessage:
        """Can't have modifier '${lexeme_0}' in an extension type.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtraneousModifierInExtensionType(Token lexeme) =>
    _withArgumentsExtraneousModifierInExtensionType(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExtraneousModifierInPrimaryConstructor = const Template(
  "ExtraneousModifierInPrimaryConstructor",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInPrimaryConstructor,
  withArguments: _withArgumentsExtraneousModifierInPrimaryConstructor,
  sharedCode: SharedCode.ExtraneousModifierInPrimaryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInPrimaryConstructor({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeExtraneousModifierInPrimaryConstructor,
    problemMessage:
        """Can't have modifier '${lexeme_0}' in a primary constructor.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldExtraneousModifierInPrimaryConstructor(Token lexeme) =>
    _withArgumentsExtraneousModifierInPrimaryConstructor(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFactoryNotSync = const MessageCode(
  "FactoryNotSync",
  pseudoSharedCode: PseudoSharedCode.nonSyncFactory,
  problemMessage: """Factory bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFactoryTopLevelDeclaration = const MessageCode(
  "FactoryTopLevelDeclaration",
  sharedCode: SharedCode.FactoryTopLevelDeclaration,
  problemMessage:
      """Top-level declarations can't be declared to be 'factory'.""",
  correctionMessage: """Try removing the keyword 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFastaCLIArgumentRequired = const Template(
  "FastaCLIArgumentRequired",
  withArgumentsOld: _withArgumentsOldFastaCLIArgumentRequired,
  withArguments: _withArgumentsFastaCLIArgumentRequired,
  pseudoSharedCode: PseudoSharedCode.fastaCliArgumentRequired,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFastaCLIArgumentRequired,
    problemMessage: """Expected value after '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFastaCLIArgumentRequired(String name) =>
    _withArgumentsFastaCLIArgumentRequired(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFieldInitializedOutsideDeclaringClass = const MessageCode(
  "FieldInitializedOutsideDeclaringClass",
  sharedCode: SharedCode.FieldInitializedOutsideDeclaringClass,
  problemMessage: """A field can only be initialized in its declaring class""",
  correctionMessage:
      """Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFieldInitializerOutsideConstructor = const MessageCode(
  "FieldInitializerOutsideConstructor",
  sharedCode: SharedCode.FieldInitializerOutsideConstructor,
  problemMessage:
      """Field formal parameters can only be used in a constructor.""",
  correctionMessage: """Try removing 'this.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndCovariant = const MessageCode(
  "FinalAndCovariant",
  sharedCode: SharedCode.FinalAndCovariant,
  problemMessage:
      """Members can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      """Try removing either the 'final' or 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndCovariantLateWithInitializer = const MessageCode(
  "FinalAndCovariantLateWithInitializer",
  sharedCode: SharedCode.FinalAndCovariantLateWithInitializer,
  problemMessage:
      """Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      """Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndVar = const MessageCode(
  "FinalAndVar",
  sharedCode: SharedCode.FinalAndVar,
  problemMessage: """Members can't be declared to be both 'final' and 'var'.""",
  correctionMessage: """Try removing the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalEnum = const MessageCode(
  "FinalEnum",
  sharedCode: SharedCode.FinalEnum,
  problemMessage: """Enums can't be declared to be 'final'.""",
  correctionMessage: """Try removing the keyword 'final'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFinalFieldWithoutInitializer = const Template(
  "FinalFieldWithoutInitializer",
  withArgumentsOld: _withArgumentsOldFinalFieldWithoutInitializer,
  withArguments: _withArgumentsFinalFieldWithoutInitializer,
  pseudoSharedCode: PseudoSharedCode.finalNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeFinalFieldWithoutInitializer,
    problemMessage: """The final variable '${name_0}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldFinalFieldWithoutInitializer(String name) =>
    _withArgumentsFinalFieldWithoutInitializer(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalMixin = const MessageCode(
  "FinalMixin",
  sharedCode: SharedCode.FinalMixin,
  problemMessage: """A mixin can't be declared 'final'.""",
  correctionMessage: """Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalMixinClass = const MessageCode(
  "FinalMixinClass",
  sharedCode: SharedCode.FinalMixinClass,
  problemMessage: """A mixin class can't be declared 'final'.""",
  correctionMessage: """Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFunctionTypeDefaultValue = const MessageCode(
  "FunctionTypeDefaultValue",
  pseudoSharedCode: PseudoSharedCode.defaultValueInFunctionType,
  problemMessage: """Can't have a default value in a function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFunctionTypedParameterVar = const MessageCode(
  "FunctionTypedParameterVar",
  sharedCode: SharedCode.FunctionTypedParameterVar,
  problemMessage:
      """Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
  correctionMessage: """Try replacing the keyword with a return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGeneratorReturnsValue = const MessageCode(
  "GeneratorReturnsValue",
  pseudoSharedCode: PseudoSharedCode.returnInGenerator,
  problemMessage: """'sync*' and 'async*' can't return a value.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGetterConstructor = const MessageCode(
  "GetterConstructor",
  sharedCode: SharedCode.GetterConstructor,
  problemMessage: """Constructors can't be a getter.""",
  correctionMessage: """Try removing 'get'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGetterWithFormals = const MessageCode(
  "GetterWithFormals",
  pseudoSharedCode: PseudoSharedCode.getterWithParameters,
  problemMessage: """A getter can't have formal parameters.""",
  correctionMessage: """Try removing '(...)'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalAssignmentToNonAssignable = const MessageCode(
  "IllegalAssignmentToNonAssignable",
  sharedCode: SharedCode.IllegalAssignmentToNonAssignable,
  problemMessage: """Illegal assignment to non-assignable expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeIllegalPatternAssignmentVariableName = const Template(
  "IllegalPatternAssignmentVariableName",
  withArgumentsOld: _withArgumentsOldIllegalPatternAssignmentVariableName,
  withArguments: _withArgumentsIllegalPatternAssignmentVariableName,
  sharedCode: SharedCode.IllegalPatternAssignmentVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternAssignmentVariableName({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeIllegalPatternAssignmentVariableName,
    problemMessage:
        """A variable assigned by a pattern assignment can't be named '${lexeme_0}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalPatternAssignmentVariableName(Token lexeme) =>
    _withArgumentsIllegalPatternAssignmentVariableName(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeIllegalPatternIdentifierName = const Template(
  "IllegalPatternIdentifierName",
  withArgumentsOld: _withArgumentsOldIllegalPatternIdentifierName,
  withArguments: _withArgumentsIllegalPatternIdentifierName,
  sharedCode: SharedCode.IllegalPatternIdentifierName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternIdentifierName({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeIllegalPatternIdentifierName,
    problemMessage:
        """A pattern can't refer to an identifier named '${lexeme_0}'.""",
    correctionMessage: """Match the identifier using '==""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalPatternIdentifierName(Token lexeme) =>
    _withArgumentsIllegalPatternIdentifierName(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeIllegalPatternVariableName = const Template(
  "IllegalPatternVariableName",
  withArgumentsOld: _withArgumentsOldIllegalPatternVariableName,
  withArguments: _withArgumentsIllegalPatternVariableName,
  sharedCode: SharedCode.IllegalPatternVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternVariableName({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeIllegalPatternVariableName,
    problemMessage:
        """The variable declared by a variable pattern can't be named '${lexeme_0}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldIllegalPatternVariableName(Token lexeme) =>
    _withArgumentsIllegalPatternVariableName(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsBeforeExtends = const MessageCode(
  "ImplementsBeforeExtends",
  sharedCode: SharedCode.ImplementsBeforeExtends,
  problemMessage:
      """The extends clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the extends clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsBeforeOn = const MessageCode(
  "ImplementsBeforeOn",
  sharedCode: SharedCode.ImplementsBeforeOn,
  problemMessage: """The on clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the on clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsBeforeWith = const MessageCode(
  "ImplementsBeforeWith",
  sharedCode: SharedCode.ImplementsBeforeWith,
  problemMessage: """The with clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the with clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImportAfterPart = const MessageCode(
  "ImportAfterPart",
  sharedCode: SharedCode.ImportAfterPart,
  problemMessage: """Import directives must precede part directives.""",
  correctionMessage:
      """Try moving the import directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInitializedVariableInForEach = const MessageCode(
  "InitializedVariableInForEach",
  sharedCode: SharedCode.InitializedVariableInForEach,
  problemMessage:
      """The loop variable in a for-each loop can't be initialized.""",
  correctionMessage:
      """Try removing the initializer, or using a different kind of loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceEnum = const MessageCode(
  "InterfaceEnum",
  sharedCode: SharedCode.InterfaceEnum,
  problemMessage: """Enums can't be declared to be 'interface'.""",
  correctionMessage: """Try removing the keyword 'interface'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceMixin = const MessageCode(
  "InterfaceMixin",
  sharedCode: SharedCode.InterfaceMixin,
  problemMessage: """A mixin can't be declared 'interface'.""",
  correctionMessage: """Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceMixinClass = const MessageCode(
  "InterfaceMixinClass",
  sharedCode: SharedCode.InterfaceMixinClass,
  problemMessage: """A mixin class can't be declared 'interface'.""",
  correctionMessage: """Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
codeInternalProblemStackNotEmpty = const Template(
  "InternalProblemStackNotEmpty",
  withArgumentsOld: _withArgumentsOldInternalProblemStackNotEmpty,
  withArguments: _withArgumentsInternalProblemStackNotEmpty,
  pseudoSharedCode: PseudoSharedCode.internalProblemStackNotEmpty,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty({
  required String name,
  required String string,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  var string_0 = conversions.validateString(string);
  return new Message(
    codeInternalProblemStackNotEmpty,
    problemMessage: """${name_0}.stack isn't empty:
  ${string_0}""",
    arguments: {'name': name, 'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemStackNotEmpty(
  String name,
  String string,
) => _withArgumentsInternalProblemStackNotEmpty(name: name, string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeInternalProblemUnhandled = const Template(
  "InternalProblemUnhandled",
  withArgumentsOld: _withArgumentsOldInternalProblemUnhandled,
  withArguments: _withArgumentsInternalProblemUnhandled,
  pseudoSharedCode: PseudoSharedCode.internalProblemUnhandled,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeInternalProblemUnhandled,
    problemMessage: """Unhandled ${string_0} in ${string2_0}.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnhandled(
  String string,
  String string2,
) => _withArgumentsInternalProblemUnhandled(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInternalProblemUnsupported = const Template(
  "InternalProblemUnsupported",
  withArgumentsOld: _withArgumentsOldInternalProblemUnsupported,
  withArguments: _withArgumentsInternalProblemUnsupported,
  pseudoSharedCode: PseudoSharedCode.internalProblemUnsupported,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInternalProblemUnsupported,
    problemMessage: """Unsupported operation: '${name_0}'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInternalProblemUnsupported(String name) =>
    _withArgumentsInternalProblemUnsupported(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterpolationInUri = const MessageCode(
  "InterpolationInUri",
  pseudoSharedCode: PseudoSharedCode.invalidLiteralInConfiguration,
  problemMessage: """Can't use string interpolation in a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidAwaitFor = const MessageCode(
  "InvalidAwaitFor",
  sharedCode: SharedCode.InvalidAwaitFor,
  problemMessage:
      """The keyword 'await' isn't allowed for a normal 'for' statement.""",
  correctionMessage:
      """Try removing the keyword, or use a for-each statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidCodePoint = const MessageCode(
  "InvalidCodePoint",
  pseudoSharedCode: PseudoSharedCode.invalidCodePoint,
  problemMessage:
      """The escape sequence starting with '\\u' isn't a valid code point.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidConstantPatternBinary = const Template(
  "InvalidConstantPatternBinary",
  withArgumentsOld: _withArgumentsOldInvalidConstantPatternBinary,
  withArguments: _withArgumentsInvalidConstantPatternBinary,
  sharedCode: SharedCode.InvalidConstantPatternBinary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternBinary({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvalidConstantPatternBinary,
    problemMessage:
        """The binary operator ${name_0} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidConstantPatternBinary(String name) =>
    _withArgumentsInvalidConstantPatternBinary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternConstPrefix = const MessageCode(
  "InvalidConstantPatternConstPrefix",
  sharedCode: SharedCode.InvalidConstantPatternConstPrefix,
  problemMessage:
      """The expression can't be prefixed by 'const' to form a constant pattern.""",
  correctionMessage:
      """Try wrapping the expression in 'const ( ... )' instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternDuplicateConst = const MessageCode(
  "InvalidConstantPatternDuplicateConst",
  sharedCode: SharedCode.InvalidConstantPatternDuplicateConst,
  problemMessage: """Duplicate 'const' keyword in constant expression.""",
  correctionMessage: """Try removing one of the 'const' keywords.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeInvalidConstantPatternEmptyRecordLiteral = const MessageCode(
  "InvalidConstantPatternEmptyRecordLiteral",
  sharedCode: SharedCode.InvalidConstantPatternEmptyRecordLiteral,
  problemMessage:
      """The empty record literal is not supported as a constant pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternGeneric = const MessageCode(
  "InvalidConstantPatternGeneric",
  sharedCode: SharedCode.InvalidConstantPatternGeneric,
  problemMessage: """This expression is not supported as a constant pattern.""",
  correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternNegation = const MessageCode(
  "InvalidConstantPatternNegation",
  sharedCode: SharedCode.InvalidConstantPatternNegation,
  problemMessage:
      """Only negation of a numeric literal is supported as a constant pattern.""",
  correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidConstantPatternUnary = const Template(
  "InvalidConstantPatternUnary",
  withArgumentsOld: _withArgumentsOldInvalidConstantPatternUnary,
  withArguments: _withArgumentsInvalidConstantPatternUnary,
  sharedCode: SharedCode.InvalidConstantPatternUnary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternUnary({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeInvalidConstantPatternUnary,
    problemMessage:
        """The unary operator ${name_0} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidConstantPatternUnary(String name) =>
    _withArgumentsInvalidConstantPatternUnary(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidEscapeStarted = const MessageCode(
  "InvalidEscapeStarted",
  sharedCode: SharedCode.InvalidEscapeStarted,
  problemMessage: """The string '\\' can't stand alone.""",
  correctionMessage:
      """Try adding another backslash (\\) to escape the '\\'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidHexEscape = const MessageCode(
  "InvalidHexEscape",
  sharedCode: SharedCode.InvalidHexEscape,
  problemMessage:
      """An escape sequence starting with '\\x' must be followed by 2 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInitializer = const MessageCode(
  "InvalidInitializer",
  sharedCode: SharedCode.InvalidInitializer,
  problemMessage: """Not a valid initializer.""",
  correctionMessage:
      """To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInlineFunctionType = const MessageCode(
  "InvalidInlineFunctionType",
  pseudoSharedCode: PseudoSharedCode.invalidInlineFunctionType,
  problemMessage:
      """Inline function types cannot be used for parameters in a generic function type.""",
  correctionMessage:
      """Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInsideUnaryPattern = const MessageCode(
  "InvalidInsideUnaryPattern",
  sharedCode: SharedCode.InvalidInsideUnaryPattern,
  problemMessage:
      """This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.""",
  correctionMessage:
      """Try combining into a single pattern if possible, or enclose the inner pattern in parentheses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeInvalidOperator = const Template(
  "InvalidOperator",
  withArgumentsOld: _withArgumentsOldInvalidOperator,
  withArguments: _withArgumentsInvalidOperator,
  sharedCode: SharedCode.InvalidOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeInvalidOperator,
    problemMessage:
        """The string '${lexeme_0}' isn't a user-definable operator.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldInvalidOperator(Token lexeme) =>
    _withArgumentsInvalidOperator(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidSuperInInitializer = const MessageCode(
  "InvalidSuperInInitializer",
  sharedCode: SharedCode.InvalidSuperInInitializer,
  problemMessage:
      """Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidSyncModifier = const MessageCode(
  "InvalidSyncModifier",
  pseudoSharedCode: PseudoSharedCode.missingStarAfterSync,
  problemMessage: """Invalid modifier 'sync'.""",
  correctionMessage: """Try replacing 'sync' with 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidThisInInitializer = const MessageCode(
  "InvalidThisInInitializer",
  sharedCode: SharedCode.InvalidThisInInitializer,
  problemMessage:
      """Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUBracket = const MessageCode(
  "InvalidUnicodeEscapeUBracket",
  sharedCode: SharedCode.InvalidUnicodeEscapeUBracket,
  problemMessage:
      """An escape sequence starting with '\\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUNoBracket = const MessageCode(
  "InvalidUnicodeEscapeUNoBracket",
  sharedCode: SharedCode.InvalidUnicodeEscapeUNoBracket,
  problemMessage:
      """An escape sequence starting with '\\u' must be followed by 4 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUStarted = const MessageCode(
  "InvalidUnicodeEscapeUStarted",
  sharedCode: SharedCode.InvalidUnicodeEscapeUStarted,
  problemMessage:
      """An escape sequence starting with '\\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidVoid = const MessageCode(
  "InvalidVoid",
  pseudoSharedCode: PseudoSharedCode.expectedTypeName,
  problemMessage: """Type 'void' can't be used here.""",
  correctionMessage:
      """Try removing 'void' keyword or replace it with 'var', 'final', or a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLatePatternVariableDeclaration = const MessageCode(
  "LatePatternVariableDeclaration",
  sharedCode: SharedCode.LatePatternVariableDeclaration,
  problemMessage:
      """A pattern variable declaration may not use the `late` keyword.""",
  correctionMessage: """Try removing the keyword `late`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLibraryDirectiveNotFirst = const MessageCode(
  "LibraryDirectiveNotFirst",
  sharedCode: SharedCode.LibraryDirectiveNotFirst,
  problemMessage:
      """The library directive must appear before all other directives.""",
  correctionMessage:
      """Try moving the library directive before any other directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Token lexeme),
  Message Function({required String string, required Token lexeme})
>
codeLiteralWithClass = const Template(
  "LiteralWithClass",
  withArgumentsOld: _withArgumentsOldLiteralWithClass,
  withArguments: _withArgumentsLiteralWithClass,
  sharedCode: SharedCode.LiteralWithClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClass({
  required String string,
  required Token lexeme,
}) {
  var string_0 = conversions.validateString(string);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeLiteralWithClass,
    problemMessage:
        """A ${string_0} literal can't be prefixed by '${lexeme_0}'.""",
    correctionMessage: """Try removing '${lexeme_0}'""",
    arguments: {'string': string, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLiteralWithClass(String string, Token lexeme) =>
    _withArgumentsLiteralWithClass(string: string, lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Token lexeme),
  Message Function({required String string, required Token lexeme})
>
codeLiteralWithClassAndNew = const Template(
  "LiteralWithClassAndNew",
  withArgumentsOld: _withArgumentsOldLiteralWithClassAndNew,
  withArguments: _withArgumentsLiteralWithClassAndNew,
  sharedCode: SharedCode.LiteralWithClassAndNew,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClassAndNew({
  required String string,
  required Token lexeme,
}) {
  var string_0 = conversions.validateString(string);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeLiteralWithClassAndNew,
    problemMessage:
        """A ${string_0} literal can't be prefixed by 'new ${lexeme_0}'.""",
    correctionMessage: """Try removing 'new' and '${lexeme_0}'""",
    arguments: {'string': string, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldLiteralWithClassAndNew(String string, Token lexeme) =>
    _withArgumentsLiteralWithClassAndNew(string: string, lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLiteralWithNew = const MessageCode(
  "LiteralWithNew",
  sharedCode: SharedCode.LiteralWithNew,
  problemMessage: """A literal can't be prefixed by 'new'.""",
  correctionMessage: """Try removing 'new'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMemberWithSameNameAsClass = const MessageCode(
  "MemberWithSameNameAsClass",
  sharedCode: SharedCode.MemberWithSameNameAsClass,
  problemMessage:
      """A class member can't have the same name as the enclosing class.""",
  correctionMessage: """Try renaming the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataSpaceBeforeParenthesis = const MessageCode(
  "MetadataSpaceBeforeParenthesis",
  sharedCode: SharedCode.MetadataSpaceBeforeParenthesis,
  problemMessage:
      """Annotations can't have spaces or comments before the parenthesis.""",
  correctionMessage:
      """Remove any spaces or comments before the parenthesis.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataTypeArguments = const MessageCode(
  "MetadataTypeArguments",
  sharedCode: SharedCode.MetadataTypeArguments,
  problemMessage: """An annotation can't use type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataTypeArgumentsUninstantiated = const MessageCode(
  "MetadataTypeArgumentsUninstantiated",
  sharedCode: SharedCode.MetadataTypeArgumentsUninstantiated,
  problemMessage:
      """An annotation with type arguments must be followed by an argument list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingAssignableSelector = const MessageCode(
  "MissingAssignableSelector",
  sharedCode: SharedCode.MissingAssignableSelector,
  problemMessage: """Missing selector such as '.identifier' or '[0]'.""",
  correctionMessage: """Try adding a selector.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingAssignmentInInitializer = const MessageCode(
  "MissingAssignmentInInitializer",
  sharedCode: SharedCode.MissingAssignmentInInitializer,
  problemMessage: """Expected an assignment after the field name.""",
  correctionMessage:
      """To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingConstFinalVarOrType = const MessageCode(
  "MissingConstFinalVarOrType",
  sharedCode: SharedCode.MissingConstFinalVarOrType,
  problemMessage:
      """Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
  correctionMessage:
      """Try adding the name of the type of the variable or the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingExponent = const MessageCode(
  "MissingExponent",
  pseudoSharedCode: PseudoSharedCode.missingDigit,
  problemMessage:
      """Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
  correctionMessage:
      """Make sure there is an exponent, and remove any whitespace before it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingExpressionInThrow = const MessageCode(
  "MissingExpressionInThrow",
  sharedCode: SharedCode.MissingExpressionInThrow,
  problemMessage: """Missing expression after 'throw'.""",
  correctionMessage:
      """Add an expression after 'throw' or use 'rethrow' to throw a caught exception""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingFunctionParameters = const MessageCode(
  "MissingFunctionParameters",
  pseudoSharedCode: PseudoSharedCode.missingFunctionParameters,
  problemMessage:
      """A function declaration needs an explicit list of parameters.""",
  correctionMessage:
      """Try adding a parameter list to the function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingMethodParameters = const MessageCode(
  "MissingMethodParameters",
  pseudoSharedCode: PseudoSharedCode.missingMethodParameters,
  problemMessage:
      """A method declaration needs an explicit list of parameters.""",
  correctionMessage:
      """Try adding a parameter list to the method declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingOperatorKeyword = const MessageCode(
  "MissingOperatorKeyword",
  sharedCode: SharedCode.MissingOperatorKeyword,
  problemMessage:
      """Operator declarations must be preceded by the keyword 'operator'.""",
  correctionMessage: """Try adding the keyword 'operator'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrefixInDeferredImport = const MessageCode(
  "MissingPrefixInDeferredImport",
  sharedCode: SharedCode.MissingPrefixInDeferredImport,
  problemMessage: """Deferred imports should have a prefix.""",
  correctionMessage:
      """Try adding a prefix to the import by adding an 'as' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrimaryConstructor = const MessageCode(
  "MissingPrimaryConstructor",
  sharedCode: SharedCode.MissingPrimaryConstructor,
  problemMessage:
      """An extension type declaration must have a primary constructor declaration.""",
  correctionMessage:
      """Try adding a primary constructor to the extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrimaryConstructorParameters = const MessageCode(
  "MissingPrimaryConstructorParameters",
  sharedCode: SharedCode.MissingPrimaryConstructorParameters,
  problemMessage:
      """A primary constructor declaration must have formal parameters.""",
  correctionMessage:
      """Try adding formal parameters after the primary constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingTypedefParameters = const MessageCode(
  "MissingTypedefParameters",
  pseudoSharedCode: PseudoSharedCode.missingTypedefParameters,
  problemMessage: """A typedef needs an explicit list of parameters.""",
  correctionMessage: """Try adding a parameter list to the typedef.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinDeclaresConstructor = const MessageCode(
  "MixinDeclaresConstructor",
  sharedCode: SharedCode.MixinDeclaresConstructor,
  problemMessage: """Mixins can't declare constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinWithClause = const MessageCode(
  "MixinWithClause",
  sharedCode: SharedCode.MixinWithClause,
  problemMessage: """A mixin can't have a with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeModifierOutOfOrder = const Template(
  "ModifierOutOfOrder",
  withArgumentsOld: _withArgumentsOldModifierOutOfOrder,
  withArguments: _withArgumentsModifierOutOfOrder,
  sharedCode: SharedCode.ModifierOutOfOrder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsModifierOutOfOrder({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeModifierOutOfOrder,
    problemMessage:
        """The modifier '${string_0}' should be before the modifier '${string2_0}'.""",
    correctionMessage: """Try re-ordering the modifiers.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldModifierOutOfOrder(String string, String string2) =>
    _withArgumentsModifierOutOfOrder(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeMultipleClauses = const Template(
  "MultipleClauses",
  withArgumentsOld: _withArgumentsOldMultipleClauses,
  withArguments: _withArgumentsMultipleClauses,
  sharedCode: SharedCode.MultipleClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMultipleClauses({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeMultipleClauses,
    problemMessage:
        """Each '${string_0}' definition can have at most one '${string2_0}' clause.""",
    correctionMessage:
        """Try combining all of the '${string2_0}' clauses into a single clause.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldMultipleClauses(String string, String string2) =>
    _withArgumentsMultipleClauses(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleExtends = const MessageCode(
  "MultipleExtends",
  sharedCode: SharedCode.MultipleExtends,
  problemMessage:
      """Each class definition can have at most one extends clause.""",
  correctionMessage:
      """Try choosing one superclass and define your class to implement (or mix in) the others.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleImplements = const MessageCode(
  "MultipleImplements",
  pseudoSharedCode: PseudoSharedCode.multipleImplementsClauses,
  problemMessage:
      """Each class definition can have at most one implements clause.""",
  correctionMessage:
      """Try combining all of the implements clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleLibraryDirectives = const MessageCode(
  "MultipleLibraryDirectives",
  sharedCode: SharedCode.MultipleLibraryDirectives,
  problemMessage: """Only one library directive may be declared in a file.""",
  correctionMessage: """Try removing all but one of the library directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleOnClauses = const MessageCode(
  "MultipleOnClauses",
  sharedCode: SharedCode.MultipleOnClauses,
  problemMessage: """Each mixin definition can have at most one on clause.""",
  correctionMessage:
      """Try combining all of the on clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleVarianceModifiers = const MessageCode(
  "MultipleVarianceModifiers",
  sharedCode: SharedCode.MultipleVarianceModifiers,
  problemMessage:
      """Each type parameter can have at most one variance modifier.""",
  correctionMessage:
      """Use at most one of the 'in', 'out', or 'inout' modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleWith = const MessageCode(
  "MultipleWith",
  sharedCode: SharedCode.MultipleWith,
  problemMessage: """Each class definition can have at most one with clause.""",
  correctionMessage:
      """Try combining all of the with clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNamedFunctionExpression = const MessageCode(
  "NamedFunctionExpression",
  pseudoSharedCode: PseudoSharedCode.namedFunctionExpression,
  problemMessage: """A function expression can't have a name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNativeClauseShouldBeAnnotation = const MessageCode(
  "NativeClauseShouldBeAnnotation",
  sharedCode: SharedCode.NativeClauseShouldBeAnnotation,
  problemMessage: """Native clause in this form is deprecated.""",
  correctionMessage:
      """Try removing this native clause and adding @native() or @native('native-name') before the declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String character, int unicode),
  Message Function({required String character, required int unicode})
>
codeNonAsciiIdentifier = const Template(
  "NonAsciiIdentifier",
  withArgumentsOld: _withArgumentsOldNonAsciiIdentifier,
  withArguments: _withArgumentsNonAsciiIdentifier,
  pseudoSharedCode: PseudoSharedCode.illegalCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier({
  required String character,
  required int unicode,
}) {
  var character_0 = conversions.validateCharacter(character);
  var unicode_0 = conversions.codePointToUnicode(unicode);
  return new Message(
    codeNonAsciiIdentifier,
    problemMessage:
        """The non-ASCII character '${character_0}' (${unicode_0}) can't be used in identifiers, only in strings and comments.""",
    correctionMessage:
        """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
    arguments: {'character': character, 'unicode': unicode},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonAsciiIdentifier(String character, int unicode) =>
    _withArgumentsNonAsciiIdentifier(character: character, unicode: unicode);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int unicode),
  Message Function({required int unicode})
>
codeNonAsciiWhitespace = const Template(
  "NonAsciiWhitespace",
  withArgumentsOld: _withArgumentsOldNonAsciiWhitespace,
  withArguments: _withArgumentsNonAsciiWhitespace,
  pseudoSharedCode: PseudoSharedCode.illegalCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace({required int unicode}) {
  var unicode_0 = conversions.codePointToUnicode(unicode);
  return new Message(
    codeNonAsciiWhitespace,
    problemMessage:
        """The non-ASCII space character ${unicode_0} can only be used in strings and comments.""",
    arguments: {'unicode': unicode},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldNonAsciiWhitespace(int unicode) =>
    _withArgumentsNonAsciiWhitespace(unicode: unicode);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNonPartOfDirectiveInPart = const MessageCode(
  "NonPartOfDirectiveInPart",
  pseudoSharedCode: PseudoSharedCode.nonPartOfDirectiveInPart,
  problemMessage:
      """The part-of directive must be the only directive in a part.""",
  correctionMessage:
      """Try removing the other directives, or moving them to the library for which this is a part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNullAwareCascadeOutOfOrder = const MessageCode(
  "NullAwareCascadeOutOfOrder",
  sharedCode: SharedCode.NullAwareCascadeOutOfOrder,
  problemMessage:
      """The '?..' cascade operator must be first in the cascade sequence.""",
  correctionMessage:
      """Try moving the '?..' operator to be the first cascade operator in the sequence.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeOnlyTry = const MessageCode(
  "OnlyTry",
  sharedCode: SharedCode.OnlyTry,
  problemMessage:
      """A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
  correctionMessage:
      """Try adding either a catch or finally clause, or remove the try statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeOperatorWithTypeParameters = const MessageCode(
  "OperatorWithTypeParameters",
  sharedCode: SharedCode.OperatorWithTypeParameters,
  problemMessage:
      """Types parameters aren't allowed when defining an operator.""",
  correctionMessage: """Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeOutOfOrderClauses = const Template(
  "OutOfOrderClauses",
  withArgumentsOld: _withArgumentsOldOutOfOrderClauses,
  withArguments: _withArgumentsOutOfOrderClauses,
  sharedCode: SharedCode.OutOfOrderClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOutOfOrderClauses({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeOutOfOrderClauses,
    problemMessage:
        """The '${string_0}' clause must come before the '${string2_0}' clause.""",
    correctionMessage:
        """Try moving the '${string_0}' clause before the '${string2_0}' clause.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldOutOfOrderClauses(String string, String string2) =>
    _withArgumentsOutOfOrderClauses(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePartOfTwice = const MessageCode(
  "PartOfTwice",
  sharedCode: SharedCode.PartOfTwice,
  problemMessage: """Only one part-of directive may be declared in a file.""",
  correctionMessage: """Try removing all but one of the part-of directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codePatternAssignmentDeclaresVariable = const Template(
  "PatternAssignmentDeclaresVariable",
  withArgumentsOld: _withArgumentsOldPatternAssignmentDeclaresVariable,
  withArguments: _withArgumentsPatternAssignmentDeclaresVariable,
  sharedCode: SharedCode.PatternAssignmentDeclaresVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternAssignmentDeclaresVariable({
  required String name,
}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codePatternAssignmentDeclaresVariable,
    problemMessage:
        """Variable '${name_0}' can't be declared in a pattern assignment.""",
    correctionMessage:
        """Try using a preexisting variable or changing the assignment to a pattern variable declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldPatternAssignmentDeclaresVariable(String name) =>
    _withArgumentsPatternAssignmentDeclaresVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codePatternVariableDeclarationOutsideFunctionOrMethod = const MessageCode(
  "PatternVariableDeclarationOutsideFunctionOrMethod",
  sharedCode: SharedCode.PatternVariableDeclarationOutsideFunctionOrMethod,
  problemMessage:
      """A pattern variable declaration may not appear outside a function or method.""",
  correctionMessage:
      """Try declaring ordinary variables and assigning from within a function or method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePositionalAfterNamedArgument = const MessageCode(
  "PositionalAfterNamedArgument",
  pseudoSharedCode: PseudoSharedCode.positionalAfterNamedArgument,
  problemMessage: """Place positional arguments before named arguments.""",
  correctionMessage:
      """Try moving the positional argument before the named arguments, or add a name to the argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePositionalParameterWithEquals = const MessageCode(
  "PositionalParameterWithEquals",
  pseudoSharedCode: PseudoSharedCode.wrongSeparatorForPositionalParameter,
  problemMessage:
      """Positional optional parameters can't use ':' to specify a default value.""",
  correctionMessage: """Try replacing ':' with '='.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePrefixAfterCombinator = const MessageCode(
  "PrefixAfterCombinator",
  sharedCode: SharedCode.PrefixAfterCombinator,
  problemMessage:
      """The prefix ('as' clause) should come before any show/hide combinators.""",
  correctionMessage: """Try moving the prefix before the combinators.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePrivateNamedParameter = const MessageCode(
  "PrivateNamedParameter",
  pseudoSharedCode: PseudoSharedCode.privateOptionalParameter,
  problemMessage: """A named parameter can't start with an underscore ('_').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeRecordLiteralOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordLiteralOnePositionalFieldNoTrailingComma",
  sharedCode: SharedCode.RecordLiteralOnePositionalFieldNoTrailingComma,
  problemMessage:
      """A record literal with exactly one positional field requires a trailing comma.""",
  correctionMessage: """Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordLiteralZeroFieldsWithTrailingComma =
    const MessageCode(
      "RecordLiteralZeroFieldsWithTrailingComma",
      sharedCode: SharedCode.RecordLiteralZeroFieldsWithTrailingComma,
      problemMessage:
          """A record literal without fields can't have a trailing comma.""",
      correctionMessage: """Try removing the trailing comma.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeRecordTypeOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordTypeOnePositionalFieldNoTrailingComma",
  sharedCode: SharedCode.RecordTypeOnePositionalFieldNoTrailingComma,
  problemMessage:
      """A record type with exactly one positional field requires a trailing comma.""",
  correctionMessage: """Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordTypeZeroFieldsButTrailingComma = const MessageCode(
  "RecordTypeZeroFieldsButTrailingComma",
  sharedCode: SharedCode.RecordTypeZeroFieldsButTrailingComma,
  problemMessage:
      """A record type without fields can't have a trailing comma.""",
  correctionMessage: """Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectingConstructorWithBody = const MessageCode(
  "RedirectingConstructorWithBody",
  sharedCode: SharedCode.RedirectingConstructorWithBody,
  problemMessage: """Redirecting constructors can't have a body.""",
  correctionMessage:
      """Try removing the body, or not making this a redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectionInNonFactory = const MessageCode(
  "RedirectionInNonFactory",
  sharedCode: SharedCode.RedirectionInNonFactory,
  problemMessage: """Only factory constructor can specify '=' redirection.""",
  correctionMessage:
      """Try making this a factory constructor, or remove the redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRequiredParameterWithDefault = const MessageCode(
  "RequiredParameterWithDefault",
  pseudoSharedCode: PseudoSharedCode.namedParameterOutsideGroup,
  problemMessage: """Non-optional parameters can't have a default value.""",
  correctionMessage:
      """Try removing the default value or making the parameter optional.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedEnum = const MessageCode(
  "SealedEnum",
  sharedCode: SharedCode.SealedEnum,
  problemMessage: """Enums can't be declared to be 'sealed'.""",
  correctionMessage: """Try removing the keyword 'sealed'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedMixin = const MessageCode(
  "SealedMixin",
  sharedCode: SharedCode.SealedMixin,
  problemMessage: """A mixin can't be declared 'sealed'.""",
  correctionMessage: """Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedMixinClass = const MessageCode(
  "SealedMixinClass",
  sharedCode: SharedCode.SealedMixinClass,
  problemMessage: """A mixin class can't be declared 'sealed'.""",
  correctionMessage: """Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetOrMapLiteralTooManyTypeArguments = const MessageCode(
  "SetOrMapLiteralTooManyTypeArguments",
  pseudoSharedCode: PseudoSharedCode.setOrMapLiteralTooManyTypeArguments,
  problemMessage:
      """A set or map literal requires exactly one or two type arguments, respectively.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetterConstructor = const MessageCode(
  "SetterConstructor",
  sharedCode: SharedCode.SetterConstructor,
  problemMessage: """Constructors can't be a setter.""",
  correctionMessage: """Try removing 'set'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetterNotSync = const MessageCode(
  "SetterNotSync",
  pseudoSharedCode: PseudoSharedCode.invalidModifierOnSetter,
  problemMessage: """Setters can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStackOverflow = const MessageCode(
  "StackOverflow",
  sharedCode: SharedCode.StackOverflow,
  problemMessage: """The file has too many nested expressions or statements.""",
  correctionMessage: """Try simplifying the code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStaticConstructor = const MessageCode(
  "StaticConstructor",
  sharedCode: SharedCode.StaticConstructor,
  problemMessage: """Constructors can't be static.""",
  correctionMessage: """Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStaticOperator = const MessageCode(
  "StaticOperator",
  sharedCode: SharedCode.StaticOperator,
  problemMessage: """Operators can't be static.""",
  correctionMessage: """Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSuperNullAware = const MessageCode(
  "SuperNullAware",
  sharedCode: SharedCode.SuperNullAware,
  problemMessage:
      """The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
  correctionMessage: """Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchHasCaseAfterDefault = const MessageCode(
  "SwitchHasCaseAfterDefault",
  sharedCode: SharedCode.SwitchHasCaseAfterDefault,
  problemMessage:
      """The default case should be the last case in a switch statement.""",
  correctionMessage:
      """Try moving the default case after the other case clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchHasMultipleDefaults = const MessageCode(
  "SwitchHasMultipleDefaults",
  sharedCode: SharedCode.SwitchHasMultipleDefaults,
  problemMessage: """The 'default' case can only be declared once.""",
  correctionMessage: """Try removing all but one default case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTopLevelOperator = const MessageCode(
  "TopLevelOperator",
  sharedCode: SharedCode.TopLevelOperator,
  problemMessage: """Operators must be declared within a class.""",
  correctionMessage:
      """Try removing the operator, moving it to a class, or converting it to be a function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeAfterVar = const MessageCode(
  "TypeAfterVar",
  sharedCode: SharedCode.TypeAfterVar,
  problemMessage:
      """Variables can't be declared using both 'var' and a type name.""",
  correctionMessage: """Try removing 'var.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeTypeArgumentsOnTypeVariable = const Template(
  "TypeArgumentsOnTypeVariable",
  withArgumentsOld: _withArgumentsOldTypeArgumentsOnTypeVariable,
  withArguments: _withArgumentsTypeArgumentsOnTypeVariable,
  sharedCode: SharedCode.TypeArgumentsOnTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    codeTypeArgumentsOnTypeVariable,
    problemMessage:
        """Can't use type arguments with type variable '${name_0}'.""",
    correctionMessage: """Try removing the type arguments.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldTypeArgumentsOnTypeVariable(String name) =>
    _withArgumentsTypeArgumentsOnTypeVariable(name: name);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeBeforeFactory = const MessageCode(
  "TypeBeforeFactory",
  sharedCode: SharedCode.TypeBeforeFactory,
  problemMessage: """Factory constructors cannot have a return type.""",
  correctionMessage: """Try removing the type appearing before 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefInClass = const MessageCode(
  "TypedefInClass",
  sharedCode: SharedCode.TypedefInClass,
  problemMessage: """Typedefs can't be declared inside classes.""",
  correctionMessage: """Try moving the typedef to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnexpectedDollarInString = const MessageCode(
  "UnexpectedDollarInString",
  pseudoSharedCode: PseudoSharedCode.unexpectedDollarInString,
  problemMessage:
      """A '\$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
  correctionMessage: """Try adding a backslash (\\) to escape the '\$'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnexpectedSeparatorInNumber = const MessageCode(
  "UnexpectedSeparatorInNumber",
  pseudoSharedCode: PseudoSharedCode.unexpectedSeparatorInNumber,
  problemMessage:
      """Digit separators ('_') in a number literal can only be placed between two digits.""",
  correctionMessage: """Try removing the '_'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeUnexpectedToken = const Template(
  "UnexpectedToken",
  withArgumentsOld: _withArgumentsOldUnexpectedToken,
  withArguments: _withArgumentsUnexpectedToken,
  pseudoSharedCode: PseudoSharedCode.unexpectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeUnexpectedToken,
    problemMessage: """Unexpected token '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnexpectedToken(Token lexeme) =>
    _withArgumentsUnexpectedToken(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnexpectedTokens = const MessageCode(
  "UnexpectedTokens",
  sharedCode: SharedCode.UnexpectedTokens,
  problemMessage: """Unexpected tokens.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Token lexeme),
  Message Function({required String string, required Token lexeme})
>
codeUnmatchedToken = const Template(
  "UnmatchedToken",
  withArgumentsOld: _withArgumentsOldUnmatchedToken,
  withArguments: _withArgumentsUnmatchedToken,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken({
  required String string,
  required Token lexeme,
}) {
  var string_0 = conversions.validateString(string);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeUnmatchedToken,
    problemMessage: """Can't find '${string_0}' to match '${lexeme_0}'.""",
    arguments: {'string': string, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnmatchedToken(String string, Token lexeme) =>
    _withArgumentsUnmatchedToken(string: string, lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeUnspecified = const Template(
  "Unspecified",
  withArgumentsOld: _withArgumentsOldUnspecified,
  withArguments: _withArgumentsUnspecified,
  pseudoSharedCode: PseudoSharedCode.unspecified,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified({required String string}) {
  var string_0 = conversions.validateString(string);
  return new Message(
    codeUnspecified,
    problemMessage: """${string_0}""",
    arguments: {'string': string},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnspecified(String string) =>
    _withArgumentsUnspecified(string: string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeUnsupportedOperator = const Template(
  "UnsupportedOperator",
  withArgumentsOld: _withArgumentsOldUnsupportedOperator,
  withArguments: _withArgumentsUnsupportedOperator,
  pseudoSharedCode: PseudoSharedCode.unsupportedOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedOperator({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    codeUnsupportedOperator,
    problemMessage: """The '${lexeme_0}' operator is not supported.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnsupportedOperator(Token lexeme) =>
    _withArgumentsUnsupportedOperator(lexeme: lexeme);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnsupportedPrefixPlus = const MessageCode(
  "UnsupportedPrefixPlus",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """'+' is not a prefix operator.""",
  correctionMessage: """Try removing '+'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnterminatedComment = const MessageCode(
  "UnterminatedComment",
  pseudoSharedCode: PseudoSharedCode.unterminatedMultiLineComment,
  problemMessage: """Comment starting with '/*' must end with '*/'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeUnterminatedString = const Template(
  "UnterminatedString",
  withArgumentsOld: _withArgumentsOldUnterminatedString,
  withArguments: _withArgumentsUnterminatedString,
  pseudoSharedCode: PseudoSharedCode.unterminatedStringLiteral,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString({
  required String string,
  required String string2,
}) {
  var string_0 = conversions.validateString(string);
  var string2_0 = conversions.validateString(string2);
  return new Message(
    codeUnterminatedString,
    problemMessage:
        """String starting with ${string_0} must end with ${string2_0}.""",
    arguments: {'string': string, 'string2': string2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOldUnterminatedString(String string, String string2) =>
    _withArgumentsUnterminatedString(string: string, string2: string2);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVarAsTypeName = const MessageCode(
  "VarAsTypeName",
  sharedCode: SharedCode.VarAsTypeName,
  problemMessage: """The keyword 'var' can't be used as a type name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVarReturnType = const MessageCode(
  "VarReturnType",
  sharedCode: SharedCode.VarReturnType,
  problemMessage: """The return type can't be 'var'.""",
  correctionMessage:
      """Try removing the keyword 'var', or replacing it with the name of the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeVariablePatternKeywordInDeclarationContext = const MessageCode(
  "VariablePatternKeywordInDeclarationContext",
  sharedCode: SharedCode.VariablePatternKeywordInDeclarationContext,
  problemMessage:
      """Variable patterns in declaration context can't specify 'var' or 'final' keyword.""",
  correctionMessage: """Try removing the keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVoidWithTypeArguments = const MessageCode(
  "VoidWithTypeArguments",
  sharedCode: SharedCode.VoidWithTypeArguments,
  problemMessage: """Type 'void' can't have type arguments.""",
  correctionMessage: """Try removing the type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWithBeforeExtends = const MessageCode(
  "WithBeforeExtends",
  sharedCode: SharedCode.WithBeforeExtends,
  problemMessage: """The extends clause must be before the with clause.""",
  correctionMessage:
      """Try moving the extends clause before the with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeYieldAsIdentifier = const MessageCode(
  "YieldAsIdentifier",
  pseudoSharedCode: PseudoSharedCode.asyncKeywordUsedAsIdentifier,
  problemMessage:
      """'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeYieldNotGenerator = const MessageCode(
  "YieldNotGenerator",
  pseudoSharedCode: PseudoSharedCode.yieldInNonGenerator,
  problemMessage:
      """'yield' can only be used in 'sync*' or 'async*' methods.""",
);

/// Enum containing analyzer error codes referenced by [Code.pseudoSharedCode].
enum PseudoSharedCode {
  abstractExtensionField,
  assertAsExpression,
  asyncForInWrongContext,
  asyncKeywordUsedAsIdentifier,
  awaitInWrongContext,
  builtInIdentifierAsType,
  builtInIdentifierInDeclaration,
  constConstructorWithBody,
  constNotInitialized,
  defaultValueInFunctionType,
  encoding,
  expectedClassMember,
  expectedExecutable,
  expectedStringLiteral,
  expectedToken,
  expectedTypeName,
  extensionDeclaresInstanceField,
  extensionTypeDeclaresInstanceField,
  extensionTypeWithAbstractMember,
  fastaCliArgumentRequired,
  finalNotInitialized,
  getterWithParameters,
  illegalCharacter,
  internalProblemStackNotEmpty,
  internalProblemUnhandled,
  internalProblemUnsupported,
  invalidCodePoint,
  invalidInlineFunctionType,
  invalidLiteralInConfiguration,
  invalidModifierOnSetter,
  missingDigit,
  missingEnumBody,
  missingFunctionBody,
  missingFunctionParameters,
  missingHexDigit,
  missingIdentifier,
  missingMethodParameters,
  missingStarAfterSync,
  missingTypedefParameters,
  multipleImplementsClauses,
  namedFunctionExpression,
  namedParameterOutsideGroup,
  nonPartOfDirectiveInPart,
  nonSyncAbstractMethod,
  nonSyncFactory,
  positionalAfterNamedArgument,
  privateOptionalParameter,
  returnInGenerator,
  setOrMapLiteralTooManyTypeArguments,
  unexpectedDollarInString,
  unexpectedSeparatorInNumber,
  unexpectedToken,
  unspecified,
  unsupportedOperator,
  unterminatedMultiLineComment,
  unterminatedStringLiteral,
  wrongSeparatorForPositionalParameter,
  yieldInNonGenerator,
}

/// Enum containing analyzer error codes referenced by [Code.sharedCode].
enum SharedCode {
  AbstractClassMember,
  AbstractExternalField,
  AbstractFinalBaseClass,
  AbstractFinalInterfaceClass,
  AbstractLateField,
  AbstractSealedClass,
  AbstractStaticField,
  AnnotationOnTypeArgument,
  MetadataSpaceBeforeParenthesis,
  MetadataTypeArguments,
  MetadataTypeArgumentsUninstantiated,
  BaseEnum,
  BinaryOperatorWrittenOut,
  BreakOutsideOfLoop,
  CatchSyntax,
  CatchSyntaxExtraParameters,
  ClassInClass,
  ColonInPlaceOfIn,
  ConflictingModifiers,
  ConstructorWithReturnType,
  ConstructorWithTypeArguments,
  ConstAndFinal,
  ConstClass,
  ConstFactory,
  ConstMethod,
  ContinueOutsideOfLoop,
  ContinueWithoutLabelInCase,
  CovariantAndStatic,
  CovariantMember,
  DefaultInSwitchExpression,
  DeferredAfterPrefix,
  DirectiveAfterDeclaration,
  DuplicatedModifier,
  DuplicateDeferred,
  DuplicateLabelInSwitchStatement,
  DuplicatePrefix,
  RecordLiteralZeroFieldsWithTrailingComma,
  EmptyRecordTypeNamedFieldsList,
  RecordTypeZeroFieldsButTrailingComma,
  EnumInClass,
  EqualityCannotBeEqualityOperand,
  ExpectedCatchClauseBody,
  ExpectedClassBody,
  ExpectedElseOrComma,
  ExpectedExtensionBody,
  ExpectedExtensionTypeBody,
  ExpectedFinallyClauseBody,
  ExpectedIdentifierButGotKeyword,
  ExpectedInstead,
  ExpectedMixinBody,
  ExpectedSwitchExpressionBody,
  ExpectedSwitchStatementBody,
  ExpectedTryStatementBody,
  ExperimentNotEnabled,
  ExperimentNotEnabledOffByDefault,
  ExportAfterPart,
  ExtensionAugmentationHasOnClause,
  ExtensionDeclaresAbstractMember,
  ExtensionDeclaresConstructor,
  ExtensionTypeExtends,
  ExtensionTypeWith,
  ExternalClass,
  ExternalConstructorWithFieldInitializers,
  ExternalConstructorWithInitializer,
  ExternalEnum,
  ExternalFactoryRedirection,
  ExternalFactoryWithBody,
  ExternalLateField,
  ExternalMethodWithBody,
  ExternalTypedef,
  ExtraneousModifier,
  ExtraneousModifierInExtensionType,
  ExtraneousModifierInPrimaryConstructor,
  FactoryTopLevelDeclaration,
  FieldInitializedOutsideDeclaringClass,
  FieldInitializerOutsideConstructor,
  FinalAndCovariant,
  FinalAndCovariantLateWithInitializer,
  FinalAndVar,
  FinalEnum,
  FinalMixin,
  FinalMixinClass,
  FunctionTypedParameterVar,
  GetterConstructor,
  IllegalAssignmentToNonAssignable,
  IllegalPatternAssignmentVariableName,
  IllegalPatternIdentifierName,
  IllegalPatternVariableName,
  ImplementsBeforeExtends,
  ImplementsBeforeOn,
  ImplementsBeforeWith,
  ImportAfterPart,
  InitializedVariableInForEach,
  InterfaceEnum,
  InterfaceMixin,
  InterfaceMixinClass,
  InvalidAwaitFor,
  InvalidConstantPatternConstPrefix,
  InvalidConstantPatternBinary,
  InvalidConstantPatternDuplicateConst,
  InvalidConstantPatternEmptyRecordLiteral,
  InvalidConstantPatternGeneric,
  InvalidConstantPatternNegation,
  InvalidConstantPatternUnary,
  ConstructorWithWrongName,
  InvalidHexEscape,
  InvalidInitializer,
  InvalidInsideUnaryPattern,
  InvalidOperator,
  SuperNullAware,
  InvalidSuperInInitializer,
  InvalidThisInInitializer,
  InvalidEscapeStarted,
  InvalidUnicodeEscapeUBracket,
  InvalidUnicodeEscapeUNoBracket,
  InvalidUnicodeEscapeUStarted,
  ExtraneousModifierInExtension,
  LatePatternVariableDeclaration,
  LibraryDirectiveNotFirst,
  LiteralWithClass,
  LiteralWithClassAndNew,
  LiteralWithNew,
  MemberWithSameNameAsClass,
  MissingAssignableSelector,
  MissingAssignmentInInitializer,
  OnlyTry,
  MissingConstFinalVarOrType,
  MissingExpressionInThrow,
  ExpectedAnInitializer,
  MissingOperatorKeyword,
  MissingPrefixInDeferredImport,
  MissingPrimaryConstructor,
  MissingPrimaryConstructorParameters,
  ExpectedStatement,
  MixinDeclaresConstructor,
  MixinWithClause,
  ModifierOutOfOrder,
  MultipleClauses,
  MultipleExtends,
  MultipleLibraryDirectives,
  MultipleOnClauses,
  PartOfTwice,
  MultipleVarianceModifiers,
  MultipleWith,
  NativeClauseShouldBeAnnotation,
  NullAwareCascadeOutOfOrder,
  OutOfOrderClauses,
  PatternAssignmentDeclaresVariable,
  PatternVariableDeclarationOutsideFunctionOrMethod,
  PrefixAfterCombinator,
  RecordLiteralOnePositionalFieldNoTrailingComma,
  RecordTypeOnePositionalFieldNoTrailingComma,
  RedirectingConstructorWithBody,
  RedirectionInNonFactory,
  SealedEnum,
  SealedMixin,
  SealedMixinClass,
  SetterConstructor,
  StackOverflow,
  StaticConstructor,
  StaticOperator,
  SwitchHasCaseAfterDefault,
  SwitchHasMultipleDefaults,
  TopLevelOperator,
  TypedefInClass,
  TypeArgumentsOnTypeVariable,
  TypeBeforeFactory,
  ConstructorWithTypeParameters,
  OperatorWithTypeParameters,
  UnexpectedTokens,
  VariablePatternKeywordInDeclarationContext,
  TypeAfterVar,
  VarAsTypeName,
  VarReturnType,
  VoidWithTypeArguments,
  WithBeforeExtends,
}
