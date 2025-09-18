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
  index: 51,
  problemMessage: r"""Members of classes can't be declared to be 'abstract'.""",
  correctionMessage:
      r"""Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractExtensionField = const MessageCode(
  "AbstractExtensionField",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.abstractExtensionField],
  problemMessage: r"""Extension fields can't be declared 'abstract'.""",
  correctionMessage: r"""Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractExternalField = const MessageCode(
  "AbstractExternalField",
  index: 110,
  problemMessage:
      r"""Fields can't be declared both 'abstract' and 'external'.""",
  correctionMessage: r"""Try removing the 'abstract' or 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFinalBaseClass = const MessageCode(
  "AbstractFinalBaseClass",
  index: 176,
  problemMessage:
      r"""An 'abstract' class can't be declared as both 'final' and 'base'.""",
  correctionMessage: r"""Try removing either the 'final' or 'base' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractFinalInterfaceClass = const MessageCode(
  "AbstractFinalInterfaceClass",
  index: 50,
  problemMessage:
      r"""An 'abstract' class can't be declared as both 'final' and 'interface'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractLateField = const MessageCode(
  "AbstractLateField",
  index: 108,
  problemMessage: r"""Abstract fields cannot be late.""",
  correctionMessage: r"""Try removing the 'abstract' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractNotSync = const MessageCode(
  "AbstractNotSync",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.nonSyncAbstractMethod],
  problemMessage:
      r"""Abstract methods can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractSealedClass = const MessageCode(
  "AbstractSealedClass",
  index: 132,
  problemMessage:
      r"""A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.""",
  correctionMessage: r"""Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAbstractStaticField = const MessageCode(
  "AbstractStaticField",
  index: 107,
  problemMessage: r"""Static fields can't be declared 'abstract'.""",
  correctionMessage: r"""Try removing the 'abstract' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAnnotationOnTypeArgument = const MessageCode(
  "AnnotationOnTypeArgument",
  index: 111,
  problemMessage:
      r"""Type arguments can't have annotations because they aren't declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(int character),
  Message Function({required int character})
>
codeAsciiControlCharacter = const Template(
  "AsciiControlCharacter",
  problemMessageTemplate:
      r"""The control character #character can only be used in strings and comments.""",
  withArgumentsOld: _withArgumentsOldAsciiControlCharacter,
  withArguments: _withArgumentsAsciiControlCharacter,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.illegalCharacter],
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
  problemMessage: r"""`assert` can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitAsIdentifier = const MessageCode(
  "AwaitAsIdentifier",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.asyncKeywordUsedAsIdentifier],
  problemMessage:
      r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitForNotAsync = const MessageCode(
  "AwaitForNotAsync",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.asyncForInWrongContext],
  problemMessage:
      r"""The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
  correctionMessage:
      r"""Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeAwaitNotAsync = const MessageCode(
  "AwaitNotAsync",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.awaitInWrongContext],
  problemMessage:
      r"""'await' can only be used in 'async' or 'async*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeBaseEnum = const MessageCode(
  "BaseEnum",
  index: 155,
  problemMessage: r"""Enums can't be declared to be 'base'.""",
  correctionMessage: r"""Try removing the keyword 'base'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeBinaryOperatorWrittenOut = const Template(
  "BinaryOperatorWrittenOut",
  problemMessageTemplate:
      r"""Binary operator '#string' is written as '#string2' instead of the written out word.""",
  correctionMessageTemplate: r"""Try replacing '#string' with '#string2'.""",
  withArgumentsOld: _withArgumentsOldBinaryOperatorWrittenOut,
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
  index: 112,
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
  index: 52,
  problemMessage:
      r"""A break statement can't be used outside of a loop or switch statement.""",
  correctionMessage: r"""Try removing the break statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeBuiltInIdentifierAsType = const Template(
  "BuiltInIdentifierAsType",
  problemMessageTemplate:
      r"""The built-in identifier '#lexeme' can't be used as a type.""",
  withArgumentsOld: _withArgumentsOldBuiltInIdentifierAsType,
  withArguments: _withArgumentsBuiltInIdentifierAsType,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.builtInIdentifierAsType],
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
  problemMessageTemplate: r"""Can't use '#lexeme' as a name here.""",
  withArgumentsOld: _withArgumentsOldBuiltInIdentifierInDeclaration,
  withArguments: _withArgumentsBuiltInIdentifierInDeclaration,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.builtInIdentifierInDeclaration],
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
  index: 84,
  problemMessage:
      r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCatchSyntaxExtraParameters = const MessageCode(
  "CatchSyntaxExtraParameters",
  index: 83,
  problemMessage:
      r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeClassInClass = const MessageCode(
  "ClassInClass",
  index: 53,
  problemMessage: r"""Classes can't be declared inside other classes.""",
  correctionMessage: r"""Try moving the class to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeColonInPlaceOfIn = const MessageCode(
  "ColonInPlaceOfIn",
  index: 54,
  problemMessage: r"""For-in loops use 'in' rather than a colon.""",
  correctionMessage: r"""Try replacing the colon with the keyword 'in'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeConflictingModifiers = const Template(
  "ConflictingModifiers",
  problemMessageTemplate:
      r"""Members can't be declared to be both '#string' and '#string2'.""",
  correctionMessageTemplate: r"""Try removing one of the keywords.""",
  withArgumentsOld: _withArgumentsOldConflictingModifiers,
  withArguments: _withArgumentsConflictingModifiers,
  index: 59,
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
  index: 58,
  problemMessage:
      r"""Members can't be declared to be both 'const' and 'final'.""",
  correctionMessage: r"""Try removing either the 'const' or 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstClass = const MessageCode(
  "ConstClass",
  index: 60,
  problemMessage: r"""Classes can't be declared to be 'const'.""",
  correctionMessage:
      r"""Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstConstructorWithBody = const MessageCode(
  "ConstConstructorWithBody",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.constConstructorWithBody],
  problemMessage: r"""A const constructor can't have a body.""",
  correctionMessage:
      r"""Try removing either the 'const' keyword or the body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstFactory = const MessageCode(
  "ConstFactory",
  index: 62,
  problemMessage:
      r"""Only redirecting factory constructors can be declared to be 'const'.""",
  correctionMessage:
      r"""Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeConstFieldWithoutInitializer = const Template(
  "ConstFieldWithoutInitializer",
  problemMessageTemplate:
      r"""The const variable '#name' must be initialized.""",
  correctionMessageTemplate:
      r"""Try adding an initializer ('= expression') to the declaration.""",
  withArgumentsOld: _withArgumentsOldConstFieldWithoutInitializer,
  withArguments: _withArgumentsConstFieldWithoutInitializer,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.constNotInitialized],
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
  index: 63,
  problemMessage:
      r"""Getters, setters and methods can't be declared to be 'const'.""",
  correctionMessage: r"""Try removing the 'const' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithReturnType = const MessageCode(
  "ConstructorWithReturnType",
  index: 55,
  problemMessage: r"""Constructors can't have a return type.""",
  correctionMessage: r"""Try removing the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithTypeArguments = const MessageCode(
  "ConstructorWithTypeArguments",
  index: 118,
  problemMessage:
      r"""A constructor invocation can't have type arguments after the constructor name.""",
  correctionMessage:
      r"""Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithTypeParameters = const MessageCode(
  "ConstructorWithTypeParameters",
  index: 99,
  problemMessage: r"""Constructors can't have type parameters.""",
  correctionMessage: r"""Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeConstructorWithWrongName = const MessageCode(
  "ConstructorWithWrongName",
  index: 102,
  problemMessage:
      r"""The name of a constructor must match the name of the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeContinueOutsideOfLoop = const MessageCode(
  "ContinueOutsideOfLoop",
  index: 2,
  problemMessage:
      r"""A continue statement can't be used outside of a loop or switch statement.""",
  correctionMessage: r"""Try removing the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeContinueWithoutLabelInCase = const MessageCode(
  "ContinueWithoutLabelInCase",
  index: 64,
  problemMessage:
      r"""A continue statement in a switch statement must have a label as a target.""",
  correctionMessage:
      r"""Try adding a label associated with one of the case clauses to the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCovariantAndStatic = const MessageCode(
  "CovariantAndStatic",
  index: 66,
  problemMessage:
      r"""Members can't be declared to be both 'covariant' and 'static'.""",
  correctionMessage:
      r"""Try removing either the 'covariant' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeCovariantMember = const MessageCode(
  "CovariantMember",
  index: 67,
  problemMessage:
      r"""Getters, setters and methods can't be declared to be 'covariant'.""",
  correctionMessage: r"""Try removing the 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDefaultInSwitchExpression = const MessageCode(
  "DefaultInSwitchExpression",
  index: 153,
  problemMessage: r"""A switch expression may not use the `default` keyword.""",
  correctionMessage: r"""Try replacing `default` with `_`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDeferredAfterPrefix = const MessageCode(
  "DeferredAfterPrefix",
  index: 68,
  problemMessage:
      r"""The deferred keyword should come immediately before the prefix ('as' clause).""",
  correctionMessage: r"""Try moving the deferred keyword before the prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDirectiveAfterDeclaration = const MessageCode(
  "DirectiveAfterDeclaration",
  index: 69,
  problemMessage: r"""Directives must appear before any declarations.""",
  correctionMessage: r"""Try moving the directive before any declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeDuplicateDeferred = const MessageCode(
  "DuplicateDeferred",
  index: 71,
  problemMessage:
      r"""An import directive can only have one 'deferred' keyword.""",
  correctionMessage: r"""Try removing all but one 'deferred' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeDuplicateLabelInSwitchStatement = const Template(
  "DuplicateLabelInSwitchStatement",
  problemMessageTemplate:
      r"""The label '#name' was already used in this switch statement.""",
  correctionMessageTemplate:
      r"""Try choosing a different name for this label.""",
  withArgumentsOld: _withArgumentsOldDuplicateLabelInSwitchStatement,
  withArguments: _withArgumentsDuplicateLabelInSwitchStatement,
  index: 72,
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
  index: 73,
  problemMessage:
      r"""An import directive can only have one prefix ('as' clause).""",
  correctionMessage: r"""Try removing all but one prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeDuplicatedModifier = const Template(
  "DuplicatedModifier",
  problemMessageTemplate: r"""The modifier '#lexeme' was already specified.""",
  correctionMessageTemplate:
      r"""Try removing all but one occurrence of the modifier.""",
  withArgumentsOld: _withArgumentsOldDuplicatedModifier,
  withArguments: _withArgumentsDuplicatedModifier,
  index: 70,
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingIdentifier],
  problemMessage: r"""Named parameter lists cannot be empty.""",
  correctionMessage: r"""Try adding a named parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyOptionalParameterList = const MessageCode(
  "EmptyOptionalParameterList",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingIdentifier],
  problemMessage: r"""Optional parameter lists cannot be empty.""",
  correctionMessage: r"""Try adding an optional parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEmptyRecordTypeNamedFieldsList = const MessageCode(
  "EmptyRecordTypeNamedFieldsList",
  index: 129,
  problemMessage:
      r"""The list of named fields in a record type can't be empty.""",
  correctionMessage: r"""Try adding a named field to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEncoding = const MessageCode(
  "Encoding",
  problemMessage: r"""Unable to decode bytes as UTF-8.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEnumInClass = const MessageCode(
  "EnumInClass",
  index: 74,
  problemMessage: r"""Enums can't be declared inside classes.""",
  correctionMessage: r"""Try moving the enum to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeEqualityCannotBeEqualityOperand = const MessageCode(
  "EqualityCannotBeEqualityOperand",
  index: 1,
  problemMessage:
      r"""A comparison expression can't be an operand of another comparison expression.""",
  correctionMessage:
      r"""Try putting parentheses around one of the comparisons.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedAfterButGot = const Template(
  "ExpectedAfterButGot",
  problemMessageTemplate: r"""Expected '#string' after this.""",
  withArgumentsOld: _withArgumentsOldExpectedAfterButGot,
  withArguments: _withArgumentsExpectedAfterButGot,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedToken],
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
  index: 36,
  problemMessage: r"""Expected an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedBody = const MessageCode(
  "ExpectedBody",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingFunctionBody],
  problemMessage: r"""Expected a function body or '=>'.""",
  correctionMessage: r"""Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedButGot = const Template(
  "ExpectedButGot",
  problemMessageTemplate: r"""Expected '#string' before this.""",
  withArgumentsOld: _withArgumentsOldExpectedButGot,
  withArguments: _withArgumentsExpectedButGot,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedToken],
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
  index: 169,
  problemMessage: r"""A catch clause must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedClassBody = const MessageCode(
  "ExpectedClassBody",
  index: 8,
  problemMessage:
      r"""A class declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedClassMember = const Template(
  "ExpectedClassMember",
  problemMessageTemplate: r"""Expected a class member, but got '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedClassMember,
  withArguments: _withArgumentsExpectedClassMember,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedClassMember],
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
  problemMessageTemplate: r"""Expected a declaration, but got '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedDeclaration,
  withArguments: _withArgumentsExpectedDeclaration,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedExecutable],
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
  index: 46,
  problemMessage: r"""Expected 'else' or comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedEnumBody = const Template(
  "ExpectedEnumBody",
  problemMessageTemplate: r"""Expected a enum body, but got '#lexeme'.""",
  correctionMessageTemplate:
      r"""An enum definition must have a body with at least one constant name.""",
  withArgumentsOld: _withArgumentsOldExpectedEnumBody,
  withArguments: _withArgumentsExpectedEnumBody,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingEnumBody],
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
  index: 173,
  problemMessage:
      r"""An extension declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedExtensionTypeBody = const MessageCode(
  "ExpectedExtensionTypeBody",
  index: 167,
  problemMessage:
      r"""An extension type declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedFinallyClauseBody = const MessageCode(
  "ExpectedFinallyClauseBody",
  index: 170,
  problemMessage:
      r"""A finally clause must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedFunctionBody = const Template(
  "ExpectedFunctionBody",
  problemMessageTemplate: r"""Expected a function body, but got '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedFunctionBody,
  withArguments: _withArgumentsExpectedFunctionBody,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingFunctionBody],
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingHexDigit],
  problemMessage: r"""A hex digit (0-9 or A-F) must follow '0x'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedIdentifier = const Template(
  "ExpectedIdentifier",
  problemMessageTemplate: r"""Expected an identifier, but got '#lexeme'.""",
  correctionMessageTemplate:
      r"""Try inserting an identifier before '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedIdentifier,
  withArguments: _withArgumentsExpectedIdentifier,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingIdentifier],
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
  problemMessageTemplate:
      r"""'#lexeme' can't be used as an identifier because it's a keyword.""",
  correctionMessageTemplate:
      r"""Try renaming this to be an identifier that isn't a keyword.""",
  withArgumentsOld: _withArgumentsOldExpectedIdentifierButGotKeyword,
  withArguments: _withArgumentsExpectedIdentifierButGotKeyword,
  index: 113,
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
  problemMessageTemplate: r"""Expected '#string' instead of this.""",
  withArgumentsOld: _withArgumentsOldExpectedInstead,
  withArguments: _withArgumentsExpectedInstead,
  index: 41,
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
  index: 166,
  problemMessage:
      r"""A mixin declaration must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedStatement = const MessageCode(
  "ExpectedStatement",
  index: 29,
  problemMessage: r"""Expected a statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedString = const Template(
  "ExpectedString",
  problemMessageTemplate: r"""Expected a String, but got '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedString,
  withArguments: _withArgumentsExpectedString,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedStringLiteral],
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
  index: 171,
  problemMessage:
      r"""A switch expression must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExpectedSwitchStatementBody = const MessageCode(
  "ExpectedSwitchStatementBody",
  index: 172,
  problemMessage:
      r"""A switch statement must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string),
  Message Function({required String string})
>
codeExpectedToken = const Template(
  "ExpectedToken",
  problemMessageTemplate: r"""Expected to find '#string'.""",
  withArgumentsOld: _withArgumentsOldExpectedToken,
  withArguments: _withArgumentsExpectedToken,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedToken],
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
  index: 168,
  problemMessage: r"""A try statement must have a body, even if it is empty.""",
  correctionMessage: r"""Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExpectedType = const Template(
  "ExpectedType",
  problemMessageTemplate: r"""Expected a type, but got '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExpectedType,
  withArguments: _withArgumentsExpectedType,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedTypeName],
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
  problemMessageTemplate:
      r"""This requires the '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""Try updating your pubspec.yaml to set the minimum SDK constraint to #string2 or higher, and running 'pub get'.""",
  withArgumentsOld: _withArgumentsOldExperimentNotEnabled,
  withArguments: _withArgumentsExperimentNotEnabled,
  index: 48,
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
  problemMessageTemplate:
      r"""This requires the experimental '#string' language feature to be enabled.""",
  correctionMessageTemplate:
      r"""Try passing the '--enable-experiment=#string' command line option.""",
  withArgumentsOld: _withArgumentsOldExperimentNotEnabledOffByDefault,
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
  index: 133,
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
  index: 75,
  problemMessage: r"""Export directives must precede part directives.""",
  correctionMessage:
      r"""Try moving the export directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionAugmentationHasOnClause = const MessageCode(
  "ExtensionAugmentationHasOnClause",
  index: 93,
  problemMessage: r"""Extension augmentations can't have 'on' clauses.""",
  correctionMessage: r"""Try removing the 'on' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresAbstractMember = const MessageCode(
  "ExtensionDeclaresAbstractMember",
  index: 94,
  problemMessage: r"""Extensions can't declare abstract members.""",
  correctionMessage: r"""Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresConstructor = const MessageCode(
  "ExtensionDeclaresConstructor",
  index: 92,
  problemMessage: r"""Extensions can't declare constructors.""",
  correctionMessage: r"""Try removing the constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionDeclaresInstanceField = const MessageCode(
  "ExtensionDeclaresInstanceField",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.extensionDeclaresInstanceField],
  problemMessage: r"""Extensions can't declare instance fields""",
  correctionMessage:
      r"""Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeDeclaresAbstractMember = const MessageCode(
  "ExtensionTypeDeclaresAbstractMember",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.extensionTypeWithAbstractMember],
  problemMessage: r"""Extension types can't declare abstract members.""",
  correctionMessage: r"""Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeDeclaresInstanceField = const MessageCode(
  "ExtensionTypeDeclaresInstanceField",
  analyzerCodes: <AnalyzerCode>[
    AnalyzerCode.extensionTypeDeclaresInstanceField,
  ],
  problemMessage: r"""Extension types can't declare instance fields""",
  correctionMessage:
      r"""Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeExtends = const MessageCode(
  "ExtensionTypeExtends",
  index: 164,
  problemMessage:
      r"""An extension type declaration can't have an 'extends' clause.""",
  correctionMessage:
      r"""Try removing the 'extends' clause or replacing the 'extends' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExtensionTypeWith = const MessageCode(
  "ExtensionTypeWith",
  index: 165,
  problemMessage:
      r"""An extension type declaration can't have a 'with' clause.""",
  correctionMessage:
      r"""Try removing the 'with' clause or replacing the 'with' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalClass = const MessageCode(
  "ExternalClass",
  index: 3,
  problemMessage: r"""Classes can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeExternalConstructorWithFieldInitializers = const MessageCode(
  "ExternalConstructorWithFieldInitializers",
  index: 87,
  problemMessage: r"""An external constructor can't initialize fields.""",
  correctionMessage:
      r"""Try removing the field initializers, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalConstructorWithInitializer = const MessageCode(
  "ExternalConstructorWithInitializer",
  index: 106,
  problemMessage: r"""An external constructor can't have any initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalEnum = const MessageCode(
  "ExternalEnum",
  index: 5,
  problemMessage: r"""Enums can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalFactoryRedirection = const MessageCode(
  "ExternalFactoryRedirection",
  index: 85,
  problemMessage: r"""A redirecting factory can't be external.""",
  correctionMessage: r"""Try removing the 'external' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalFactoryWithBody = const MessageCode(
  "ExternalFactoryWithBody",
  index: 86,
  problemMessage: r"""External factories can't have a body.""",
  correctionMessage:
      r"""Try removing the body of the factory, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalLateField = const MessageCode(
  "ExternalLateField",
  index: 109,
  problemMessage: r"""External fields cannot be late.""",
  correctionMessage: r"""Try removing the 'external' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalMethodWithBody = const MessageCode(
  "ExternalMethodWithBody",
  index: 49,
  problemMessage: r"""An external or native method can't have a body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeExternalTypedef = const MessageCode(
  "ExternalTypedef",
  index: 76,
  problemMessage: r"""Typedefs can't be declared to be 'external'.""",
  correctionMessage: r"""Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeExtraneousModifier = const Template(
  "ExtraneousModifier",
  problemMessageTemplate: r"""Can't have modifier '#lexeme' here.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExtraneousModifier,
  withArguments: _withArgumentsExtraneousModifier,
  index: 77,
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
  problemMessageTemplate: r"""Can't have modifier '#lexeme' in an extension.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInExtension,
  withArguments: _withArgumentsExtraneousModifierInExtension,
  index: 98,
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
  problemMessageTemplate:
      r"""Can't have modifier '#lexeme' in an extension type.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInExtensionType,
  withArguments: _withArgumentsExtraneousModifierInExtensionType,
  index: 174,
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
  problemMessageTemplate:
      r"""Can't have modifier '#lexeme' in a primary constructor.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldExtraneousModifierInPrimaryConstructor,
  withArguments: _withArgumentsExtraneousModifierInPrimaryConstructor,
  index: 175,
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.nonSyncFactory],
  problemMessage:
      r"""Factory bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFactoryTopLevelDeclaration = const MessageCode(
  "FactoryTopLevelDeclaration",
  index: 78,
  problemMessage:
      r"""Top-level declarations can't be declared to be 'factory'.""",
  correctionMessage: r"""Try removing the keyword 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFastaCLIArgumentRequired = const Template(
  "FastaCLIArgumentRequired",
  problemMessageTemplate: r"""Expected value after '#name'.""",
  withArgumentsOld: _withArgumentsOldFastaCLIArgumentRequired,
  withArguments: _withArgumentsFastaCLIArgumentRequired,
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
  index: 88,
  problemMessage: r"""A field can only be initialized in its declaring class""",
  correctionMessage:
      r"""Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFieldInitializerOutsideConstructor = const MessageCode(
  "FieldInitializerOutsideConstructor",
  index: 79,
  problemMessage:
      r"""Field formal parameters can only be used in a constructor.""",
  correctionMessage: r"""Try removing 'this.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndCovariant = const MessageCode(
  "FinalAndCovariant",
  index: 80,
  problemMessage:
      r"""Members can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndCovariantLateWithInitializer = const MessageCode(
  "FinalAndCovariantLateWithInitializer",
  index: 101,
  problemMessage:
      r"""Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      r"""Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalAndVar = const MessageCode(
  "FinalAndVar",
  index: 81,
  problemMessage:
      r"""Members can't be declared to be both 'final' and 'var'.""",
  correctionMessage: r"""Try removing the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalEnum = const MessageCode(
  "FinalEnum",
  index: 156,
  problemMessage: r"""Enums can't be declared to be 'final'.""",
  correctionMessage: r"""Try removing the keyword 'final'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeFinalFieldWithoutInitializer = const Template(
  "FinalFieldWithoutInitializer",
  problemMessageTemplate:
      r"""The final variable '#name' must be initialized.""",
  correctionMessageTemplate:
      r"""Try adding an initializer ('= expression') to the declaration.""",
  withArgumentsOld: _withArgumentsOldFinalFieldWithoutInitializer,
  withArguments: _withArgumentsFinalFieldWithoutInitializer,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.finalNotInitialized],
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
  index: 146,
  problemMessage: r"""A mixin can't be declared 'final'.""",
  correctionMessage: r"""Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFinalMixinClass = const MessageCode(
  "FinalMixinClass",
  index: 142,
  problemMessage: r"""A mixin class can't be declared 'final'.""",
  correctionMessage: r"""Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFunctionTypeDefaultValue = const MessageCode(
  "FunctionTypeDefaultValue",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.defaultValueInFunctionType],
  problemMessage: r"""Can't have a default value in a function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeFunctionTypedParameterVar = const MessageCode(
  "FunctionTypedParameterVar",
  index: 119,
  problemMessage:
      r"""Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
  correctionMessage: r"""Try replacing the keyword with a return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGeneratorReturnsValue = const MessageCode(
  "GeneratorReturnsValue",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.returnInGenerator],
  problemMessage: r"""'sync*' and 'async*' can't return a value.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGetterConstructor = const MessageCode(
  "GetterConstructor",
  index: 103,
  problemMessage: r"""Constructors can't be a getter.""",
  correctionMessage: r"""Try removing 'get'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeGetterWithFormals = const MessageCode(
  "GetterWithFormals",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.getterWithParameters],
  problemMessage: r"""A getter can't have formal parameters.""",
  correctionMessage: r"""Try removing '(...)'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeIllegalAssignmentToNonAssignable = const MessageCode(
  "IllegalAssignmentToNonAssignable",
  index: 45,
  problemMessage: r"""Illegal assignment to non-assignable expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeIllegalPatternAssignmentVariableName = const Template(
  "IllegalPatternAssignmentVariableName",
  problemMessageTemplate:
      r"""A variable assigned by a pattern assignment can't be named '#lexeme'.""",
  correctionMessageTemplate: r"""Choose a different name.""",
  withArgumentsOld: _withArgumentsOldIllegalPatternAssignmentVariableName,
  withArguments: _withArgumentsIllegalPatternAssignmentVariableName,
  index: 160,
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
  problemMessageTemplate:
      r"""A pattern can't refer to an identifier named '#lexeme'.""",
  correctionMessageTemplate: r"""Match the identifier using '==""",
  withArgumentsOld: _withArgumentsOldIllegalPatternIdentifierName,
  withArguments: _withArgumentsIllegalPatternIdentifierName,
  index: 161,
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
  problemMessageTemplate:
      r"""The variable declared by a variable pattern can't be named '#lexeme'.""",
  correctionMessageTemplate: r"""Choose a different name.""",
  withArgumentsOld: _withArgumentsOldIllegalPatternVariableName,
  withArguments: _withArgumentsIllegalPatternVariableName,
  index: 159,
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
  index: 44,
  problemMessage:
      r"""The extends clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the extends clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsBeforeOn = const MessageCode(
  "ImplementsBeforeOn",
  index: 43,
  problemMessage: r"""The on clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the on clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImplementsBeforeWith = const MessageCode(
  "ImplementsBeforeWith",
  index: 42,
  problemMessage: r"""The with clause must be before the implements clause.""",
  correctionMessage:
      r"""Try moving the with clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeImportAfterPart = const MessageCode(
  "ImportAfterPart",
  index: 10,
  problemMessage: r"""Import directives must precede part directives.""",
  correctionMessage:
      r"""Try moving the import directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInitializedVariableInForEach = const MessageCode(
  "InitializedVariableInForEach",
  index: 82,
  problemMessage:
      r"""The loop variable in a for-each loop can't be initialized.""",
  correctionMessage:
      r"""Try removing the initializer, or using a different kind of loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceEnum = const MessageCode(
  "InterfaceEnum",
  index: 157,
  problemMessage: r"""Enums can't be declared to be 'interface'.""",
  correctionMessage: r"""Try removing the keyword 'interface'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceMixin = const MessageCode(
  "InterfaceMixin",
  index: 147,
  problemMessage: r"""A mixin can't be declared 'interface'.""",
  correctionMessage: r"""Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInterfaceMixinClass = const MessageCode(
  "InterfaceMixinClass",
  index: 143,
  problemMessage: r"""A mixin class can't be declared 'interface'.""",
  correctionMessage: r"""Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name, String string),
  Message Function({required String name, required String string})
>
codeInternalProblemStackNotEmpty = const Template(
  "InternalProblemStackNotEmpty",
  problemMessageTemplate: r"""#name.stack isn't empty:
  #string""",
  withArgumentsOld: _withArgumentsOldInternalProblemStackNotEmpty,
  withArguments: _withArgumentsInternalProblemStackNotEmpty,
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
  problemMessageTemplate: r"""Unhandled #string in #string2.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUnhandled,
  withArguments: _withArgumentsInternalProblemUnhandled,
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
  problemMessageTemplate: r"""Unsupported operation: '#name'.""",
  withArgumentsOld: _withArgumentsOldInternalProblemUnsupported,
  withArguments: _withArgumentsInternalProblemUnsupported,
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.invalidLiteralInConfiguration],
  problemMessage: r"""Can't use string interpolation in a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidAwaitFor = const MessageCode(
  "InvalidAwaitFor",
  index: 9,
  problemMessage:
      r"""The keyword 'await' isn't allowed for a normal 'for' statement.""",
  correctionMessage:
      r"""Try removing the keyword, or use a for-each statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidCodePoint = const MessageCode(
  "InvalidCodePoint",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.invalidCodePoint],
  problemMessage:
      r"""The escape sequence starting with '\u' isn't a valid code point.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidConstantPatternBinary = const Template(
  "InvalidConstantPatternBinary",
  problemMessageTemplate:
      r"""The binary operator #name is not supported as a constant pattern.""",
  correctionMessageTemplate:
      r"""Try wrapping the expression in 'const ( ... )'.""",
  withArgumentsOld: _withArgumentsOldInvalidConstantPatternBinary,
  withArguments: _withArgumentsInvalidConstantPatternBinary,
  index: 141,
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
  index: 140,
  problemMessage:
      r"""The expression can't be prefixed by 'const' to form a constant pattern.""",
  correctionMessage:
      r"""Try wrapping the expression in 'const ( ... )' instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternDuplicateConst = const MessageCode(
  "InvalidConstantPatternDuplicateConst",
  index: 137,
  problemMessage: r"""Duplicate 'const' keyword in constant expression.""",
  correctionMessage: r"""Try removing one of the 'const' keywords.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeInvalidConstantPatternEmptyRecordLiteral = const MessageCode(
  "InvalidConstantPatternEmptyRecordLiteral",
  index: 138,
  problemMessage:
      r"""The empty record literal is not supported as a constant pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternGeneric = const MessageCode(
  "InvalidConstantPatternGeneric",
  index: 139,
  problemMessage:
      r"""This expression is not supported as a constant pattern.""",
  correctionMessage: r"""Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidConstantPatternNegation = const MessageCode(
  "InvalidConstantPatternNegation",
  index: 135,
  problemMessage:
      r"""Only negation of a numeric literal is supported as a constant pattern.""",
  correctionMessage: r"""Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeInvalidConstantPatternUnary = const Template(
  "InvalidConstantPatternUnary",
  problemMessageTemplate:
      r"""The unary operator #name is not supported as a constant pattern.""",
  correctionMessageTemplate:
      r"""Try wrapping the expression in 'const ( ... )'.""",
  withArgumentsOld: _withArgumentsOldInvalidConstantPatternUnary,
  withArguments: _withArgumentsInvalidConstantPatternUnary,
  index: 136,
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
  index: 126,
  problemMessage: r"""The string '\' can't stand alone.""",
  correctionMessage: r"""Try adding another backslash (\) to escape the '\'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidHexEscape = const MessageCode(
  "InvalidHexEscape",
  index: 40,
  problemMessage:
      r"""An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInitializer = const MessageCode(
  "InvalidInitializer",
  index: 90,
  problemMessage: r"""Not a valid initializer.""",
  correctionMessage:
      r"""To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInlineFunctionType = const MessageCode(
  "InvalidInlineFunctionType",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.invalidInlineFunctionType],
  problemMessage:
      r"""Inline function types cannot be used for parameters in a generic function type.""",
  correctionMessage:
      r"""Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidInsideUnaryPattern = const MessageCode(
  "InvalidInsideUnaryPattern",
  index: 150,
  problemMessage:
      r"""This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.""",
  correctionMessage:
      r"""Try combining into a single pattern if possible, or enclose the inner pattern in parentheses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeInvalidOperator = const Template(
  "InvalidOperator",
  problemMessageTemplate:
      r"""The string '#lexeme' isn't a user-definable operator.""",
  withArgumentsOld: _withArgumentsOldInvalidOperator,
  withArguments: _withArgumentsInvalidOperator,
  index: 39,
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
  index: 47,
  problemMessage:
      r"""Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidSyncModifier = const MessageCode(
  "InvalidSyncModifier",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingStarAfterSync],
  problemMessage: r"""Invalid modifier 'sync'.""",
  correctionMessage: r"""Try replacing 'sync' with 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidThisInInitializer = const MessageCode(
  "InvalidThisInInitializer",
  index: 65,
  problemMessage:
      r"""Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUBracket = const MessageCode(
  "InvalidUnicodeEscapeUBracket",
  index: 125,
  problemMessage:
      r"""An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUNoBracket = const MessageCode(
  "InvalidUnicodeEscapeUNoBracket",
  index: 124,
  problemMessage:
      r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidUnicodeEscapeUStarted = const MessageCode(
  "InvalidUnicodeEscapeUStarted",
  index: 38,
  problemMessage:
      r"""An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeInvalidVoid = const MessageCode(
  "InvalidVoid",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedTypeName],
  problemMessage: r"""Type 'void' can't be used here.""",
  correctionMessage:
      r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLatePatternVariableDeclaration = const MessageCode(
  "LatePatternVariableDeclaration",
  index: 151,
  problemMessage:
      r"""A pattern variable declaration may not use the `late` keyword.""",
  correctionMessage: r"""Try removing the keyword `late`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeLibraryDirectiveNotFirst = const MessageCode(
  "LibraryDirectiveNotFirst",
  index: 37,
  problemMessage:
      r"""The library directive must appear before all other directives.""",
  correctionMessage:
      r"""Try moving the library directive before any other directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Token lexeme),
  Message Function({required String string, required Token lexeme})
>
codeLiteralWithClass = const Template(
  "LiteralWithClass",
  problemMessageTemplate:
      r"""A #string literal can't be prefixed by '#lexeme'.""",
  correctionMessageTemplate: r"""Try removing '#lexeme'""",
  withArgumentsOld: _withArgumentsOldLiteralWithClass,
  withArguments: _withArgumentsLiteralWithClass,
  index: 116,
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
  problemMessageTemplate:
      r"""A #string literal can't be prefixed by 'new #lexeme'.""",
  correctionMessageTemplate: r"""Try removing 'new' and '#lexeme'""",
  withArgumentsOld: _withArgumentsOldLiteralWithClassAndNew,
  withArguments: _withArgumentsLiteralWithClassAndNew,
  index: 115,
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
  index: 117,
  problemMessage: r"""A literal can't be prefixed by 'new'.""",
  correctionMessage: r"""Try removing 'new'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMemberWithSameNameAsClass = const MessageCode(
  "MemberWithSameNameAsClass",
  index: 105,
  problemMessage:
      r"""A class member can't have the same name as the enclosing class.""",
  correctionMessage: r"""Try renaming the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataSpaceBeforeParenthesis = const MessageCode(
  "MetadataSpaceBeforeParenthesis",
  index: 134,
  problemMessage:
      r"""Annotations can't have spaces or comments before the parenthesis.""",
  correctionMessage:
      r"""Remove any spaces or comments before the parenthesis.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataTypeArguments = const MessageCode(
  "MetadataTypeArguments",
  index: 91,
  problemMessage: r"""An annotation can't use type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMetadataTypeArgumentsUninstantiated = const MessageCode(
  "MetadataTypeArgumentsUninstantiated",
  index: 114,
  problemMessage:
      r"""An annotation with type arguments must be followed by an argument list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingAssignableSelector = const MessageCode(
  "MissingAssignableSelector",
  index: 35,
  problemMessage: r"""Missing selector such as '.identifier' or '[0]'.""",
  correctionMessage: r"""Try adding a selector.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingAssignmentInInitializer = const MessageCode(
  "MissingAssignmentInInitializer",
  index: 34,
  problemMessage: r"""Expected an assignment after the field name.""",
  correctionMessage:
      r"""To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingConstFinalVarOrType = const MessageCode(
  "MissingConstFinalVarOrType",
  index: 33,
  problemMessage:
      r"""Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
  correctionMessage:
      r"""Try adding the name of the type of the variable or the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingExponent = const MessageCode(
  "MissingExponent",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingDigit],
  problemMessage:
      r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
  correctionMessage:
      r"""Make sure there is an exponent, and remove any whitespace before it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingExpressionInThrow = const MessageCode(
  "MissingExpressionInThrow",
  index: 32,
  problemMessage: r"""Missing expression after 'throw'.""",
  correctionMessage:
      r"""Add an expression after 'throw' or use 'rethrow' to throw a caught exception""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingFunctionParameters = const MessageCode(
  "MissingFunctionParameters",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingFunctionParameters],
  problemMessage:
      r"""A function declaration needs an explicit list of parameters.""",
  correctionMessage:
      r"""Try adding a parameter list to the function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingMethodParameters = const MessageCode(
  "MissingMethodParameters",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingMethodParameters],
  problemMessage:
      r"""A method declaration needs an explicit list of parameters.""",
  correctionMessage:
      r"""Try adding a parameter list to the method declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingOperatorKeyword = const MessageCode(
  "MissingOperatorKeyword",
  index: 31,
  problemMessage:
      r"""Operator declarations must be preceded by the keyword 'operator'.""",
  correctionMessage: r"""Try adding the keyword 'operator'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrefixInDeferredImport = const MessageCode(
  "MissingPrefixInDeferredImport",
  index: 30,
  problemMessage: r"""Deferred imports should have a prefix.""",
  correctionMessage:
      r"""Try adding a prefix to the import by adding an 'as' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrimaryConstructor = const MessageCode(
  "MissingPrimaryConstructor",
  index: 162,
  problemMessage:
      r"""An extension type declaration must have a primary constructor declaration.""",
  correctionMessage:
      r"""Try adding a primary constructor to the extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingPrimaryConstructorParameters = const MessageCode(
  "MissingPrimaryConstructorParameters",
  index: 163,
  problemMessage:
      r"""A primary constructor declaration must have formal parameters.""",
  correctionMessage:
      r"""Try adding formal parameters after the primary constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMissingTypedefParameters = const MessageCode(
  "MissingTypedefParameters",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingTypedefParameters],
  problemMessage: r"""A typedef needs an explicit list of parameters.""",
  correctionMessage: r"""Try adding a parameter list to the typedef.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinDeclaresConstructor = const MessageCode(
  "MixinDeclaresConstructor",
  index: 95,
  problemMessage: r"""Mixins can't declare constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMixinWithClause = const MessageCode(
  "MixinWithClause",
  index: 154,
  problemMessage: r"""A mixin can't have a with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeModifierOutOfOrder = const Template(
  "ModifierOutOfOrder",
  problemMessageTemplate:
      r"""The modifier '#string' should be before the modifier '#string2'.""",
  correctionMessageTemplate: r"""Try re-ordering the modifiers.""",
  withArgumentsOld: _withArgumentsOldModifierOutOfOrder,
  withArguments: _withArgumentsModifierOutOfOrder,
  index: 56,
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
  problemMessageTemplate:
      r"""Each '#string' definition can have at most one '#string2' clause.""",
  correctionMessageTemplate:
      r"""Try combining all of the '#string2' clauses into a single clause.""",
  withArgumentsOld: _withArgumentsOldMultipleClauses,
  withArguments: _withArgumentsMultipleClauses,
  index: 121,
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
  index: 28,
  problemMessage:
      r"""Each class definition can have at most one extends clause.""",
  correctionMessage:
      r"""Try choosing one superclass and define your class to implement (or mix in) the others.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleImplements = const MessageCode(
  "MultipleImplements",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.multipleImplementsClauses],
  problemMessage:
      r"""Each class definition can have at most one implements clause.""",
  correctionMessage:
      r"""Try combining all of the implements clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleLibraryDirectives = const MessageCode(
  "MultipleLibraryDirectives",
  index: 27,
  problemMessage: r"""Only one library directive may be declared in a file.""",
  correctionMessage: r"""Try removing all but one of the library directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleOnClauses = const MessageCode(
  "MultipleOnClauses",
  index: 26,
  problemMessage: r"""Each mixin definition can have at most one on clause.""",
  correctionMessage:
      r"""Try combining all of the on clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleVarianceModifiers = const MessageCode(
  "MultipleVarianceModifiers",
  index: 97,
  problemMessage:
      r"""Each type parameter can have at most one variance modifier.""",
  correctionMessage:
      r"""Use at most one of the 'in', 'out', or 'inout' modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeMultipleWith = const MessageCode(
  "MultipleWith",
  index: 24,
  problemMessage:
      r"""Each class definition can have at most one with clause.""",
  correctionMessage:
      r"""Try combining all of the with clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNamedFunctionExpression = const MessageCode(
  "NamedFunctionExpression",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.namedFunctionExpression],
  problemMessage: r"""A function expression can't have a name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNativeClauseShouldBeAnnotation = const MessageCode(
  "NativeClauseShouldBeAnnotation",
  index: 23,
  problemMessage: r"""Native clause in this form is deprecated.""",
  correctionMessage:
      r"""Try removing this native clause and adding @native() or @native('native-name') before the declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String character, int unicode),
  Message Function({required String character, required int unicode})
>
codeNonAsciiIdentifier = const Template(
  "NonAsciiIdentifier",
  problemMessageTemplate:
      r"""The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.""",
  correctionMessageTemplate:
      r"""Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).""",
  withArgumentsOld: _withArgumentsOldNonAsciiIdentifier,
  withArguments: _withArgumentsNonAsciiIdentifier,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.illegalCharacter],
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
  problemMessageTemplate:
      r"""The non-ASCII space character #unicode can only be used in strings and comments.""",
  withArgumentsOld: _withArgumentsOldNonAsciiWhitespace,
  withArguments: _withArgumentsNonAsciiWhitespace,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.illegalCharacter],
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.nonPartOfDirectiveInPart],
  problemMessage:
      r"""The part-of directive must be the only directive in a part.""",
  correctionMessage:
      r"""Try removing the other directives, or moving them to the library for which this is a part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeNullAwareCascadeOutOfOrder = const MessageCode(
  "NullAwareCascadeOutOfOrder",
  index: 96,
  problemMessage:
      r"""The '?..' cascade operator must be first in the cascade sequence.""",
  correctionMessage:
      r"""Try moving the '?..' operator to be the first cascade operator in the sequence.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeOnlyTry = const MessageCode(
  "OnlyTry",
  index: 20,
  problemMessage:
      r"""A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
  correctionMessage:
      r"""Try adding either a catch or finally clause, or remove the try statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeOperatorWithTypeParameters = const MessageCode(
  "OperatorWithTypeParameters",
  index: 120,
  problemMessage:
      r"""Types parameters aren't allowed when defining an operator.""",
  correctionMessage: r"""Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeOutOfOrderClauses = const Template(
  "OutOfOrderClauses",
  problemMessageTemplate:
      r"""The '#string' clause must come before the '#string2' clause.""",
  correctionMessageTemplate:
      r"""Try moving the '#string' clause before the '#string2' clause.""",
  withArgumentsOld: _withArgumentsOldOutOfOrderClauses,
  withArguments: _withArgumentsOutOfOrderClauses,
  index: 122,
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
  index: 25,
  problemMessage: r"""Only one part-of directive may be declared in a file.""",
  correctionMessage: r"""Try removing all but one of the part-of directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codePatternAssignmentDeclaresVariable = const Template(
  "PatternAssignmentDeclaresVariable",
  problemMessageTemplate:
      r"""Variable '#name' can't be declared in a pattern assignment.""",
  correctionMessageTemplate:
      r"""Try using a preexisting variable or changing the assignment to a pattern variable declaration.""",
  withArgumentsOld: _withArgumentsOldPatternAssignmentDeclaresVariable,
  withArguments: _withArgumentsPatternAssignmentDeclaresVariable,
  index: 145,
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
  index: 152,
  problemMessage:
      r"""A pattern variable declaration may not appear outside a function or method.""",
  correctionMessage:
      r"""Try declaring ordinary variables and assigning from within a function or method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePositionalAfterNamedArgument = const MessageCode(
  "PositionalAfterNamedArgument",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.positionalAfterNamedArgument],
  problemMessage: r"""Place positional arguments before named arguments.""",
  correctionMessage:
      r"""Try moving the positional argument before the named arguments, or add a name to the argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePositionalParameterWithEquals = const MessageCode(
  "PositionalParameterWithEquals",
  analyzerCodes: <AnalyzerCode>[
    AnalyzerCode.wrongSeparatorForPositionalParameter,
  ],
  problemMessage:
      r"""Positional optional parameters can't use ':' to specify a default value.""",
  correctionMessage: r"""Try replacing ':' with '='.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePrefixAfterCombinator = const MessageCode(
  "PrefixAfterCombinator",
  index: 6,
  problemMessage:
      r"""The prefix ('as' clause) should come before any show/hide combinators.""",
  correctionMessage: r"""Try moving the prefix before the combinators.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codePrivateNamedParameter = const MessageCode(
  "PrivateNamedParameter",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.privateOptionalParameter],
  problemMessage:
      r"""A named parameter can't start with an underscore ('_').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeRecordLiteralOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordLiteralOnePositionalFieldNoTrailingComma",
  index: 127,
  problemMessage:
      r"""A record literal with exactly one positional field requires a trailing comma.""",
  correctionMessage: r"""Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordLiteralZeroFieldsWithTrailingComma =
    const MessageCode(
      "RecordLiteralZeroFieldsWithTrailingComma",
      index: 128,
      problemMessage:
          r"""A record literal without fields can't have a trailing comma.""",
      correctionMessage: r"""Try removing the trailing comma.""",
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeRecordTypeOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordTypeOnePositionalFieldNoTrailingComma",
  index: 131,
  problemMessage:
      r"""A record type with exactly one positional field requires a trailing comma.""",
  correctionMessage: r"""Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRecordTypeZeroFieldsButTrailingComma = const MessageCode(
  "RecordTypeZeroFieldsButTrailingComma",
  index: 130,
  problemMessage:
      r"""A record type without fields can't have a trailing comma.""",
  correctionMessage: r"""Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectingConstructorWithBody = const MessageCode(
  "RedirectingConstructorWithBody",
  index: 22,
  problemMessage: r"""Redirecting constructors can't have a body.""",
  correctionMessage:
      r"""Try removing the body, or not making this a redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRedirectionInNonFactory = const MessageCode(
  "RedirectionInNonFactory",
  index: 21,
  problemMessage: r"""Only factory constructor can specify '=' redirection.""",
  correctionMessage:
      r"""Try making this a factory constructor, or remove the redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeRequiredParameterWithDefault = const MessageCode(
  "RequiredParameterWithDefault",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.namedParameterOutsideGroup],
  problemMessage: r"""Non-optional parameters can't have a default value.""",
  correctionMessage:
      r"""Try removing the default value or making the parameter optional.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedEnum = const MessageCode(
  "SealedEnum",
  index: 158,
  problemMessage: r"""Enums can't be declared to be 'sealed'.""",
  correctionMessage: r"""Try removing the keyword 'sealed'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedMixin = const MessageCode(
  "SealedMixin",
  index: 148,
  problemMessage: r"""A mixin can't be declared 'sealed'.""",
  correctionMessage: r"""Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSealedMixinClass = const MessageCode(
  "SealedMixinClass",
  index: 144,
  problemMessage: r"""A mixin class can't be declared 'sealed'.""",
  correctionMessage: r"""Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetOrMapLiteralTooManyTypeArguments = const MessageCode(
  "SetOrMapLiteralTooManyTypeArguments",
  problemMessage:
      r"""A set or map literal requires exactly one or two type arguments, respectively.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetterConstructor = const MessageCode(
  "SetterConstructor",
  index: 104,
  problemMessage: r"""Constructors can't be a setter.""",
  correctionMessage: r"""Try removing 'set'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSetterNotSync = const MessageCode(
  "SetterNotSync",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.invalidModifierOnSetter],
  problemMessage: r"""Setters can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStackOverflow = const MessageCode(
  "StackOverflow",
  index: 19,
  problemMessage:
      r"""The file has too many nested expressions or statements.""",
  correctionMessage: r"""Try simplifying the code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStaticConstructor = const MessageCode(
  "StaticConstructor",
  index: 4,
  problemMessage: r"""Constructors can't be static.""",
  correctionMessage: r"""Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeStaticOperator = const MessageCode(
  "StaticOperator",
  index: 17,
  problemMessage: r"""Operators can't be static.""",
  correctionMessage: r"""Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSuperNullAware = const MessageCode(
  "SuperNullAware",
  index: 18,
  problemMessage:
      r"""The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
  correctionMessage: r"""Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchHasCaseAfterDefault = const MessageCode(
  "SwitchHasCaseAfterDefault",
  index: 16,
  problemMessage:
      r"""The default case should be the last case in a switch statement.""",
  correctionMessage:
      r"""Try moving the default case after the other case clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeSwitchHasMultipleDefaults = const MessageCode(
  "SwitchHasMultipleDefaults",
  index: 15,
  problemMessage: r"""The 'default' case can only be declared once.""",
  correctionMessage: r"""Try removing all but one default case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTopLevelOperator = const MessageCode(
  "TopLevelOperator",
  index: 14,
  problemMessage: r"""Operators must be declared within a class.""",
  correctionMessage:
      r"""Try removing the operator, moving it to a class, or converting it to be a function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypeAfterVar = const MessageCode(
  "TypeAfterVar",
  index: 89,
  problemMessage:
      r"""Variables can't be declared using both 'var' and a type name.""",
  correctionMessage: r"""Try removing 'var.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String name),
  Message Function({required String name})
>
codeTypeArgumentsOnTypeVariable = const Template(
  "TypeArgumentsOnTypeVariable",
  problemMessageTemplate:
      r"""Can't use type arguments with type variable '#name'.""",
  correctionMessageTemplate: r"""Try removing the type arguments.""",
  withArgumentsOld: _withArgumentsOldTypeArgumentsOnTypeVariable,
  withArguments: _withArgumentsTypeArgumentsOnTypeVariable,
  index: 13,
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
  index: 57,
  problemMessage: r"""Factory constructors cannot have a return type.""",
  correctionMessage: r"""Try removing the type appearing before 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeTypedefInClass = const MessageCode(
  "TypedefInClass",
  index: 7,
  problemMessage: r"""Typedefs can't be declared inside classes.""",
  correctionMessage: r"""Try moving the typedef to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnexpectedDollarInString = const MessageCode(
  "UnexpectedDollarInString",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unexpectedDollarInString],
  problemMessage:
      r"""A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
  correctionMessage: r"""Try adding a backslash (\) to escape the '$'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnexpectedSeparatorInNumber = const MessageCode(
  "UnexpectedSeparatorInNumber",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unexpectedSeparatorInNumber],
  problemMessage:
      r"""Digit separators ('_') in a number literal can only be placed between two digits.""",
  correctionMessage: r"""Try removing the '_'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(Token lexeme),
  Message Function({required Token lexeme})
>
codeUnexpectedToken = const Template(
  "UnexpectedToken",
  problemMessageTemplate: r"""Unexpected token '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldUnexpectedToken,
  withArguments: _withArgumentsUnexpectedToken,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unexpectedToken],
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
  index: 123,
  problemMessage: r"""Unexpected tokens.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, Token lexeme),
  Message Function({required String string, required Token lexeme})
>
codeUnmatchedToken = const Template(
  "UnmatchedToken",
  problemMessageTemplate: r"""Can't find '#string' to match '#lexeme'.""",
  withArgumentsOld: _withArgumentsOldUnmatchedToken,
  withArguments: _withArgumentsUnmatchedToken,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.expectedToken],
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
  problemMessageTemplate: r"""#string""",
  withArgumentsOld: _withArgumentsOldUnspecified,
  withArguments: _withArgumentsUnspecified,
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
  problemMessageTemplate: r"""The '#lexeme' operator is not supported.""",
  withArgumentsOld: _withArgumentsOldUnsupportedOperator,
  withArguments: _withArgumentsUnsupportedOperator,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unsupportedOperator],
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
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.missingIdentifier],
  problemMessage: r"""'+' is not a prefix operator.""",
  correctionMessage: r"""Try removing '+'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeUnterminatedComment = const MessageCode(
  "UnterminatedComment",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unterminatedMultiLineComment],
  problemMessage: r"""Comment starting with '/*' must end with '*/'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function(String string, String string2),
  Message Function({required String string, required String string2})
>
codeUnterminatedString = const Template(
  "UnterminatedString",
  problemMessageTemplate:
      r"""String starting with #string must end with #string2.""",
  withArgumentsOld: _withArgumentsOldUnterminatedString,
  withArguments: _withArgumentsUnterminatedString,
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.unterminatedStringLiteral],
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
  index: 61,
  problemMessage: r"""The keyword 'var' can't be used as a type name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVarReturnType = const MessageCode(
  "VarReturnType",
  index: 12,
  problemMessage: r"""The return type can't be 'var'.""",
  correctionMessage:
      r"""Try removing the keyword 'var', or replacing it with the name of the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
codeVariablePatternKeywordInDeclarationContext = const MessageCode(
  "VariablePatternKeywordInDeclarationContext",
  index: 149,
  problemMessage:
      r"""Variable patterns in declaration context can't specify 'var' or 'final' keyword.""",
  correctionMessage: r"""Try removing the keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeVoidWithTypeArguments = const MessageCode(
  "VoidWithTypeArguments",
  index: 100,
  problemMessage: r"""Type 'void' can't have type arguments.""",
  correctionMessage: r"""Try removing the type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeWithBeforeExtends = const MessageCode(
  "WithBeforeExtends",
  index: 11,
  problemMessage: r"""The extends clause must be before the with clause.""",
  correctionMessage:
      r"""Try moving the extends clause before the with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeYieldAsIdentifier = const MessageCode(
  "YieldAsIdentifier",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.asyncKeywordUsedAsIdentifier],
  problemMessage:
      r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode codeYieldNotGenerator = const MessageCode(
  "YieldNotGenerator",
  analyzerCodes: <AnalyzerCode>[AnalyzerCode.yieldInNonGenerator],
  problemMessage:
      r"""'yield' can only be used in 'sync*' or 'async*' methods.""",
);

/// Enum containing analyzer error codes referenced by [Code.analyzerCodes].
enum AnalyzerCode {
  abstractExtensionField,
  asyncForInWrongContext,
  asyncKeywordUsedAsIdentifier,
  awaitInWrongContext,
  builtInIdentifierAsType,
  builtInIdentifierInDeclaration,
  constConstructorWithBody,
  constNotInitialized,
  defaultValueInFunctionType,
  expectedClassMember,
  expectedExecutable,
  expectedStringLiteral,
  expectedToken,
  expectedTypeName,
  extensionDeclaresInstanceField,
  extensionTypeDeclaresInstanceField,
  extensionTypeWithAbstractMember,
  finalNotInitialized,
  getterWithParameters,
  illegalCharacter,
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
  unexpectedDollarInString,
  unexpectedSeparatorInNumber,
  unexpectedToken,
  unsupportedOperator,
  unterminatedMultiLineComment,
  unterminatedStringLiteral,
  wrongSeparatorForPositionalParameter,
  yieldInNonGenerator,
}
