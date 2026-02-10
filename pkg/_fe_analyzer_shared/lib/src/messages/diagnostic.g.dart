// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and defer to it for the
// commands to update this file.

// ignore_for_file: lines_longer_than_80_chars

part of 'diagnostic.dart';

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractClassMember = const MessageCode(
  "AbstractClassMember",
  sharedCode: SharedCode.abstractClassMember,
  problemMessage: """Members of classes can't be declared to be 'abstract'.""",
  correctionMessage:
      """Try removing the 'abstract' keyword. You can add the 'abstract' keyword before the class declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractExtensionField = const MessageCode(
  "AbstractExtensionField",
  pseudoSharedCode: PseudoSharedCode.abstractExtensionField,
  problemMessage: """Extension fields can't be declared 'abstract'.""",
  correctionMessage: """Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractExternalField = const MessageCode(
  "AbstractExternalField",
  sharedCode: SharedCode.abstractExternalField,
  problemMessage:
      """Fields can't be declared both 'abstract' and 'external'.""",
  correctionMessage: """Try removing the 'abstract' or 'external' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractFinalBaseClass = const MessageCode(
  "AbstractFinalBaseClass",
  sharedCode: SharedCode.abstractFinalBaseClass,
  problemMessage:
      """An 'abstract' class can't be declared as both 'final' and 'base'.""",
  correctionMessage: """Try removing either the 'final' or 'base' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractFinalInterfaceClass = const MessageCode(
  "AbstractFinalInterfaceClass",
  sharedCode: SharedCode.abstractFinalInterfaceClass,
  problemMessage:
      """An 'abstract' class can't be declared as both 'final' and 'interface'.""",
  correctionMessage:
      """Try removing either the 'final' or 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractLateField = const MessageCode(
  "AbstractLateField",
  sharedCode: SharedCode.abstractLateField,
  problemMessage: """Abstract fields cannot be late.""",
  correctionMessage: """Try removing the 'abstract' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractNotSync = const MessageCode(
  "AbstractNotSync",
  pseudoSharedCode: PseudoSharedCode.nonSyncAbstractMethod,
  problemMessage:
      """Abstract methods can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractSealedClass = const MessageCode(
  "AbstractSealedClass",
  sharedCode: SharedCode.abstractSealedClass,
  problemMessage:
      """A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.""",
  correctionMessage: """Try removing the 'abstract' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode abstractStaticField = const MessageCode(
  "AbstractStaticField",
  sharedCode: SharedCode.abstractStaticField,
  problemMessage: """Static fields can't be declared 'abstract'.""",
  correctionMessage: """Try removing the 'abstract' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode annotationOnTypeArgument = const MessageCode(
  "AnnotationOnTypeArgument",
  sharedCode: SharedCode.annotationOnTypeArgument,
  problemMessage:
      """Type arguments can't have annotations because they aren't declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode anonymousMethodWrongParameterList = const MessageCode(
  "AnonymousMethodWrongParameterList",
  sharedCode: SharedCode.anonymousMethodWrongParameterList,
  problemMessage:
      """An anonymous method with a parameter list must have exactly one required, positional parameter.""",
  correctionMessage:
      """Try removing the parameter list, or changing it to have exactly one required positional parameter.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required int character})>
asciiControlCharacter = const Template(
  "AsciiControlCharacter",
  withArguments: _withArgumentsAsciiControlCharacter,
  pseudoSharedCode: PseudoSharedCode.illegalCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter({required int character}) {
  var character_0 = conversions.codePointToUnicode(character);
  return new Message(
    asciiControlCharacter,
    problemMessage:
        """The control character ${character_0} can only be used in strings and comments.""",
    arguments: {'character': character},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode assertAsExpression = const MessageCode(
  "AssertAsExpression",
  pseudoSharedCode: PseudoSharedCode.assertAsExpression,
  problemMessage: """`assert` can't be used as an expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode awaitAsIdentifier = const MessageCode(
  "AwaitAsIdentifier",
  pseudoSharedCode: PseudoSharedCode.asyncKeywordUsedAsIdentifier,
  problemMessage:
      """'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode awaitForNotAsync = const MessageCode(
  "AwaitForNotAsync",
  pseudoSharedCode: PseudoSharedCode.asyncForInWrongContext,
  problemMessage:
      """The asynchronous for-in can only be used in functions marked with 'async' or 'async*'.""",
  correctionMessage:
      """Try marking the function body with either 'async' or 'async*', or removing the 'await' before the for loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode awaitNotAsync = const MessageCode(
  "AwaitNotAsync",
  pseudoSharedCode: PseudoSharedCode.awaitInWrongContext,
  problemMessage:
      """'await' can only be used in 'async' or 'async*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode baseEnum = const MessageCode(
  "BaseEnum",
  sharedCode: SharedCode.baseEnum,
  problemMessage: """Enums can't be declared to be 'base'.""",
  correctionMessage: """Try removing the keyword 'base'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String actualOperator,
    required String expectedOperator,
  })
>
binaryOperatorWrittenOut = const Template(
  "BinaryOperatorWrittenOut",
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
  sharedCode: SharedCode.binaryOperatorWrittenOut,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBinaryOperatorWrittenOut({
  required String actualOperator,
  required String expectedOperator,
}) {
  var actualOperator_0 = conversions.validateString(actualOperator);
  var expectedOperator_0 = conversions.validateString(expectedOperator);
  return new Message(
    binaryOperatorWrittenOut,
    problemMessage:
        """Binary operator '${actualOperator_0}' is written as '${expectedOperator_0}' instead of the written out word.""",
    correctionMessage:
        """Try replacing '${actualOperator_0}' with '${expectedOperator_0}'.""",
    arguments: {
      'actualOperator': actualOperator,
      'expectedOperator': expectedOperator,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode breakOutsideOfLoop = const MessageCode(
  "BreakOutsideOfLoop",
  sharedCode: SharedCode.breakOutsideOfLoop,
  problemMessage:
      """A break statement can't be used outside of a loop or switch statement.""",
  correctionMessage: """Try removing the break statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
builtInIdentifierAsType = const Template(
  "BuiltInIdentifierAsType",
  withArguments: _withArgumentsBuiltInIdentifierAsType,
  pseudoSharedCode: PseudoSharedCode.builtInIdentifierAsType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    builtInIdentifierAsType,
    problemMessage:
        """The built-in identifier '${lexeme_0}' can't be used as a type.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
builtInIdentifierInDeclaration = const Template(
  "BuiltInIdentifierInDeclaration",
  withArguments: _withArgumentsBuiltInIdentifierInDeclaration,
  pseudoSharedCode: PseudoSharedCode.builtInIdentifierInDeclaration,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    builtInIdentifierInDeclaration,
    problemMessage: """Can't use '${lexeme_0}' as a name here.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode catchSyntax = const MessageCode(
  "CatchSyntax",
  sharedCode: SharedCode.catchSyntax,
  problemMessage:
      """'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      """No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode catchSyntaxExtraParameters = const MessageCode(
  "CatchSyntaxExtraParameters",
  sharedCode: SharedCode.catchSyntaxExtraParameters,
  problemMessage:
      """'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
  correctionMessage:
      """No types are needed, the first is given by 'on', the second is always 'StackTrace'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode classInClass = const MessageCode(
  "ClassInClass",
  sharedCode: SharedCode.classInClass,
  problemMessage: """Classes can't be declared inside other classes.""",
  correctionMessage: """Try moving the class to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode colonInPlaceOfIn = const MessageCode(
  "ColonInPlaceOfIn",
  sharedCode: SharedCode.colonInPlaceOfIn,
  problemMessage: """For-in loops use 'in' rather than a colon.""",
  correctionMessage: """Try replacing the colon with the keyword 'in'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String modifier, required String earlierModifier})
>
conflictingModifiers = const Template(
  "ConflictingModifiers",
  withArguments: _withArgumentsConflictingModifiers,
  sharedCode: SharedCode.conflictingModifiers,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConflictingModifiers({
  required String modifier,
  required String earlierModifier,
}) {
  var modifier_0 = conversions.validateString(modifier);
  var earlierModifier_0 = conversions.validateString(earlierModifier);
  return new Message(
    conflictingModifiers,
    problemMessage:
        """Members can't be declared to be both '${modifier_0}' and '${earlierModifier_0}'.""",
    correctionMessage: """Try removing one of the keywords.""",
    arguments: {'modifier': modifier, 'earlierModifier': earlierModifier},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constAndFinal = const MessageCode(
  "ConstAndFinal",
  sharedCode: SharedCode.constAndFinal,
  problemMessage:
      """Members can't be declared to be both 'const' and 'final'.""",
  correctionMessage: """Try removing either the 'const' or 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constClass = const MessageCode(
  "ConstClass",
  sharedCode: SharedCode.constClass,
  problemMessage: """Classes can't be declared to be 'const'.""",
  correctionMessage:
      """Try removing the 'const' keyword. If you're trying to indicate that instances of the class can be constants, place the 'const' keyword on  the class' constructor(s).""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constConstructorWithBody = const MessageCode(
  "ConstConstructorWithBody",
  pseudoSharedCode: PseudoSharedCode.constConstructorWithBody,
  problemMessage: """A const constructor can't have a body.""",
  correctionMessage: """Try removing either the 'const' keyword or the body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constFactory = const MessageCode(
  "ConstFactory",
  sharedCode: SharedCode.constFactory,
  problemMessage:
      """Only redirecting factory constructors can be declared to be 'const'.""",
  correctionMessage:
      """Try removing the 'const' keyword, or replacing the body with '=' followed by a valid target.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
constFieldWithoutInitializer = const Template(
  "ConstFieldWithoutInitializer",
  withArguments: _withArgumentsConstFieldWithoutInitializer,
  pseudoSharedCode: PseudoSharedCode.constNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstFieldWithoutInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    constFieldWithoutInitializer,
    problemMessage: """The const variable '${name_0}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constMethod = const MessageCode(
  "ConstMethod",
  sharedCode: SharedCode.constMethod,
  problemMessage:
      """Getters, setters and methods can't be declared to be 'const'.""",
  correctionMessage: """Try removing the 'const' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constWithoutPrimaryConstructor = const MessageCode(
  "ConstWithoutPrimaryConstructor",
  sharedCode: SharedCode.constWithoutPrimaryConstructor,
  problemMessage:
      """'const' can only be used together with a primary constructor declaration.""",
  correctionMessage:
      """Try removing the 'const' keyword or adding a primary constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorWithReturnType = const MessageCode(
  "ConstructorWithReturnType",
  sharedCode: SharedCode.constructorWithReturnType,
  problemMessage: """Constructors can't have a return type.""",
  correctionMessage: """Try removing the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorWithTypeArguments = const MessageCode(
  "ConstructorWithTypeArguments",
  sharedCode: SharedCode.constructorWithTypeArguments,
  problemMessage:
      """A constructor invocation can't have type arguments after the constructor name.""",
  correctionMessage:
      """Try removing the type arguments or placing them after the class name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorWithTypeParameters = const MessageCode(
  "ConstructorWithTypeParameters",
  sharedCode: SharedCode.typeParameterOnConstructor,
  problemMessage: """Constructors can't have type parameters.""",
  correctionMessage: """Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode constructorWithWrongName = const MessageCode(
  "ConstructorWithWrongName",
  sharedCode: SharedCode.invalidConstructorName,
  problemMessage:
      """The name of a constructor must match the name of the enclosing class.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode continueOutsideOfLoop = const MessageCode(
  "ContinueOutsideOfLoop",
  sharedCode: SharedCode.continueOutsideOfLoop,
  problemMessage:
      """A continue statement can't be used outside of a loop or switch statement.""",
  correctionMessage: """Try removing the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode continueWithoutLabelInCase = const MessageCode(
  "ContinueWithoutLabelInCase",
  sharedCode: SharedCode.continueWithoutLabelInCase,
  problemMessage:
      """A continue statement in a switch statement must have a label as a target.""",
  correctionMessage:
      """Try adding a label associated with one of the case clauses to the continue statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode covariantAndStatic = const MessageCode(
  "CovariantAndStatic",
  sharedCode: SharedCode.covariantAndStatic,
  problemMessage:
      """Members can't be declared to be both 'covariant' and 'static'.""",
  correctionMessage:
      """Try removing either the 'covariant' or 'static' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode covariantMember = const MessageCode(
  "CovariantMember",
  sharedCode: SharedCode.covariantMember,
  problemMessage:
      """Getters, setters and methods can't be declared to be 'covariant'.""",
  correctionMessage: """Try removing the 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode defaultInSwitchExpression = const MessageCode(
  "DefaultInSwitchExpression",
  sharedCode: SharedCode.defaultInSwitchExpression,
  problemMessage: """A switch expression may not use the `default` keyword.""",
  correctionMessage: """Try replacing `default` with `_`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode deferredAfterPrefix = const MessageCode(
  "DeferredAfterPrefix",
  sharedCode: SharedCode.deferredAfterPrefix,
  problemMessage:
      """The deferred keyword should come immediately before the prefix ('as' clause).""",
  correctionMessage: """Try moving the deferred keyword before the prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode directiveAfterDeclaration = const MessageCode(
  "DirectiveAfterDeclaration",
  sharedCode: SharedCode.directiveAfterDeclaration,
  problemMessage: """Directives must appear before any declarations.""",
  correctionMessage: """Try moving the directive before any declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicateDeferred = const MessageCode(
  "DuplicateDeferred",
  sharedCode: SharedCode.duplicateDeferred,
  problemMessage:
      """An import directive can only have one 'deferred' keyword.""",
  correctionMessage: """Try removing all but one 'deferred' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String labelName})>
duplicateLabelInSwitchStatement = const Template(
  "DuplicateLabelInSwitchStatement",
  withArguments: _withArgumentsDuplicateLabelInSwitchStatement,
  sharedCode: SharedCode.duplicateLabelInSwitchStatement,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicateLabelInSwitchStatement({
  required String labelName,
}) {
  var labelName_0 = conversions.validateAndDemangleName(labelName);
  return new Message(
    duplicateLabelInSwitchStatement,
    problemMessage:
        """The label '${labelName_0}' was already used in this switch statement.""",
    correctionMessage: """Try choosing a different name for this label.""",
    arguments: {'labelName': labelName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode duplicatePrefix = const MessageCode(
  "DuplicatePrefix",
  sharedCode: SharedCode.duplicatePrefix,
  problemMessage:
      """An import directive can only have one prefix ('as' clause).""",
  correctionMessage: """Try removing all but one prefix.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> duplicatedModifier =
    const Template(
      "DuplicatedModifier",
      withArguments: _withArgumentsDuplicatedModifier,
      sharedCode: SharedCode.duplicatedModifier,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsDuplicatedModifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    duplicatedModifier,
    problemMessage: """The modifier '${lexeme_0}' was already specified.""",
    correctionMessage:
        """Try removing all but one occurrence of the modifier.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode emptyNamedParameterList = const MessageCode(
  "EmptyNamedParameterList",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """Named parameter lists cannot be empty.""",
  correctionMessage: """Try adding a named parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode emptyOptionalParameterList = const MessageCode(
  "EmptyOptionalParameterList",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """Optional parameter lists cannot be empty.""",
  correctionMessage: """Try adding an optional parameter to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode emptyRecordTypeNamedFieldsList = const MessageCode(
  "EmptyRecordTypeNamedFieldsList",
  sharedCode: SharedCode.emptyRecordTypeNamedFieldsList,
  problemMessage:
      """The list of named fields in a record type can't be empty.""",
  correctionMessage: """Try adding a named field to the list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode encoding = const MessageCode(
  "Encoding",
  pseudoSharedCode: PseudoSharedCode.encoding,
  problemMessage: """Unable to decode bytes as UTF-8.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode enumInClass = const MessageCode(
  "EnumInClass",
  sharedCode: SharedCode.enumInClass,
  problemMessage: """Enums can't be declared inside classes.""",
  correctionMessage: """Try moving the enum to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode equalityCannotBeEqualityOperand = const MessageCode(
  "EqualityCannotBeEqualityOperand",
  sharedCode: SharedCode.equalityCannotBeEqualityOperand,
  problemMessage:
      """A comparison expression can't be an operand of another comparison expression.""",
  correctionMessage:
      """Try putting parentheses around one of the comparisons.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String expected})>
expectedAfterButGot = const Template(
  "ExpectedAfterButGot",
  withArguments: _withArgumentsExpectedAfterButGot,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedAfterButGot({required String expected}) {
  var expected_0 = conversions.validateString(expected);
  return new Message(
    expectedAfterButGot,
    problemMessage: """Expected '${expected_0}' after this.""",
    arguments: {'expected': expected},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedAnInitializer = const MessageCode(
  "ExpectedAnInitializer",
  sharedCode: SharedCode.missingInitializer,
  problemMessage: """Expected an initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedBody = const MessageCode(
  "ExpectedBody",
  pseudoSharedCode: PseudoSharedCode.missingFunctionBody,
  problemMessage: """Expected a function body or '=>'.""",
  correctionMessage: """Try adding {}.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String expected})> expectedButGot =
    const Template(
      "ExpectedButGot",
      withArguments: _withArgumentsExpectedButGot,
      pseudoSharedCode: PseudoSharedCode.expectedToken,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot({required String expected}) {
  var expected_0 = conversions.validateString(expected);
  return new Message(
    expectedButGot,
    problemMessage: """Expected '${expected_0}' before this.""",
    arguments: {'expected': expected},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String expected, required String expected2})
>
expectedButGot2 = const Template(
  "ExpectedButGot2",
  withArguments: _withArgumentsExpectedButGot2,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot2({
  required String expected,
  required String expected2,
}) {
  var expected_0 = conversions.validateString(expected);
  var expected2_0 = conversions.validateString(expected2);
  return new Message(
    expectedButGot2,
    problemMessage:
        """Expected '${expected_0}' or '${expected2_0}' before this.""",
    arguments: {'expected': expected, 'expected2': expected2},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedCatchClauseBody = const MessageCode(
  "ExpectedCatchClauseBody",
  sharedCode: SharedCode.expectedCatchClauseBody,
  problemMessage: """A catch clause must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedClassBody = const MessageCode(
  "ExpectedClassBody",
  sharedCode: SharedCode.expectedClassBody,
  problemMessage:
      """A class declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedClassMember =
    const Template(
      "ExpectedClassMember",
      withArguments: _withArgumentsExpectedClassMember,
      pseudoSharedCode: PseudoSharedCode.expectedClassMember,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassMember({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedClassMember,
    problemMessage: """Expected a class member, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedDeclaration =
    const Template(
      "ExpectedDeclaration",
      withArguments: _withArgumentsExpectedDeclaration,
      pseudoSharedCode: PseudoSharedCode.expectedExecutable,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedDeclaration,
    problemMessage: """Expected a declaration, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedElseOrComma = const MessageCode(
  "ExpectedElseOrComma",
  sharedCode: SharedCode.expectedElseOrComma,
  problemMessage: """Expected 'else' or comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedEnumBody =
    const Template(
      "ExpectedEnumBody",
      withArguments: _withArgumentsExpectedEnumBody,
      pseudoSharedCode: PseudoSharedCode.missingEnumBody,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedEnumBody({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedEnumBody,
    problemMessage: """Expected a enum body, but got '${lexeme_0}'.""",
    correctionMessage:
        """An enum definition must have a body with at least one constant name.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedExtensionBody = const MessageCode(
  "ExpectedExtensionBody",
  sharedCode: SharedCode.expectedExtensionBody,
  problemMessage:
      """An extension declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedExtensionTypeBody = const MessageCode(
  "ExpectedExtensionTypeBody",
  sharedCode: SharedCode.expectedExtensionTypeBody,
  problemMessage:
      """An extension type declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedFinallyClauseBody = const MessageCode(
  "ExpectedFinallyClauseBody",
  sharedCode: SharedCode.expectedFinallyClauseBody,
  problemMessage: """A finally clause must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedFunctionBody =
    const Template(
      "ExpectedFunctionBody",
      withArguments: _withArgumentsExpectedFunctionBody,
      pseudoSharedCode: PseudoSharedCode.missingFunctionBody,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedFunctionBody,
    problemMessage: """Expected a function body, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedHexDigit = const MessageCode(
  "ExpectedHexDigit",
  pseudoSharedCode: PseudoSharedCode.missingHexDigit,
  problemMessage: """A hex digit (0-9 or A-F) must follow '0x'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedIdentifier =
    const Template(
      "ExpectedIdentifier",
      withArguments: _withArgumentsExpectedIdentifier,
      pseudoSharedCode: PseudoSharedCode.missingIdentifier,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedIdentifier,
    problemMessage: """Expected an identifier, but got '${lexeme_0}'.""",
    correctionMessage: """Try inserting an identifier before '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
expectedIdentifierButGotKeyword = const Template(
  "ExpectedIdentifierButGotKeyword",
  withArguments: _withArgumentsExpectedIdentifierButGotKeyword,
  sharedCode: SharedCode.expectedIdentifierButGotKeyword,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifierButGotKeyword({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedIdentifierButGotKeyword,
    problemMessage:
        """'${lexeme_0}' can't be used as an identifier because it's a keyword.""",
    correctionMessage:
        """Try renaming this to be an identifier that isn't a keyword.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String expected})> expectedInstead =
    const Template(
      "ExpectedInstead",
      withArguments: _withArgumentsExpectedInstead,
      sharedCode: SharedCode.expectedInstead,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedInstead({required String expected}) {
  var expected_0 = conversions.validateString(expected);
  return new Message(
    expectedInstead,
    problemMessage: """Expected '${expected_0}' instead of this.""",
    arguments: {'expected': expected},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedMixinBody = const MessageCode(
  "ExpectedMixinBody",
  sharedCode: SharedCode.expectedMixinBody,
  problemMessage:
      """A mixin declaration must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedStatement = const MessageCode(
  "ExpectedStatement",
  sharedCode: SharedCode.missingStatement,
  problemMessage: """Expected a statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedString =
    const Template(
      "ExpectedString",
      withArguments: _withArgumentsExpectedString,
      pseudoSharedCode: PseudoSharedCode.expectedStringLiteral,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedString,
    problemMessage: """Expected a String, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedSwitchExpressionBody = const MessageCode(
  "ExpectedSwitchExpressionBody",
  sharedCode: SharedCode.expectedSwitchExpressionBody,
  problemMessage:
      """A switch expression must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedSwitchStatementBody = const MessageCode(
  "ExpectedSwitchStatementBody",
  sharedCode: SharedCode.expectedSwitchStatementBody,
  problemMessage:
      """A switch statement must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String expected})> expectedToken =
    const Template(
      "ExpectedToken",
      withArguments: _withArgumentsExpectedToken,
      pseudoSharedCode: PseudoSharedCode.expectedToken,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedToken({required String expected}) {
  var expected_0 = conversions.validateString(expected);
  return new Message(
    expectedToken,
    problemMessage: """Expected to find '${expected_0}'.""",
    arguments: {'expected': expected},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode expectedTryStatementBody = const MessageCode(
  "ExpectedTryStatementBody",
  sharedCode: SharedCode.expectedTryStatementBody,
  problemMessage: """A try statement must have a body, even if it is empty.""",
  correctionMessage: """Try adding an empty body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> expectedType =
    const Template(
      "ExpectedType",
      withArguments: _withArgumentsExpectedType,
      pseudoSharedCode: PseudoSharedCode.expectedTypeName,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    expectedType,
    problemMessage: """Expected a type, but got '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String featureName,
    required String enabledVersion,
  })
>
experimentNotEnabled = const Template(
  "ExperimentNotEnabled",
  withArguments: _withArgumentsExperimentNotEnabled,
  sharedCode: SharedCode.experimentNotEnabled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabled({
  required String featureName,
  required String enabledVersion,
}) {
  var featureName_0 = conversions.validateString(featureName);
  var enabledVersion_0 = conversions.validateString(enabledVersion);
  return new Message(
    experimentNotEnabled,
    problemMessage:
        """This requires the '${featureName_0}' language feature to be enabled.""",
    correctionMessage:
        """Try updating your pubspec.yaml to set the minimum SDK constraint to ${enabledVersion_0} or higher, and running 'pub get'.""",
    arguments: {'featureName': featureName, 'enabledVersion': enabledVersion},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String featureName})>
experimentNotEnabledOffByDefault = const Template(
  "ExperimentNotEnabledOffByDefault",
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
  sharedCode: SharedCode.experimentNotEnabledOffByDefault,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExperimentNotEnabledOffByDefault({
  required String featureName,
}) {
  var featureName_0 = conversions.validateString(featureName);
  return new Message(
    experimentNotEnabledOffByDefault,
    problemMessage:
        """This requires the experimental '${featureName_0}' language feature to be enabled.""",
    correctionMessage:
        """Try passing the '--enable-experiment=${featureName_0}' command line option.""",
    arguments: {'featureName': featureName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode exportAfterPart = const MessageCode(
  "ExportAfterPart",
  sharedCode: SharedCode.exportDirectiveAfterPartDirective,
  problemMessage: """Export directives must precede part directives.""",
  correctionMessage:
      """Try moving the export directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionAugmentationHasOnClause = const MessageCode(
  "ExtensionAugmentationHasOnClause",
  sharedCode: SharedCode.extensionAugmentationHasOnClause,
  problemMessage: """Extension augmentations can't have 'on' clauses.""",
  correctionMessage: """Try removing the 'on' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionDeclaresAbstractMember = const MessageCode(
  "ExtensionDeclaresAbstractMember",
  sharedCode: SharedCode.extensionDeclaresAbstractMember,
  problemMessage: """Extensions can't declare abstract members.""",
  correctionMessage: """Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionDeclaresConstructor = const MessageCode(
  "ExtensionDeclaresConstructor",
  sharedCode: SharedCode.extensionDeclaresConstructor,
  problemMessage: """Extensions can't declare constructors.""",
  correctionMessage: """Try removing the constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionDeclaresInstanceField = const MessageCode(
  "ExtensionDeclaresInstanceField",
  pseudoSharedCode: PseudoSharedCode.extensionDeclaresInstanceField,
  problemMessage: """Extensions can't declare instance fields""",
  correctionMessage:
      """Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeDeclaresAbstractMember = const MessageCode(
  "ExtensionTypeDeclaresAbstractMember",
  pseudoSharedCode: PseudoSharedCode.extensionTypeWithAbstractMember,
  problemMessage: """Extension types can't declare abstract members.""",
  correctionMessage: """Try providing an implementation for the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeDeclaresInstanceField = const MessageCode(
  "ExtensionTypeDeclaresInstanceField",
  pseudoSharedCode: PseudoSharedCode.extensionTypeDeclaresInstanceField,
  problemMessage: """Extension types can't declare instance fields""",
  correctionMessage:
      """Try removing the field declaration or making it a static field""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeExtends = const MessageCode(
  "ExtensionTypeExtends",
  sharedCode: SharedCode.extensionTypeExtends,
  problemMessage:
      """An extension type declaration can't have an 'extends' clause.""",
  correctionMessage:
      """Try removing the 'extends' clause or replacing the 'extends' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode extensionTypeWith = const MessageCode(
  "ExtensionTypeWith",
  sharedCode: SharedCode.extensionTypeWith,
  problemMessage:
      """An extension type declaration can't have a 'with' clause.""",
  correctionMessage:
      """Try removing the 'with' clause or replacing the 'with' with 'implements'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalClass = const MessageCode(
  "ExternalClass",
  sharedCode: SharedCode.externalClass,
  problemMessage: """Classes can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalConstructorWithFieldInitializers = const MessageCode(
  "ExternalConstructorWithFieldInitializers",
  sharedCode: SharedCode.externalConstructorWithFieldInitializers,
  problemMessage: """An external constructor can't initialize fields.""",
  correctionMessage:
      """Try removing the field initializers, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalConstructorWithInitializer = const MessageCode(
  "ExternalConstructorWithInitializer",
  sharedCode: SharedCode.externalConstructorWithInitializer,
  problemMessage: """An external constructor can't have any initializers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalEnum = const MessageCode(
  "ExternalEnum",
  sharedCode: SharedCode.externalEnum,
  problemMessage: """Enums can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalFactoryRedirection = const MessageCode(
  "ExternalFactoryRedirection",
  sharedCode: SharedCode.externalFactoryRedirection,
  problemMessage: """A redirecting factory can't be external.""",
  correctionMessage: """Try removing the 'external' modifier.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalFactoryWithBody = const MessageCode(
  "ExternalFactoryWithBody",
  sharedCode: SharedCode.externalFactoryWithBody,
  problemMessage: """External factories can't have a body.""",
  correctionMessage:
      """Try removing the body of the factory, or removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalLateField = const MessageCode(
  "ExternalLateField",
  sharedCode: SharedCode.externalLateField,
  problemMessage: """External fields cannot be late.""",
  correctionMessage: """Try removing the 'external' or 'late' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalMethodWithBody = const MessageCode(
  "ExternalMethodWithBody",
  sharedCode: SharedCode.externalMethodWithBody,
  problemMessage: """An external or native method can't have a body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode externalTypedef = const MessageCode(
  "ExternalTypedef",
  sharedCode: SharedCode.externalTypedef,
  problemMessage: """Typedefs can't be declared to be 'external'.""",
  correctionMessage: """Try removing the keyword 'external'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> extraneousModifier =
    const Template(
      "ExtraneousModifier",
      withArguments: _withArgumentsExtraneousModifier,
      sharedCode: SharedCode.extraneousModifier,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    extraneousModifier,
    problemMessage: """Can't have modifier '${lexeme_0}' here.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
extraneousModifierInExtension = const Template(
  "ExtraneousModifierInExtension",
  withArguments: _withArgumentsExtraneousModifierInExtension,
  sharedCode: SharedCode.invalidUseOfCovariantInExtension,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtension({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    extraneousModifierInExtension,
    problemMessage: """Can't have modifier '${lexeme_0}' in an extension.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
extraneousModifierInExtensionType = const Template(
  "ExtraneousModifierInExtensionType",
  withArguments: _withArgumentsExtraneousModifierInExtensionType,
  sharedCode: SharedCode.extraneousModifierInExtensionType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInExtensionType({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    extraneousModifierInExtensionType,
    problemMessage:
        """Can't have modifier '${lexeme_0}' in an extension type.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})>
extraneousModifierInPrimaryConstructor = const Template(
  "ExtraneousModifierInPrimaryConstructor",
  withArguments: _withArgumentsExtraneousModifierInPrimaryConstructor,
  sharedCode: SharedCode.extraneousModifierInPrimaryConstructor,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifierInPrimaryConstructor({
  required Token lexeme,
}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    extraneousModifierInPrimaryConstructor,
    problemMessage:
        """Can't have modifier '${lexeme_0}' in a primary constructor.""",
    correctionMessage: """Try removing '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode factoryConstructorNewName = const MessageCode(
  "FactoryConstructorNewName",
  sharedCode: SharedCode.factoryConstructorNewName,
  problemMessage: """Factory constructors can't be named 'new'.""",
  correctionMessage:
      """Try removing the 'new' keyword or changing it to a different name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode factoryNotSync = const MessageCode(
  "FactoryNotSync",
  pseudoSharedCode: PseudoSharedCode.nonSyncFactory,
  problemMessage: """Factory bodies can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode factoryTopLevelDeclaration = const MessageCode(
  "FactoryTopLevelDeclaration",
  sharedCode: SharedCode.factoryTopLevelDeclaration,
  problemMessage:
      """Top-level declarations can't be declared to be 'factory'.""",
  correctionMessage: """Try removing the keyword 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String argumentName})>
fastaCLIArgumentRequired = const Template(
  "FastaCLIArgumentRequired",
  withArguments: _withArgumentsFastaCLIArgumentRequired,
  pseudoSharedCode: PseudoSharedCode.fastaCliArgumentRequired,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired({required String argumentName}) {
  var argumentName_0 = conversions.validateAndDemangleName(argumentName);
  return new Message(
    fastaCLIArgumentRequired,
    problemMessage: """Expected value after '${argumentName_0}'.""",
    arguments: {'argumentName': argumentName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode fieldInitializedOutsideDeclaringClass = const MessageCode(
  "FieldInitializedOutsideDeclaringClass",
  sharedCode: SharedCode.fieldInitializedOutsideDeclaringClass,
  problemMessage: """A field can only be initialized in its declaring class""",
  correctionMessage:
      """Try passing a value into the superclass constructor, or moving the initialization into the constructor body.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode fieldInitializerOutsideConstructor = const MessageCode(
  "FieldInitializerOutsideConstructor",
  sharedCode: SharedCode.fieldInitializerOutsideConstructor,
  problemMessage:
      """Field formal parameters can only be used in a constructor.""",
  correctionMessage: """Try removing 'this.'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalAndCovariant = const MessageCode(
  "FinalAndCovariant",
  sharedCode: SharedCode.finalAndCovariant,
  problemMessage:
      """Members can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      """Try removing either the 'final' or 'covariant' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalAndCovariantLateWithInitializer = const MessageCode(
  "FinalAndCovariantLateWithInitializer",
  sharedCode: SharedCode.finalAndCovariantLateWithInitializer,
  problemMessage:
      """Members marked 'late' with an initializer can't be declared to be both 'final' and 'covariant'.""",
  correctionMessage:
      """Try removing either the 'final' or 'covariant' keyword, or removing the initializer.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalAndVar = const MessageCode(
  "FinalAndVar",
  sharedCode: SharedCode.finalAndVar,
  problemMessage: """Members can't be declared to be both 'final' and 'var'.""",
  correctionMessage: """Try removing the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalEnum = const MessageCode(
  "FinalEnum",
  sharedCode: SharedCode.finalEnum,
  problemMessage: """Enums can't be declared to be 'final'.""",
  correctionMessage: """Try removing the keyword 'final'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String name})>
finalFieldWithoutInitializer = const Template(
  "FinalFieldWithoutInitializer",
  withArguments: _withArgumentsFinalFieldWithoutInitializer,
  pseudoSharedCode: PseudoSharedCode.finalNotInitialized,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFinalFieldWithoutInitializer({required String name}) {
  var name_0 = conversions.validateAndDemangleName(name);
  return new Message(
    finalFieldWithoutInitializer,
    problemMessage: """The final variable '${name_0}' must be initialized.""",
    correctionMessage:
        """Try adding an initializer ('= expression') to the declaration.""",
    arguments: {'name': name},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalMixin = const MessageCode(
  "FinalMixin",
  sharedCode: SharedCode.finalMixin,
  problemMessage: """A mixin can't be declared 'final'.""",
  correctionMessage: """Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode finalMixinClass = const MessageCode(
  "FinalMixinClass",
  sharedCode: SharedCode.finalMixinClass,
  problemMessage: """A mixin class can't be declared 'final'.""",
  correctionMessage: """Try removing the 'final' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode functionTypeDefaultValue = const MessageCode(
  "FunctionTypeDefaultValue",
  pseudoSharedCode: PseudoSharedCode.defaultValueInFunctionType,
  problemMessage: """Can't have a default value in a function type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode functionTypedParameterVar = const MessageCode(
  "FunctionTypedParameterVar",
  sharedCode: SharedCode.functionTypedParameterVar,
  problemMessage:
      """Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.""",
  correctionMessage: """Try replacing the keyword with a return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode generatorReturnsValue = const MessageCode(
  "GeneratorReturnsValue",
  pseudoSharedCode: PseudoSharedCode.returnInGenerator,
  problemMessage: """'sync*' and 'async*' can't return a value.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode getterConstructor = const MessageCode(
  "GetterConstructor",
  sharedCode: SharedCode.getterConstructor,
  problemMessage: """Constructors can't be a getter.""",
  correctionMessage: """Try removing 'get'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode getterWithFormals = const MessageCode(
  "GetterWithFormals",
  pseudoSharedCode: PseudoSharedCode.getterWithParameters,
  problemMessage: """A getter can't have formal parameters.""",
  correctionMessage: """Try removing '(...)'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode illegalAssignmentToNonAssignable = const MessageCode(
  "IllegalAssignmentToNonAssignable",
  sharedCode: SharedCode.illegalAssignmentToNonAssignable,
  problemMessage: """Illegal assignment to non-assignable expression.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token variableName})>
illegalPatternAssignmentVariableName = const Template(
  "IllegalPatternAssignmentVariableName",
  withArguments: _withArgumentsIllegalPatternAssignmentVariableName,
  sharedCode: SharedCode.illegalPatternAssignmentVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternAssignmentVariableName({
  required Token variableName,
}) {
  var variableName_0 = conversions.tokenToLexeme(variableName);
  return new Message(
    illegalPatternAssignmentVariableName,
    problemMessage:
        """A variable assigned by a pattern assignment can't be named '${variableName_0}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token identifier})>
illegalPatternIdentifierName = const Template(
  "IllegalPatternIdentifierName",
  withArguments: _withArgumentsIllegalPatternIdentifierName,
  sharedCode: SharedCode.illegalPatternIdentifierName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternIdentifierName({
  required Token identifier,
}) {
  var identifier_0 = conversions.tokenToLexeme(identifier);
  return new Message(
    illegalPatternIdentifierName,
    problemMessage:
        """A pattern can't refer to an identifier named '${identifier_0}'.""",
    correctionMessage: """Match the identifier using '==""",
    arguments: {'identifier': identifier},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token variableName})>
illegalPatternVariableName = const Template(
  "IllegalPatternVariableName",
  withArguments: _withArgumentsIllegalPatternVariableName,
  sharedCode: SharedCode.illegalPatternVariableName,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsIllegalPatternVariableName({
  required Token variableName,
}) {
  var variableName_0 = conversions.tokenToLexeme(variableName);
  return new Message(
    illegalPatternVariableName,
    problemMessage:
        """The variable declared by a variable pattern can't be named '${variableName_0}'.""",
    correctionMessage: """Choose a different name.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implementsBeforeExtends = const MessageCode(
  "ImplementsBeforeExtends",
  sharedCode: SharedCode.implementsBeforeExtends,
  problemMessage:
      """The extends clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the extends clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implementsBeforeOn = const MessageCode(
  "ImplementsBeforeOn",
  sharedCode: SharedCode.implementsBeforeOn,
  problemMessage: """The on clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the on clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode implementsBeforeWith = const MessageCode(
  "ImplementsBeforeWith",
  sharedCode: SharedCode.implementsBeforeWith,
  problemMessage: """The with clause must be before the implements clause.""",
  correctionMessage:
      """Try moving the with clause before the implements clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode importAfterPart = const MessageCode(
  "ImportAfterPart",
  sharedCode: SharedCode.importDirectiveAfterPartDirective,
  problemMessage: """Import directives must precede part directives.""",
  correctionMessage:
      """Try moving the import directives before the part directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode initializedVariableInForEach = const MessageCode(
  "InitializedVariableInForEach",
  sharedCode: SharedCode.initializedVariableInForEach,
  problemMessage:
      """The loop variable in a for-each loop can't be initialized.""",
  correctionMessage:
      """Try removing the initializer, or using a different kind of loop.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode interfaceEnum = const MessageCode(
  "InterfaceEnum",
  sharedCode: SharedCode.interfaceEnum,
  problemMessage: """Enums can't be declared to be 'interface'.""",
  correctionMessage: """Try removing the keyword 'interface'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode interfaceMixin = const MessageCode(
  "InterfaceMixin",
  sharedCode: SharedCode.interfaceMixin,
  problemMessage: """A mixin can't be declared 'interface'.""",
  correctionMessage: """Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode interfaceMixinClass = const MessageCode(
  "InterfaceMixinClass",
  sharedCode: SharedCode.interfaceMixinClass,
  problemMessage: """A mixin class can't be declared 'interface'.""",
  correctionMessage: """Try removing the 'interface' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String typeName, required String stackContents})
>
internalProblemStackNotEmpty = const Template(
  "InternalProblemStackNotEmpty",
  withArguments: _withArgumentsInternalProblemStackNotEmpty,
  pseudoSharedCode: PseudoSharedCode.internalProblemStackNotEmpty,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty({
  required String typeName,
  required String stackContents,
}) {
  var typeName_0 = conversions.validateAndDemangleName(typeName);
  var stackContents_0 = conversions.validateString(stackContents);
  return new Message(
    internalProblemStackNotEmpty,
    problemMessage: """${typeName_0}.stack isn't empty:
  ${stackContents_0}""",
    arguments: {'typeName': typeName, 'stackContents': stackContents},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String what, required String where})>
internalProblemUnhandled = const Template(
  "InternalProblemUnhandled",
  withArguments: _withArgumentsInternalProblemUnhandled,
  pseudoSharedCode: PseudoSharedCode.internalProblemUnhandled,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled({
  required String what,
  required String where,
}) {
  var what_0 = conversions.validateString(what);
  var where_0 = conversions.validateString(where);
  return new Message(
    internalProblemUnhandled,
    problemMessage: """Unhandled ${what_0} in ${where_0}.""",
    arguments: {'what': what, 'where': where},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operation})>
internalProblemUnsupported = const Template(
  "InternalProblemUnsupported",
  withArguments: _withArgumentsInternalProblemUnsupported,
  pseudoSharedCode: PseudoSharedCode.internalProblemUnsupported,
  severity: CfeSeverity.internalProblem,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported({required String operation}) {
  var operation_0 = conversions.validateAndDemangleName(operation);
  return new Message(
    internalProblemUnsupported,
    problemMessage: """Unsupported operation: '${operation_0}'.""",
    arguments: {'operation': operation},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode interpolationInUri = const MessageCode(
  "InterpolationInUri",
  pseudoSharedCode: PseudoSharedCode.invalidLiteralInConfiguration,
  problemMessage: """Can't use string interpolation in a URI.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidAwaitFor = const MessageCode(
  "InvalidAwaitFor",
  sharedCode: SharedCode.invalidAwaitInFor,
  problemMessage:
      """The keyword 'await' isn't allowed for a normal 'for' statement.""",
  correctionMessage:
      """Try removing the keyword, or use a for-each statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidCodePoint = const MessageCode(
  "InvalidCodePoint",
  pseudoSharedCode: PseudoSharedCode.invalidCodePoint,
  problemMessage:
      """The escape sequence starting with '\\u' isn't a valid code point.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
invalidConstantPatternBinary = const Template(
  "InvalidConstantPatternBinary",
  withArguments: _withArgumentsInvalidConstantPatternBinary,
  sharedCode: SharedCode.invalidConstantPatternBinary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternBinary({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    invalidConstantPatternBinary,
    problemMessage:
        """The binary operator ${operatorName_0} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidConstantPatternConstPrefix = const MessageCode(
  "InvalidConstantPatternConstPrefix",
  sharedCode: SharedCode.invalidConstantConstPrefix,
  problemMessage:
      """The expression can't be prefixed by 'const' to form a constant pattern.""",
  correctionMessage:
      """Try wrapping the expression in 'const ( ... )' instead.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidConstantPatternDuplicateConst = const MessageCode(
  "InvalidConstantPatternDuplicateConst",
  sharedCode: SharedCode.invalidConstantPatternDuplicateConst,
  problemMessage: """Duplicate 'const' keyword in constant expression.""",
  correctionMessage: """Try removing one of the 'const' keywords.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidConstantPatternEmptyRecordLiteral = const MessageCode(
  "InvalidConstantPatternEmptyRecordLiteral",
  sharedCode: SharedCode.invalidConstantPatternEmptyRecordLiteral,
  problemMessage:
      """The empty record literal is not supported as a constant pattern.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidConstantPatternGeneric = const MessageCode(
  "InvalidConstantPatternGeneric",
  sharedCode: SharedCode.invalidConstantPatternGeneric,
  problemMessage: """This expression is not supported as a constant pattern.""",
  correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidConstantPatternNegation = const MessageCode(
  "InvalidConstantPatternNegation",
  sharedCode: SharedCode.invalidConstantPatternNegation,
  problemMessage:
      """Only negation of a numeric literal is supported as a constant pattern.""",
  correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String operatorName})>
invalidConstantPatternUnary = const Template(
  "InvalidConstantPatternUnary",
  withArguments: _withArgumentsInvalidConstantPatternUnary,
  sharedCode: SharedCode.invalidConstantPatternUnary,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidConstantPatternUnary({
  required String operatorName,
}) {
  var operatorName_0 = conversions.validateAndDemangleName(operatorName);
  return new Message(
    invalidConstantPatternUnary,
    problemMessage:
        """The unary operator ${operatorName_0} is not supported as a constant pattern.""",
    correctionMessage: """Try wrapping the expression in 'const ( ... )'.""",
    arguments: {'operatorName': operatorName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
invalidCovariantModifierInPrimaryConstructor = const MessageCode(
  "InvalidCovariantModifierInPrimaryConstructor",
  sharedCode: SharedCode.invalidCovariantModifierInPrimaryConstructor,
  problemMessage:
      """The 'covariant' modifier can only be used on non-final declaring parameters.""",
  correctionMessage: """Try removing 'covariant'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidEscapeStarted = const MessageCode(
  "InvalidEscapeStarted",
  sharedCode: SharedCode.invalidUnicodeEscapeStarted,
  problemMessage: """The string '\\' can't stand alone.""",
  correctionMessage:
      """Try adding another backslash (\\) to escape the '\\'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidHexEscape = const MessageCode(
  "InvalidHexEscape",
  sharedCode: SharedCode.invalidHexEscape,
  problemMessage:
      """An escape sequence starting with '\\x' must be followed by 2 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidInitializer = const MessageCode(
  "InvalidInitializer",
  sharedCode: SharedCode.invalidInitializer,
  problemMessage: """Not a valid initializer.""",
  correctionMessage:
      """To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidInlineFunctionType = const MessageCode(
  "InvalidInlineFunctionType",
  pseudoSharedCode: PseudoSharedCode.invalidInlineFunctionType,
  problemMessage:
      """Inline function types cannot be used for parameters in a generic function type.""",
  correctionMessage:
      """Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidInsideUnaryPattern = const MessageCode(
  "InvalidInsideUnaryPattern",
  sharedCode: SharedCode.invalidInsideUnaryPattern,
  problemMessage:
      """This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.""",
  correctionMessage:
      """Try combining into a single pattern if possible, or enclose the inner pattern in parentheses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> invalidOperator =
    const Template(
      "InvalidOperator",
      withArguments: _withArgumentsInvalidOperator,
      sharedCode: SharedCode.invalidOperator,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInvalidOperator({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    invalidOperator,
    problemMessage:
        """The string '${lexeme_0}' isn't a user-definable operator.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidSuperInInitializer = const MessageCode(
  "InvalidSuperInInitializer",
  sharedCode: SharedCode.invalidSuperInInitializer,
  problemMessage:
      """Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidSyncModifier = const MessageCode(
  "InvalidSyncModifier",
  pseudoSharedCode: PseudoSharedCode.missingStarAfterSync,
  problemMessage: """Invalid modifier 'sync'.""",
  correctionMessage: """Try replacing 'sync' with 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidThisInInitializer = const MessageCode(
  "InvalidThisInInitializer",
  sharedCode: SharedCode.invalidThisInInitializer,
  problemMessage:
      """Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidUnicodeEscapeUBracket = const MessageCode(
  "InvalidUnicodeEscapeUBracket",
  sharedCode: SharedCode.invalidUnicodeEscapeUBracket,
  problemMessage:
      """An escape sequence starting with '\\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidUnicodeEscapeUNoBracket = const MessageCode(
  "InvalidUnicodeEscapeUNoBracket",
  sharedCode: SharedCode.invalidUnicodeEscapeUNoBracket,
  problemMessage:
      """An escape sequence starting with '\\u' must be followed by 4 hexadecimal digits.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidUnicodeEscapeUStarted = const MessageCode(
  "InvalidUnicodeEscapeUStarted",
  sharedCode: SharedCode.invalidUnicodeEscapeUStarted,
  problemMessage:
      """An escape sequence starting with '\\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode invalidVoid = const MessageCode(
  "InvalidVoid",
  pseudoSharedCode: PseudoSharedCode.expectedTypeName,
  problemMessage: """Type 'void' can't be used here.""",
  correctionMessage:
      """Try removing 'void' keyword or replace it with 'var', 'final', or a type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode latePatternVariableDeclaration = const MessageCode(
  "LatePatternVariableDeclaration",
  sharedCode: SharedCode.latePatternVariableDeclaration,
  problemMessage:
      """A pattern variable declaration may not use the `late` keyword.""",
  correctionMessage: """Try removing the keyword `late`.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode libraryDirectiveNotFirst = const MessageCode(
  "LibraryDirectiveNotFirst",
  sharedCode: SharedCode.libraryDirectiveNotFirst,
  problemMessage:
      """The library directive must appear before all other directives.""",
  correctionMessage:
      """Try moving the library directive before any other directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String kind, required Token lexeme})>
literalWithClass = const Template(
  "LiteralWithClass",
  withArguments: _withArgumentsLiteralWithClass,
  sharedCode: SharedCode.literalWithClass,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClass({
  required String kind,
  required Token lexeme,
}) {
  var kind_0 = conversions.validateString(kind);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    literalWithClass,
    problemMessage:
        """A ${kind_0} literal can't be prefixed by '${lexeme_0}'.""",
    correctionMessage: """Try removing '${lexeme_0}'""",
    arguments: {'kind': kind, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String kind, required Token lexeme})>
literalWithClassAndNew = const Template(
  "LiteralWithClassAndNew",
  withArguments: _withArgumentsLiteralWithClassAndNew,
  sharedCode: SharedCode.literalWithClassAndNew,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsLiteralWithClassAndNew({
  required String kind,
  required Token lexeme,
}) {
  var kind_0 = conversions.validateString(kind);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    literalWithClassAndNew,
    problemMessage:
        """A ${kind_0} literal can't be prefixed by 'new ${lexeme_0}'.""",
    correctionMessage: """Try removing 'new' and '${lexeme_0}'""",
    arguments: {'kind': kind, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode literalWithNew = const MessageCode(
  "LiteralWithNew",
  sharedCode: SharedCode.literalWithNew,
  problemMessage: """A literal can't be prefixed by 'new'.""",
  correctionMessage: """Try removing 'new'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode memberWithSameNameAsClass = const MessageCode(
  "MemberWithSameNameAsClass",
  sharedCode: SharedCode.memberWithClassName,
  problemMessage:
      """A class member can't have the same name as the enclosing class.""",
  correctionMessage: """Try renaming the member.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode metadataSpaceBeforeParenthesis = const MessageCode(
  "MetadataSpaceBeforeParenthesis",
  sharedCode: SharedCode.annotationSpaceBeforeParenthesis,
  problemMessage:
      """Annotations can't have spaces or comments before the parenthesis.""",
  correctionMessage:
      """Remove any spaces or comments before the parenthesis.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode metadataTypeArguments = const MessageCode(
  "MetadataTypeArguments",
  sharedCode: SharedCode.annotationWithTypeArguments,
  problemMessage: """An annotation can't use type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode metadataTypeArgumentsUninstantiated = const MessageCode(
  "MetadataTypeArgumentsUninstantiated",
  sharedCode: SharedCode.annotationWithTypeArgumentsUninstantiated,
  problemMessage:
      """An annotation with type arguments must be followed by an argument list.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingAssignableSelector = const MessageCode(
  "MissingAssignableSelector",
  sharedCode: SharedCode.missingAssignableSelector,
  problemMessage: """Missing selector such as '.identifier' or '[0]'.""",
  correctionMessage: """Try adding a selector.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingAssignmentInInitializer = const MessageCode(
  "MissingAssignmentInInitializer",
  sharedCode: SharedCode.missingAssignmentInInitializer,
  problemMessage: """Expected an assignment after the field name.""",
  correctionMessage:
      """To initialize a field, use the syntax 'name = value'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingConstFinalVarOrType = const MessageCode(
  "MissingConstFinalVarOrType",
  sharedCode: SharedCode.missingConstFinalVarOrType,
  problemMessage:
      """Variables must be declared using the keywords 'const', 'final', 'var' or a type name.""",
  correctionMessage:
      """Try adding the name of the type of the variable or the keyword 'var'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingExponent = const MessageCode(
  "MissingExponent",
  pseudoSharedCode: PseudoSharedCode.missingDigit,
  problemMessage:
      """Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
  correctionMessage:
      """Make sure there is an exponent, and remove any whitespace before it.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingExpressionInThrow = const MessageCode(
  "MissingExpressionInThrow",
  sharedCode: SharedCode.missingExpressionInThrow,
  problemMessage: """Missing expression after 'throw'.""",
  correctionMessage:
      """Add an expression after 'throw' or use 'rethrow' to throw a caught exception""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingFunctionParameters = const MessageCode(
  "MissingFunctionParameters",
  pseudoSharedCode: PseudoSharedCode.missingFunctionParameters,
  problemMessage:
      """A function declaration needs an explicit list of parameters.""",
  correctionMessage:
      """Try adding a parameter list to the function declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingMethodParameters = const MessageCode(
  "MissingMethodParameters",
  pseudoSharedCode: PseudoSharedCode.missingMethodParameters,
  problemMessage:
      """A method declaration needs an explicit list of parameters.""",
  correctionMessage:
      """Try adding a parameter list to the method declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingOperatorKeyword = const MessageCode(
  "MissingOperatorKeyword",
  sharedCode: SharedCode.missingKeywordOperator,
  problemMessage:
      """Operator declarations must be preceded by the keyword 'operator'.""",
  correctionMessage: """Try adding the keyword 'operator'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingPrefixInDeferredImport = const MessageCode(
  "MissingPrefixInDeferredImport",
  sharedCode: SharedCode.missingPrefixInDeferredImport,
  problemMessage: """Deferred imports should have a prefix.""",
  correctionMessage:
      """Try adding a prefix to the import by adding an 'as' clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingPrimaryConstructor = const MessageCode(
  "MissingPrimaryConstructor",
  sharedCode: SharedCode.missingPrimaryConstructor,
  problemMessage:
      """An extension type declaration must have a primary constructor declaration.""",
  correctionMessage:
      """Try adding a primary constructor to the extension type declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingPrimaryConstructorParameters = const MessageCode(
  "MissingPrimaryConstructorParameters",
  sharedCode: SharedCode.missingPrimaryConstructorParameters,
  problemMessage:
      """A primary constructor declaration must have formal parameters.""",
  correctionMessage:
      """Try adding formal parameters after the primary constructor name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode missingTypedefParameters = const MessageCode(
  "MissingTypedefParameters",
  pseudoSharedCode: PseudoSharedCode.missingTypedefParameters,
  problemMessage: """A typedef needs an explicit list of parameters.""",
  correctionMessage: """Try adding a parameter list to the typedef.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinDeclaresConstructor = const MessageCode(
  "MixinDeclaresConstructor",
  sharedCode: SharedCode.mixinDeclaresConstructor,
  problemMessage: """Mixins can't declare constructors.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode mixinWithClause = const MessageCode(
  "MixinWithClause",
  sharedCode: SharedCode.mixinWithClause,
  problemMessage: """A mixin can't have a with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String modifier,
    required String expectedLaterModifier,
  })
>
modifierOutOfOrder = const Template(
  "ModifierOutOfOrder",
  withArguments: _withArgumentsModifierOutOfOrder,
  sharedCode: SharedCode.modifierOutOfOrder,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsModifierOutOfOrder({
  required String modifier,
  required String expectedLaterModifier,
}) {
  var modifier_0 = conversions.validateString(modifier);
  var expectedLaterModifier_0 = conversions.validateString(
    expectedLaterModifier,
  );
  return new Message(
    modifierOutOfOrder,
    problemMessage:
        """The modifier '${modifier_0}' should be before the modifier '${expectedLaterModifier_0}'.""",
    correctionMessage: """Try re-ordering the modifiers.""",
    arguments: {
      'modifier': modifier,
      'expectedLaterModifier': expectedLaterModifier,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String definitionKind, required String clauseKind})
>
multipleClauses = const Template(
  "MultipleClauses",
  withArguments: _withArgumentsMultipleClauses,
  sharedCode: SharedCode.multipleClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMultipleClauses({
  required String definitionKind,
  required String clauseKind,
}) {
  var definitionKind_0 = conversions.validateString(definitionKind);
  var clauseKind_0 = conversions.validateString(clauseKind);
  return new Message(
    multipleClauses,
    problemMessage:
        """Each '${definitionKind_0}' definition can have at most one '${clauseKind_0}' clause.""",
    correctionMessage:
        """Try combining all of the '${clauseKind_0}' clauses into a single clause.""",
    arguments: {'definitionKind': definitionKind, 'clauseKind': clauseKind},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleExtends = const MessageCode(
  "MultipleExtends",
  sharedCode: SharedCode.multipleExtendsClauses,
  problemMessage:
      """Each class definition can have at most one extends clause.""",
  correctionMessage:
      """Try choosing one superclass and define your class to implement (or mix in) the others.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleImplements = const MessageCode(
  "MultipleImplements",
  pseudoSharedCode: PseudoSharedCode.multipleImplementsClauses,
  problemMessage:
      """Each class definition can have at most one implements clause.""",
  correctionMessage:
      """Try combining all of the implements clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleLibraryDirectives = const MessageCode(
  "MultipleLibraryDirectives",
  sharedCode: SharedCode.multipleLibraryDirectives,
  problemMessage: """Only one library directive may be declared in a file.""",
  correctionMessage: """Try removing all but one of the library directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleOnClauses = const MessageCode(
  "MultipleOnClauses",
  sharedCode: SharedCode.multipleOnClauses,
  problemMessage: """Each mixin definition can have at most one on clause.""",
  correctionMessage:
      """Try combining all of the on clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
multiplePrimaryConstructorBodyDeclarations = const MessageCode(
  "MultiplePrimaryConstructorBodyDeclarations",
  sharedCode: SharedCode.multiplePrimaryConstructorBodyDeclarations,
  problemMessage:
      """Only one primary constructor body declaration is allowed.""",
  correctionMessage:
      """Try removing all but one of the primary constructor body declarations.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleVarianceModifiers = const MessageCode(
  "MultipleVarianceModifiers",
  sharedCode: SharedCode.multipleVarianceModifiers,
  problemMessage:
      """Each type parameter can have at most one variance modifier.""",
  correctionMessage:
      """Use at most one of the 'in', 'out', or 'inout' modifiers.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode multipleWith = const MessageCode(
  "MultipleWith",
  sharedCode: SharedCode.multipleWithClauses,
  problemMessage: """Each class definition can have at most one with clause.""",
  correctionMessage:
      """Try combining all of the with clauses into a single clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode namedFunctionExpression = const MessageCode(
  "NamedFunctionExpression",
  pseudoSharedCode: PseudoSharedCode.namedFunctionExpression,
  problemMessage: """A function expression can't have a name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nativeClauseShouldBeAnnotation = const MessageCode(
  "NativeClauseShouldBeAnnotation",
  sharedCode: SharedCode.nativeClauseShouldBeAnnotation,
  problemMessage: """Native clause in this form is deprecated.""",
  correctionMessage:
      """Try removing this native clause and adding @native() or @native('native-name') before the declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode newConstructorDotName = const MessageCode(
  "NewConstructorDotName",
  sharedCode: SharedCode.newConstructorDotName,
  problemMessage:
      """Constructors declared with the 'new' keyword can't use '.' before the constructor name.""",
  correctionMessage: """Try replacing the '.' with a space.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode newConstructorNewName = const MessageCode(
  "NewConstructorNewName",
  sharedCode: SharedCode.newConstructorNewName,
  problemMessage:
      """Constructors declared with the 'new' keyword can't be named 'new'.""",
  correctionMessage:
      """Try removing the second 'new' or changing it to a different name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode newConstructorQualifiedName = const MessageCode(
  "NewConstructorQualifiedName",
  sharedCode: SharedCode.newConstructorQualifiedName,
  problemMessage:
      """Constructors declared with the 'new' keyword can't have qualified names.""",
  correctionMessage:
      """Try removing the class name prefix from the qualified name or removing the 'new' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String character, required int codePoint})
>
nonAsciiIdentifier = const Template(
  "NonAsciiIdentifier",
  withArguments: _withArgumentsNonAsciiIdentifier,
  pseudoSharedCode: PseudoSharedCode.illegalCharacter,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier({
  required String character,
  required int codePoint,
}) {
  var character_0 = conversions.validateCharacter(character);
  var codePoint_0 = conversions.codePointToUnicode(codePoint);
  return new Message(
    nonAsciiIdentifier,
    problemMessage:
        """The non-ASCII character '${character_0}' (${codePoint_0}) can't be used in identifiers, only in strings and comments.""",
    correctionMessage:
        """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
    arguments: {'character': character, 'codePoint': codePoint},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required int codePoint})> nonAsciiWhitespace =
    const Template(
      "NonAsciiWhitespace",
      withArguments: _withArgumentsNonAsciiWhitespace,
      pseudoSharedCode: PseudoSharedCode.illegalCharacter,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace({required int codePoint}) {
  var codePoint_0 = conversions.codePointToUnicode(codePoint);
  return new Message(
    nonAsciiWhitespace,
    problemMessage:
        """The non-ASCII space character ${codePoint_0} can only be used in strings and comments.""",
    arguments: {'codePoint': codePoint},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nonPartOfDirectiveInPart = const MessageCode(
  "NonPartOfDirectiveInPart",
  pseudoSharedCode: PseudoSharedCode.nonPartOfDirectiveInPart,
  problemMessage:
      """The part-of directive must be the only directive in a part.""",
  correctionMessage:
      """Try removing the other directives, or moving them to the library for which this is a part.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
nonRedirectingGenerativeConstructorWithPrimary = const MessageCode(
  "NonRedirectingGenerativeConstructorWithPrimary",
  sharedCode: SharedCode.nonRedirectingGenerativeConstructorWithPrimary,
  problemMessage:
      """Classes with primary constructors can't have non-redirecting generative constructors.""",
  correctionMessage:
      """Try making the constructor redirect to the primary constructor, or remove the primary constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode nullAwareCascadeOutOfOrder = const MessageCode(
  "NullAwareCascadeOutOfOrder",
  sharedCode: SharedCode.nullAwareCascadeOutOfOrder,
  problemMessage:
      """The '?..' cascade operator must be first in the cascade sequence.""",
  correctionMessage:
      """Try moving the '?..' operator to be the first cascade operator in the sequence.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode onlyTry = const MessageCode(
  "OnlyTry",
  sharedCode: SharedCode.missingCatchOrFinally,
  problemMessage:
      """A try block must be followed by an 'on', 'catch', or 'finally' clause.""",
  correctionMessage:
      """Try adding either a catch or finally clause, or remove the try statement.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode operatorWithTypeParameters = const MessageCode(
  "OperatorWithTypeParameters",
  sharedCode: SharedCode.typeParameterOnOperator,
  problemMessage:
      """Types parameters aren't allowed when defining an operator.""",
  correctionMessage: """Try removing the type parameters.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String expectedEarlierClause,
    required String expectedLaterClause,
  })
>
outOfOrderClauses = const Template(
  "OutOfOrderClauses",
  withArguments: _withArgumentsOutOfOrderClauses,
  sharedCode: SharedCode.outOfOrderClauses,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsOutOfOrderClauses({
  required String expectedEarlierClause,
  required String expectedLaterClause,
}) {
  var expectedEarlierClause_0 = conversions.validateString(
    expectedEarlierClause,
  );
  var expectedLaterClause_0 = conversions.validateString(expectedLaterClause);
  return new Message(
    outOfOrderClauses,
    problemMessage:
        """The '${expectedEarlierClause_0}' clause must come before the '${expectedLaterClause_0}' clause.""",
    correctionMessage:
        """Try moving the '${expectedEarlierClause_0}' clause before the '${expectedLaterClause_0}' clause.""",
    arguments: {
      'expectedEarlierClause': expectedEarlierClause,
      'expectedLaterClause': expectedLaterClause,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode partOfTwice = const MessageCode(
  "PartOfTwice",
  sharedCode: SharedCode.multiplePartOfDirectives,
  problemMessage: """Only one part-of directive may be declared in a file.""",
  correctionMessage: """Try removing all but one of the part-of directives.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String variableName})>
patternAssignmentDeclaresVariable = const Template(
  "PatternAssignmentDeclaresVariable",
  withArguments: _withArgumentsPatternAssignmentDeclaresVariable,
  sharedCode: SharedCode.patternAssignmentDeclaresVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsPatternAssignmentDeclaresVariable({
  required String variableName,
}) {
  var variableName_0 = conversions.validateAndDemangleName(variableName);
  return new Message(
    patternAssignmentDeclaresVariable,
    problemMessage:
        """Variable '${variableName_0}' can't be declared in a pattern assignment.""",
    correctionMessage:
        """Try using a preexisting variable or changing the assignment to a pattern variable declaration.""",
    arguments: {'variableName': variableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
patternVariableDeclarationOutsideFunctionOrMethod = const MessageCode(
  "PatternVariableDeclarationOutsideFunctionOrMethod",
  sharedCode: SharedCode.patternVariableDeclarationOutsideFunctionOrMethod,
  problemMessage:
      """A pattern variable declaration may not appear outside a function or method.""",
  correctionMessage:
      """Try declaring ordinary variables and assigning from within a function or method.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode positionalAfterNamedArgument = const MessageCode(
  "PositionalAfterNamedArgument",
  pseudoSharedCode: PseudoSharedCode.positionalAfterNamedArgument,
  problemMessage: """Place positional arguments before named arguments.""",
  correctionMessage:
      """Try moving the positional argument before the named arguments, or add a name to the argument.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode positionalParameterWithEquals = const MessageCode(
  "PositionalParameterWithEquals",
  pseudoSharedCode: PseudoSharedCode.wrongSeparatorForPositionalParameter,
  problemMessage:
      """Positional optional parameters can't use ':' to specify a default value.""",
  correctionMessage: """Try replacing ':' with '='.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode prefixAfterCombinator = const MessageCode(
  "PrefixAfterCombinator",
  sharedCode: SharedCode.prefixAfterCombinator,
  problemMessage:
      """The prefix ('as' clause) should come before any show/hide combinators.""",
  correctionMessage: """Try moving the prefix before the combinators.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode primaryConstructorBodyWithoutDeclaration = const MessageCode(
  "PrimaryConstructorBodyWithoutDeclaration",
  sharedCode: SharedCode.primaryConstructorBodyWithoutDeclaration,
  problemMessage:
      """A primary constructor body requires a primary constructor declaration.""",
  correctionMessage: """Try adding the primary constructor declaration.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode privateNamedNonFieldParameter = const MessageCode(
  "PrivateNamedNonFieldParameter",
  pseudoSharedCode: PseudoSharedCode.privateNamedNonFieldParameter,
  problemMessage:
      """A named parameter that doesn't refer to an instance variable can't start with an underscore ('_').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode privateNamedParameter = const MessageCode(
  "PrivateNamedParameter",
  pseudoSharedCode: PseudoSharedCode.privateOptionalParameter,
  problemMessage: """A named parameter can't start with an underscore ('_').""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
recordLiteralOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordLiteralOnePositionalFieldNoTrailingComma",
  sharedCode: SharedCode.recordLiteralOnePositionalNoTrailingComma,
  problemMessage:
      """A record literal with exactly one positional field requires a trailing comma.""",
  correctionMessage: """Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordLiteralZeroFieldsWithTrailingComma = const MessageCode(
  "RecordLiteralZeroFieldsWithTrailingComma",
  sharedCode: SharedCode.emptyRecordLiteralWithComma,
  problemMessage:
      """A record literal without fields can't have a trailing comma.""",
  correctionMessage: """Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
recordTypeOnePositionalFieldNoTrailingComma = const MessageCode(
  "RecordTypeOnePositionalFieldNoTrailingComma",
  sharedCode: SharedCode.recordTypeOnePositionalNoTrailingComma,
  problemMessage:
      """A record type with exactly one positional field requires a trailing comma.""",
  correctionMessage: """Try adding a trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode recordTypeZeroFieldsButTrailingComma = const MessageCode(
  "RecordTypeZeroFieldsButTrailingComma",
  sharedCode: SharedCode.emptyRecordTypeWithComma,
  problemMessage:
      """A record type without fields can't have a trailing comma.""",
  correctionMessage: """Try removing the trailing comma.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode redirectingConstructorWithBody = const MessageCode(
  "RedirectingConstructorWithBody",
  sharedCode: SharedCode.redirectingConstructorWithBody,
  problemMessage: """Redirecting constructors can't have a body.""",
  correctionMessage:
      """Try removing the body, or not making this a redirecting constructor.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode redirectionInNonFactory = const MessageCode(
  "RedirectionInNonFactory",
  sharedCode: SharedCode.redirectionInNonFactoryConstructor,
  problemMessage: """Only factory constructor can specify '=' redirection.""",
  correctionMessage:
      """Try making this a factory constructor, or remove the redirection.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode requiredParameterWithDefault = const MessageCode(
  "RequiredParameterWithDefault",
  pseudoSharedCode: PseudoSharedCode.namedParameterOutsideGroup,
  problemMessage: """Non-optional parameters can't have a default value.""",
  correctionMessage:
      """Try removing the default value or making the parameter optional.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode sealedEnum = const MessageCode(
  "SealedEnum",
  sharedCode: SharedCode.sealedEnum,
  problemMessage: """Enums can't be declared to be 'sealed'.""",
  correctionMessage: """Try removing the keyword 'sealed'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode sealedMixin = const MessageCode(
  "SealedMixin",
  sharedCode: SharedCode.sealedMixin,
  problemMessage: """A mixin can't be declared 'sealed'.""",
  correctionMessage: """Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode sealedMixinClass = const MessageCode(
  "SealedMixinClass",
  sharedCode: SharedCode.sealedMixinClass,
  problemMessage: """A mixin class can't be declared 'sealed'.""",
  correctionMessage: """Try removing the 'sealed' keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode setOrMapLiteralTooManyTypeArguments = const MessageCode(
  "SetOrMapLiteralTooManyTypeArguments",
  pseudoSharedCode: PseudoSharedCode.setOrMapLiteralTooManyTypeArguments,
  problemMessage:
      """A set or map literal requires exactly one or two type arguments, respectively.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode setterConstructor = const MessageCode(
  "SetterConstructor",
  sharedCode: SharedCode.setterConstructor,
  problemMessage: """Constructors can't be a setter.""",
  correctionMessage: """Try removing 'set'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode setterNotSync = const MessageCode(
  "SetterNotSync",
  pseudoSharedCode: PseudoSharedCode.invalidModifierOnSetter,
  problemMessage: """Setters can't use 'async', 'async*', or 'sync*'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode stackOverflow = const MessageCode(
  "StackOverflow",
  sharedCode: SharedCode.stackOverflow,
  problemMessage: """The file has too many nested expressions or statements.""",
  correctionMessage: """Try simplifying the code.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode staticConstructor = const MessageCode(
  "StaticConstructor",
  sharedCode: SharedCode.staticConstructor,
  problemMessage: """Constructors can't be static.""",
  correctionMessage: """Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode staticOperator = const MessageCode(
  "StaticOperator",
  sharedCode: SharedCode.staticOperator,
  problemMessage: """Operators can't be static.""",
  correctionMessage: """Try removing the keyword 'static'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode superNullAware = const MessageCode(
  "SuperNullAware",
  sharedCode: SharedCode.invalidOperatorQuestionmarkPeriodForSuper,
  problemMessage:
      """The operator '?.' cannot be used with 'super' because 'super' cannot be null.""",
  correctionMessage: """Try replacing '?.' with '.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode switchHasCaseAfterDefault = const MessageCode(
  "SwitchHasCaseAfterDefault",
  sharedCode: SharedCode.switchHasCaseAfterDefaultCase,
  problemMessage:
      """The default case should be the last case in a switch statement.""",
  correctionMessage:
      """Try moving the default case after the other case clauses.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode switchHasMultipleDefaults = const MessageCode(
  "SwitchHasMultipleDefaults",
  sharedCode: SharedCode.switchHasMultipleDefaultCases,
  problemMessage: """The 'default' case can only be declared once.""",
  correctionMessage: """Try removing all but one default case.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode topLevelOperator = const MessageCode(
  "TopLevelOperator",
  sharedCode: SharedCode.topLevelOperator,
  problemMessage: """Operators must be declared within a class.""",
  correctionMessage:
      """Try removing the operator, moving it to a class, or converting it to be a function.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeAfterVar = const MessageCode(
  "TypeAfterVar",
  sharedCode: SharedCode.varAndType,
  problemMessage:
      """Variables can't be declared using both 'var' and a type name.""",
  correctionMessage: """Try removing 'var.'""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String typeVariableName})>
typeArgumentsOnTypeVariable = const Template(
  "TypeArgumentsOnTypeVariable",
  withArguments: _withArgumentsTypeArgumentsOnTypeVariable,
  sharedCode: SharedCode.typeArgumentsOnTypeVariable,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeArgumentsOnTypeVariable({
  required String typeVariableName,
}) {
  var typeVariableName_0 = conversions.validateAndDemangleName(
    typeVariableName,
  );
  return new Message(
    typeArgumentsOnTypeVariable,
    problemMessage:
        """Can't use type arguments with type variable '${typeVariableName_0}'.""",
    correctionMessage: """Try removing the type arguments.""",
    arguments: {'typeVariableName': typeVariableName},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typeBeforeFactory = const MessageCode(
  "TypeBeforeFactory",
  sharedCode: SharedCode.typeBeforeFactory,
  problemMessage: """Factory constructors cannot have a return type.""",
  correctionMessage: """Try removing the type appearing before 'factory'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode typedefInClass = const MessageCode(
  "TypedefInClass",
  sharedCode: SharedCode.typedefInClass,
  problemMessage: """Typedefs can't be declared inside classes.""",
  correctionMessage: """Try moving the typedef to the top-level.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unexpectedDollarInString = const MessageCode(
  "UnexpectedDollarInString",
  pseudoSharedCode: PseudoSharedCode.unexpectedDollarInString,
  problemMessage:
      """A '\$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
  correctionMessage: """Try adding a backslash (\\) to escape the '\$'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unexpectedSeparatorInNumber = const MessageCode(
  "UnexpectedSeparatorInNumber",
  pseudoSharedCode: PseudoSharedCode.unexpectedSeparatorInNumber,
  problemMessage:
      """Digit separators ('_') in a number literal can only be placed between two digits.""",
  correctionMessage: """Try removing the '_'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token lexeme})> unexpectedToken =
    const Template(
      "UnexpectedToken",
      withArguments: _withArgumentsUnexpectedToken,
      pseudoSharedCode: PseudoSharedCode.unexpectedToken,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken({required Token lexeme}) {
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    unexpectedToken,
    problemMessage: """Unexpected token '${lexeme_0}'.""",
    arguments: {'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unexpectedTokens = const MessageCode(
  "UnexpectedTokens",
  sharedCode: SharedCode.unexpectedTokens,
  problemMessage: """Unexpected tokens.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({required String expected, required Token lexeme})
>
unmatchedToken = const Template(
  "UnmatchedToken",
  withArguments: _withArgumentsUnmatchedToken,
  pseudoSharedCode: PseudoSharedCode.expectedToken,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken({
  required String expected,
  required Token lexeme,
}) {
  var expected_0 = conversions.validateString(expected);
  var lexeme_0 = conversions.tokenToLexeme(lexeme);
  return new Message(
    unmatchedToken,
    problemMessage: """Can't find '${expected_0}' to match '${lexeme_0}'.""",
    arguments: {'expected': expected, 'lexeme': lexeme},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required String message})> unspecified =
    const Template(
      "Unspecified",
      withArguments: _withArgumentsUnspecified,
      pseudoSharedCode: PseudoSharedCode.unspecified,
    );

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified({required String message}) {
  var message_0 = conversions.validateString(message);
  return new Message(
    unspecified,
    problemMessage: """${message_0}""",
    arguments: {'message': message},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function({required Token operator})>
unsupportedOperator = const Template(
  "UnsupportedOperator",
  withArguments: _withArgumentsUnsupportedOperator,
  pseudoSharedCode: PseudoSharedCode.unsupportedOperator,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnsupportedOperator({required Token operator}) {
  var operator_0 = conversions.tokenToLexeme(operator);
  return new Message(
    unsupportedOperator,
    problemMessage: """The '${operator_0}' operator is not supported.""",
    arguments: {'operator': operator},
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unsupportedPrefixPlus = const MessageCode(
  "UnsupportedPrefixPlus",
  pseudoSharedCode: PseudoSharedCode.missingIdentifier,
  problemMessage: """'+' is not a prefix operator.""",
  correctionMessage: """Try removing '+'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode unterminatedComment = const MessageCode(
  "UnterminatedComment",
  pseudoSharedCode: PseudoSharedCode.unterminatedMultiLineComment,
  problemMessage: """Comment starting with '/*' must end with '*/'.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
  Message Function({
    required String openQuote,
    required String expectedCloseQuote,
  })
>
unterminatedString = const Template(
  "UnterminatedString",
  withArguments: _withArgumentsUnterminatedString,
  pseudoSharedCode: PseudoSharedCode.unterminatedStringLiteral,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString({
  required String openQuote,
  required String expectedCloseQuote,
}) {
  var openQuote_0 = conversions.validateString(openQuote);
  var expectedCloseQuote_0 = conversions.validateString(expectedCloseQuote);
  return new Message(
    unterminatedString,
    problemMessage:
        """String starting with ${openQuote_0} must end with ${expectedCloseQuote_0}.""",
    arguments: {
      'openQuote': openQuote,
      'expectedCloseQuote': expectedCloseQuote,
    },
  );
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode varAsTypeName = const MessageCode(
  "VarAsTypeName",
  sharedCode: SharedCode.varAsTypeName,
  problemMessage: """The keyword 'var' can't be used as a type name.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode varReturnType = const MessageCode(
  "VarReturnType",
  sharedCode: SharedCode.varReturnType,
  problemMessage: """The return type can't be 'var'.""",
  correctionMessage:
      """Try removing the keyword 'var', or replacing it with the name of the return type.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode
variablePatternKeywordInDeclarationContext = const MessageCode(
  "VariablePatternKeywordInDeclarationContext",
  sharedCode: SharedCode.variablePatternKeywordInDeclarationContext,
  problemMessage:
      """Variable patterns in declaration context can't specify 'var' or 'final' keyword.""",
  correctionMessage: """Try removing the keyword.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode voidWithTypeArguments = const MessageCode(
  "VoidWithTypeArguments",
  sharedCode: SharedCode.voidWithTypeArguments,
  problemMessage: """Type 'void' can't have type arguments.""",
  correctionMessage: """Try removing the type arguments.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode withBeforeExtends = const MessageCode(
  "WithBeforeExtends",
  sharedCode: SharedCode.withBeforeExtends,
  problemMessage: """The extends clause must be before the with clause.""",
  correctionMessage:
      """Try moving the extends clause before the with clause.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode yieldAsIdentifier = const MessageCode(
  "YieldAsIdentifier",
  pseudoSharedCode: PseudoSharedCode.asyncKeywordUsedAsIdentifier,
  problemMessage:
      """'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""",
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode yieldNotGenerator = const MessageCode(
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
  privateNamedNonFieldParameter,
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
  abstractClassMember,
  abstractExternalField,
  abstractFinalBaseClass,
  abstractFinalInterfaceClass,
  abstractLateField,
  abstractSealedClass,
  abstractStaticField,
  annotationOnTypeArgument,
  annotationSpaceBeforeParenthesis,
  annotationWithTypeArguments,
  annotationWithTypeArgumentsUninstantiated,
  anonymousMethodWrongParameterList,
  baseEnum,
  binaryOperatorWrittenOut,
  breakOutsideOfLoop,
  catchSyntax,
  catchSyntaxExtraParameters,
  classInClass,
  colonInPlaceOfIn,
  conflictingModifiers,
  constAndFinal,
  constClass,
  constFactory,
  constMethod,
  constWithoutPrimaryConstructor,
  constructorWithReturnType,
  constructorWithTypeArguments,
  continueOutsideOfLoop,
  continueWithoutLabelInCase,
  covariantAndStatic,
  covariantMember,
  defaultInSwitchExpression,
  deferredAfterPrefix,
  directiveAfterDeclaration,
  duplicateDeferred,
  duplicateLabelInSwitchStatement,
  duplicatePrefix,
  duplicatedModifier,
  emptyRecordLiteralWithComma,
  emptyRecordTypeNamedFieldsList,
  emptyRecordTypeWithComma,
  enumInClass,
  equalityCannotBeEqualityOperand,
  expectedCatchClauseBody,
  expectedClassBody,
  expectedElseOrComma,
  expectedExtensionBody,
  expectedExtensionTypeBody,
  expectedFinallyClauseBody,
  expectedIdentifierButGotKeyword,
  expectedInstead,
  expectedMixinBody,
  expectedSwitchExpressionBody,
  expectedSwitchStatementBody,
  expectedTryStatementBody,
  experimentNotEnabled,
  experimentNotEnabledOffByDefault,
  exportDirectiveAfterPartDirective,
  extensionAugmentationHasOnClause,
  extensionDeclaresAbstractMember,
  extensionDeclaresConstructor,
  extensionTypeExtends,
  extensionTypeWith,
  externalClass,
  externalConstructorWithFieldInitializers,
  externalConstructorWithInitializer,
  externalEnum,
  externalFactoryRedirection,
  externalFactoryWithBody,
  externalLateField,
  externalMethodWithBody,
  externalTypedef,
  extraneousModifier,
  extraneousModifierInExtensionType,
  extraneousModifierInPrimaryConstructor,
  factoryConstructorNewName,
  factoryTopLevelDeclaration,
  fieldInitializedOutsideDeclaringClass,
  fieldInitializerOutsideConstructor,
  finalAndCovariant,
  finalAndCovariantLateWithInitializer,
  finalAndVar,
  finalEnum,
  finalMixin,
  finalMixinClass,
  functionTypedParameterVar,
  getterConstructor,
  illegalAssignmentToNonAssignable,
  illegalPatternAssignmentVariableName,
  illegalPatternIdentifierName,
  illegalPatternVariableName,
  implementsBeforeExtends,
  implementsBeforeOn,
  implementsBeforeWith,
  importDirectiveAfterPartDirective,
  initializedVariableInForEach,
  interfaceEnum,
  interfaceMixin,
  interfaceMixinClass,
  invalidAwaitInFor,
  invalidConstantConstPrefix,
  invalidConstantPatternBinary,
  invalidConstantPatternDuplicateConst,
  invalidConstantPatternEmptyRecordLiteral,
  invalidConstantPatternGeneric,
  invalidConstantPatternNegation,
  invalidConstantPatternUnary,
  invalidConstructorName,
  invalidCovariantModifierInPrimaryConstructor,
  invalidHexEscape,
  invalidInitializer,
  invalidInsideUnaryPattern,
  invalidOperator,
  invalidOperatorQuestionmarkPeriodForSuper,
  invalidSuperInInitializer,
  invalidThisInInitializer,
  invalidUnicodeEscapeStarted,
  invalidUnicodeEscapeUBracket,
  invalidUnicodeEscapeUNoBracket,
  invalidUnicodeEscapeUStarted,
  invalidUseOfCovariantInExtension,
  latePatternVariableDeclaration,
  libraryDirectiveNotFirst,
  literalWithClass,
  literalWithClassAndNew,
  literalWithNew,
  memberWithClassName,
  missingAssignableSelector,
  missingAssignmentInInitializer,
  missingCatchOrFinally,
  missingConstFinalVarOrType,
  missingExpressionInThrow,
  missingInitializer,
  missingKeywordOperator,
  missingPrefixInDeferredImport,
  missingPrimaryConstructor,
  missingPrimaryConstructorParameters,
  missingStatement,
  mixinDeclaresConstructor,
  mixinWithClause,
  modifierOutOfOrder,
  multipleClauses,
  multipleExtendsClauses,
  multipleLibraryDirectives,
  multipleOnClauses,
  multiplePartOfDirectives,
  multiplePrimaryConstructorBodyDeclarations,
  multipleVarianceModifiers,
  multipleWithClauses,
  nativeClauseShouldBeAnnotation,
  newConstructorDotName,
  newConstructorNewName,
  newConstructorQualifiedName,
  nonRedirectingGenerativeConstructorWithPrimary,
  nullAwareCascadeOutOfOrder,
  outOfOrderClauses,
  patternAssignmentDeclaresVariable,
  patternVariableDeclarationOutsideFunctionOrMethod,
  prefixAfterCombinator,
  primaryConstructorBodyWithoutDeclaration,
  recordLiteralOnePositionalNoTrailingComma,
  recordTypeOnePositionalNoTrailingComma,
  redirectingConstructorWithBody,
  redirectionInNonFactoryConstructor,
  sealedEnum,
  sealedMixin,
  sealedMixinClass,
  setterConstructor,
  stackOverflow,
  staticConstructor,
  staticOperator,
  switchHasCaseAfterDefaultCase,
  switchHasMultipleDefaultCases,
  topLevelOperator,
  typeArgumentsOnTypeVariable,
  typeBeforeFactory,
  typeParameterOnConstructor,
  typeParameterOnOperator,
  typedefInClass,
  unexpectedTokens,
  varAndType,
  varAsTypeName,
  varReturnType,
  variablePatternKeywordInDeclarationContext,
  voidWithTypeArguments,
  withBeforeExtends,
}
