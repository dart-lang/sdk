// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/_fasta/generate_messages.dart' to update.

part of fasta.codes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassBodyToSkip =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a class body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassBodyToSkip);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassBodyToSkip =
    const Code<Message Function(Token token)>(
        "ExpectedClassBodyToSkip", templateExpectedClassBodyToSkip,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassBodyToSkip(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassBodyToSkip,
      message: """Expected a class body, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFunctionTypeDefaultValue = messageFunctionTypeDefaultValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFunctionTypeDefaultValue = const MessageCode(
    "FunctionTypeDefaultValue",
    dart2jsCode: "*ignored*",
    message: r"""Can't have a default value in a function type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNonInstanceTypeVariableUse =
    messageNonInstanceTypeVariableUse;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNonInstanceTypeVariableUse = const MessageCode(
    "NonInstanceTypeVariableUse",
    message: r"""Can only use type variables in instance methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemUnsupported =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Unsupported operation: '#name'.""",
        withArguments: _withArgumentsInternalProblemUnsupported);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemUnsupported =
    const Code<Message Function(String name)>(
  "InternalProblemUnsupported",
  templateInternalProblemUnsupported,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnsupported(String name) {
  return new Message(codeInternalProblemUnsupported,
      message: """Unsupported operation: '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemPreviousTokenNotFound =
    messageInternalProblemPreviousTokenNotFound;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemPreviousTokenNotFound =
    const MessageCode("InternalProblemPreviousTokenNotFound",
        message: r"""Couldn't find previous token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeStackOverflow = messageStackOverflow;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageStackOverflow = const MessageCode("StackOverflow",
    dart2jsCode: "GENERIC", message: r"""Stack overflow.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateCyclicTypedef =
    const Template<Message Function(String name)>(
        messageTemplate: r"""The typedef '#name' has a reference to itself.""",
        withArguments: _withArgumentsCyclicTypedef);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeCyclicTypedef =
    const Code<Message Function(String name)>(
  "CyclicTypedef",
  templateCyclicTypedef,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsCyclicTypedef(String name) {
  return new Message(codeCyclicTypedef,
      message: """The typedef '$name' has a reference to itself.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertExtraneousArgument = messageAssertExtraneousArgument;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertExtraneousArgument = const MessageCode(
    "AssertExtraneousArgument",
    dart2jsCode: "*fatal*",
    message: r"""`assert` can't have more than two arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateUnexpectedToken =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Unexpected token '#lexeme'.""",
        withArguments: _withArgumentsUnexpectedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeUnexpectedToken =
    const Code<Message Function(Token token)>(
        "UnexpectedToken", templateUnexpectedToken,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnexpectedToken(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnexpectedToken,
      message: """Unexpected token '$lexeme'.""", arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitAsIdentifier = messageAwaitAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitAsIdentifier = const MessageCode(
    "AwaitAsIdentifier",
    dart2jsCode: "*ignored*",
    message:
        r"""'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFactoryNotSync = messageFactoryNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFactoryNotSync = const MessageCode("FactoryNotSync",
    dart2jsCode: "*ignored*",
    message: r"""Factories can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, Uri uri_)>
    templateInternalProblemConstructorNotFound =
    const Template<Message Function(String name, Uri uri_)>(
        messageTemplate: r"""No constructor named '#name' in '#uri'.""",
        withArguments: _withArgumentsInternalProblemConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, Uri uri_)>
    codeInternalProblemConstructorNotFound =
    const Code<Message Function(String name, Uri uri_)>(
  "InternalProblemConstructorNotFound",
  templateInternalProblemConstructorNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemConstructorNotFound(
    String name, Uri uri_) {
  String uri = relativizeUri(uri_);
  return new Message(codeInternalProblemConstructorNotFound,
      message: """No constructor named '$name' in '$uri'.""",
      arguments: {'name': name, 'uri': uri_});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSuperNullAware = messageSuperNullAware;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSuperNullAware = const MessageCode("SuperNullAware",
    dart2jsCode: "*ignored*",
    message: r"""'super' can't be null.""",
    tip: r"""Try replacing '?.' with '.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePrivateNamedParameter = messagePrivateNamedParameter;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePrivateNamedParameter = const MessageCode(
    "PrivateNamedParameter",
    dart2jsCode: "*ignored*",
    message: r"""An optional named parameter can't start with '_'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldNotGenerator = messageYieldNotGenerator;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldNotGenerator = const MessageCode(
    "YieldNotGenerator",
    dart2jsCode: "*ignored*",
    message: r"""'yield' can only be used in 'sync*' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeReturnTypeFunctionExpression =
    messageReturnTypeFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageReturnTypeFunctionExpression = const MessageCode(
    "ReturnTypeFunctionExpression",
    dart2jsCode: "*ignored*",
    message: r"""A function expression can't have a return type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeSetterNotSync = messageSetterNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageSetterNotSync = const MessageCode("SetterNotSync",
    dart2jsCode: "*ignored*",
    message: r"""Setters can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateNonAsciiWhitespace = const Template<
        Message Function(int codePoint)>(
    messageTemplate:
        r"""The non-ASCII space character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsNonAsciiWhitespace);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeNonAsciiWhitespace =
    const Code<Message Function(int codePoint)>(
        "NonAsciiWhitespace", templateNonAsciiWhitespace,
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiWhitespace(int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new Message(codeNonAsciiWhitespace,
      message:
          """The non-ASCII space character $unicode can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedIdentifier =
    const Template<Message Function(Token token)>(
        messageTemplate:
            r"""'#lexeme' is a reserved word and can't be used here.""",
        tipTemplate: r"""Try using a different name.""",
        withArguments: _withArgumentsExpectedIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedIdentifier =
    const Code<Message Function(Token token)>(
        "ExpectedIdentifier", templateExpectedIdentifier,
        dart2jsCode: "EXPECTED_IDENTIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedIdentifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedIdentifier,
      message: """'$lexeme' is a reserved word and can't be used here.""",
      tip: """Try using a different name.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBlockToSkip = messageExpectedBlockToSkip;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBlockToSkip = const MessageCode(
    "ExpectedBlockToSkip",
    dart2jsCode: "NATIVE_OR_BODY_EXPECTED",
    message: r"""Expected a function body or '=>'.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeRequiredParameterWithDefault =
    messageRequiredParameterWithDefault;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageRequiredParameterWithDefault = const MessageCode(
    "RequiredParameterWithDefault",
    dart2jsCode: "REQUIRED_PARAMETER_WITH_DEFAULT",
    message: r"""Non-optional parameters can't have a default value.""",
    tip:
        r"""Try removing the default value or making the parameter optional.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateUnspecified =
    const Template<Message Function(String string)>(
        messageTemplate: r"""#string""",
        withArguments: _withArgumentsUnspecified);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeUnspecified =
    const Code<Message Function(String string)>(
        "Unspecified", templateUnspecified,
        dart2jsCode: "GENERIC");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnspecified(String string) {
  return new Message(codeUnspecified,
      message: """$string""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMissingExponent = messageMissingExponent;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMissingExponent = const MessageCode("MissingExponent",
    analyzerCode: "MISSING_DIGIT",
    dart2jsCode: "EXPONENT_MISSING",
    message:
        r"""Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).""",
    tip:
        r"""Make sure there is an exponent, and remove any whitespace before it.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codePositionalParameterWithEquals =
    messagePositionalParameterWithEquals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messagePositionalParameterWithEquals = const MessageCode(
    "PositionalParameterWithEquals",
    dart2jsCode: "POSITIONAL_PARAMETER_WITH_EQUALS",
    message:
        r"""Positional optional parameters can't use ':' to specify a default value.""",
    tip: r"""Try replacing ':' with '='.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnexpectedDollarInString = messageUnexpectedDollarInString;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnexpectedDollarInString = const MessageCode(
    "UnexpectedDollarInString",
    dart2jsCode: "MALFORMED_STRING_LITERAL",
    message:
        r"""A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).""",
    tip: r"""Try adding a backslash (\) to escape the '$'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFinalFieldWithoutInitializer =
    messageFinalFieldWithoutInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFinalFieldWithoutInitializer = const MessageCode(
    "FinalFieldWithoutInitializer",
    dart2jsCode: "*ignored*",
    message: r"""A 'final' field must be initialized.""",
    tip: r"""Try adding '= <initializer>'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExtraneousModifier =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't have modifier '#lexeme' here.""",
        tipTemplate: r"""Try removing '#lexeme'.""",
        withArguments: _withArgumentsExtraneousModifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExtraneousModifier =
    const Code<Message Function(Token token)>(
        "ExtraneousModifier", templateExtraneousModifier,
        dart2jsCode: "EXTRANEOUS_MODIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExtraneousModifier(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExtraneousModifier,
      message: """Can't have modifier '$lexeme' here.""",
      tip: """Try removing '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyOptionalParameterList =
    messageEmptyOptionalParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyOptionalParameterList = const MessageCode(
    "EmptyOptionalParameterList",
    dart2jsCode: "EMPTY_OPTIONAL_PARAMETER_LIST",
    message: r"""Optional parameter lists cannot be empty.""",
    tip: r"""Try adding an optional parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String name2)>
    templateInternalProblemNotFoundIn =
    const Template<Message Function(String name, String name2)>(
        messageTemplate: r"""Couldn't find '#name' in '#name2'.""",
        withArguments: _withArgumentsInternalProblemNotFoundIn);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String name2)>
    codeInternalProblemNotFoundIn =
    const Code<Message Function(String name, String name2)>(
  "InternalProblemNotFoundIn",
  templateInternalProblemNotFoundIn,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFoundIn(String name, String name2) {
  return new Message(codeInternalProblemNotFoundIn,
      message: """Couldn't find '$name' in '$name2'.""",
      arguments: {'name': name, 'name2': name2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateTypeNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Type '#name' not found.""",
        withArguments: _withArgumentsTypeNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeTypeNotFound =
    const Code<Message Function(String name)>(
  "TypeNotFound",
  templateTypeNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsTypeNotFound(String name) {
  return new Message(codeTypeNotFound,
      message: """Type '$name' not found.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemSuperclassNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Superclass not found '#name'.""",
        withArguments: _withArgumentsInternalProblemSuperclassNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInternalProblemSuperclassNotFound =
    const Code<Message Function(String name)>(
  "InternalProblemSuperclassNotFound",
  templateInternalProblemSuperclassNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemSuperclassNotFound(String name) {
  return new Message(codeInternalProblemSuperclassNotFound,
      message: """Superclass not found '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateUnterminatedString =
    const Template<Message Function(String string)>(
        messageTemplate: r"""String must end with #string.""",
        withArguments: _withArgumentsUnterminatedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeUnterminatedString =
    const Code<Message Function(String string)>(
        "UnterminatedString", templateUnterminatedString,
        analyzerCode: "UNTERMINATED_STRING_LITERAL",
        dart2jsCode: "UNTERMINATED_STRING");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnterminatedString(String string) {
  return new Message(codeUnterminatedString,
      message: """String must end with $string.""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitNotAsync = messageAwaitNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitNotAsync = const MessageCode("AwaitNotAsync",
    dart2jsCode: "*ignored*",
    message: r"""'await' can only be used in 'async' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemBodyOnAbstractMethod =
    messageInternalProblemBodyOnAbstractMethod;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemBodyOnAbstractMethod =
    const MessageCode("InternalProblemBodyOnAbstractMethod",
        message: r"""Attempting to set body on abstract method.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedFunctionBody =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a function body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedFunctionBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedFunctionBody =
    const Code<Message Function(Token token)>(
        "ExpectedFunctionBody", templateExpectedFunctionBody,
        dart2jsCode: "NATIVE_OR_FATAL");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedFunctionBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedFunctionBody,
      message: """Expected a function body, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedHexDigit = messageExpectedHexDigit;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedHexDigit = const MessageCode(
    "ExpectedHexDigit",
    analyzerCode: "MISSING_HEX_DIGIT",
    dart2jsCode: "HEX_DIGIT_EXPECTED",
    message: r"""A hex digit (0-9 or A-F) must follow '0x'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEmptyNamedParameterList = messageEmptyNamedParameterList;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEmptyNamedParameterList = const MessageCode(
    "EmptyNamedParameterList",
    dart2jsCode: "EMPTY_NAMED_PARAMETER_LIST",
    message: r"""Named parameter lists cannot be empty.""",
    tip: r"""Try adding a named parameter to the list.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnsupportedPrefixPlus = messageUnsupportedPrefixPlus;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnsupportedPrefixPlus = const MessageCode(
    "UnsupportedPrefixPlus",
    dart2jsCode: "UNSUPPORTED_PREFIX_PLUS",
    message: r"""'+' is not a prefix operator. """,
    tip: r"""Try removing '+'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedString =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a String, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedString);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedString =
    const Code<Message Function(Token token)>(
        "ExpectedString", templateExpectedString,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedString(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedString,
      message: """Expected a String, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageShort = messageFastaUsageShort;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageShort =
    const MessageCode("FastaUsageShort", message: r"""Frequently used options:

  -o <file> Generate the output into <file>.
  -h        Display this message (add -v for information about all options).""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeAfterVar = messageTypeAfterVar;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeAfterVar = const MessageCode("TypeAfterVar",
    dart2jsCode: "EXTRANEOUS_MODIFIER",
    message: r"""Can't have both a type and 'var'.""",
    tip: r"""Try removing 'var.'""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateAbstractClassInstantiation =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""The class '#name' is abstract and can't be instantiated.""",
        withArguments: _withArgumentsAbstractClassInstantiation);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeAbstractClassInstantiation =
    const Code<Message Function(String name)>(
  "AbstractClassInstantiation",
  templateAbstractClassInstantiation,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAbstractClassInstantiation(String name) {
  return new Message(codeAbstractClassInstantiation,
      message: """The class '$name' is abstract and can't be instantiated.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAbstractNotSync = messageAbstractNotSync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAbstractNotSync = const MessageCode("AbstractNotSync",
    dart2jsCode: "*ignored*",
    message: r"""Abstract methods can't use 'async', 'async*', or 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name, String string)>
    templateInternalProblemStackNotEmpty =
    const Template<Message Function(String name, String string)>(
        messageTemplate: r"""#name.stack isn't empty:
  #string""", withArguments: _withArgumentsInternalProblemStackNotEmpty);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name, String string)>
    codeInternalProblemStackNotEmpty =
    const Code<Message Function(String name, String string)>(
  "InternalProblemStackNotEmpty",
  templateInternalProblemStackNotEmpty,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemStackNotEmpty(String name, String string) {
  return new Message(codeInternalProblemStackNotEmpty,
      message: """$name.stack isn't empty:
  $string""", arguments: {'name': name, 'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateGetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Getter not found: '#name'.""",
        withArguments: _withArgumentsGetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeGetterNotFound =
    const Code<Message Function(String name)>(
  "GetterNotFound",
  templateGetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsGetterNotFound(String name) {
  return new Message(codeGetterNotFound,
      message: """Getter not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateInternalProblemPrivateConstructorAccess =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Can't access private constructor '#name'.""",
        withArguments: _withArgumentsInternalProblemPrivateConstructorAccess);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)>
    codeInternalProblemPrivateConstructorAccess =
    const Code<Message Function(String name)>(
  "InternalProblemPrivateConstructorAccess",
  templateInternalProblemPrivateConstructorAccess,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemPrivateConstructorAccess(String name) {
  return new Message(codeInternalProblemPrivateConstructorAccess,
      message: """Can't access private constructor '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTooManyTypeArguments =
    messageListLiteralTooManyTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTooManyTypeArguments = const MessageCode(
    "ListLiteralTooManyTypeArguments",
    message: r"""Too many type arguments on List literal.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedDeclaration =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a declaration, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedDeclaration =
    const Code<Message Function(Token token)>(
        "ExpectedDeclaration", templateExpectedDeclaration,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedDeclaration,
      message: """Expected a declaration, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)>
    templateInternalProblemUnimplemented =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Unimplemented #string.""",
        withArguments: _withArgumentsInternalProblemUnimplemented);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeInternalProblemUnimplemented =
    const Code<Message Function(String string)>(
  "InternalProblemUnimplemented",
  templateInternalProblemUnimplemented,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnimplemented(String string) {
  return new Message(codeInternalProblemUnimplemented,
      message: """Unimplemented $string.""", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateConstructorNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Couldn't find constructor '#name'.""",
        withArguments: _withArgumentsConstructorNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeConstructorNotFound =
    const Code<Message Function(String name)>(
  "ConstructorNotFound",
  templateConstructorNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsConstructorNotFound(String name) {
  return new Message(codeConstructorNotFound,
      message: """Couldn't find constructor '$name'.""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        int
            codePoint)> templateAsciiControlCharacter = const Template<
        Message Function(int codePoint)>(
    messageTemplate:
        r"""The control character #unicode can only be used in strings and comments.""",
    withArguments: _withArgumentsAsciiControlCharacter);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(int codePoint)> codeAsciiControlCharacter =
    const Code<Message Function(int codePoint)>(
        "AsciiControlCharacter", templateAsciiControlCharacter,
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsAsciiControlCharacter(int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new Message(codeAsciiControlCharacter,
      message:
          """The control character $unicode can only be used in strings and comments.""",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, Token token)>
    templateUnmatchedToken =
    const Template<Message Function(String string, Token token)>(
        messageTemplate: r"""Can't find '#string' to match '#lexeme'.""",
        withArguments: _withArgumentsUnmatchedToken);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, Token token)> codeUnmatchedToken =
    const Code<Message Function(String string, Token token)>(
        "UnmatchedToken", templateUnmatchedToken,
        dart2jsCode: "UNMATCHED_TOKEN");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsUnmatchedToken(String string, Token token) {
  String lexeme = token.lexeme;
  return new Message(codeUnmatchedToken,
      message: """Can't find '$string' to match '$lexeme'.""",
      arguments: {'string': string, 'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateInternalProblemNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Couldn't find '#name'.""",
        withArguments: _withArgumentsInternalProblemNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeInternalProblemNotFound =
    const Code<Message Function(String name)>(
  "InternalProblemNotFound",
  templateInternalProblemNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemNotFound(String name) {
  return new Message(codeInternalProblemNotFound,
      message: """Couldn't find '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidSyncModifier = messageInvalidSyncModifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidSyncModifier = const MessageCode(
    "InvalidSyncModifier",
    dart2jsCode: "INVALID_SYNC_MODIFIER",
    message: r"""Invalid modifier 'sync'.""",
    tip: r"""Try replacing 'sync' with 'sync*'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnhandled =
    const Template<Message Function(String string, String string2)>(
        messageTemplate: r"""Unhandled #string in #string2.""",
        withArguments: _withArgumentsInternalProblemUnhandled);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnhandled =
    const Code<Message Function(String string, String string2)>(
  "InternalProblemUnhandled",
  templateInternalProblemUnhandled,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnhandled(String string, String string2) {
  return new Message(codeInternalProblemUnhandled,
      message: """Unhandled $string in $string2.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateFastaCLIArgumentRequired =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Expected value after '#name'.""",
        withArguments: _withArgumentsFastaCLIArgumentRequired);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeFastaCLIArgumentRequired =
    const Code<Message Function(String name)>(
  "FastaCLIArgumentRequired",
  templateFastaCLIArgumentRequired,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsFastaCLIArgumentRequired(String name) {
  return new Message(codeFastaCLIArgumentRequired,
      message: """Expected value after '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGetterWithFormals = messageGetterWithFormals;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGetterWithFormals = const MessageCode(
    "GetterWithFormals",
    dart2jsCode: "*ignored*",
    message: r"""A getter can't have formal parameters.""",
    tip: r"""Try removing '(...)'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(Token token)> templateNoFormals = const Template<
        Message Function(Token token)>(
    messageTemplate: r"""A function should have formal parameters.""",
    tipTemplate:
        r"""Try adding '()' after '#lexeme', or add 'get' before '#lexeme' to declare a getter.""",
    withArguments: _withArgumentsNoFormals);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeNoFormals =
    const Code<Message Function(Token token)>("NoFormals", templateNoFormals,
        dart2jsCode: "*ignored*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNoFormals(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeNoFormals,
      message: """A function should have formal parameters.""",
      tip:
          """Try adding '()' after '$lexeme', or add 'get' before '$lexeme' to declare a getter.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedOpenParens = messageExpectedOpenParens;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedOpenParens = const MessageCode(
    "ExpectedOpenParens",
    dart2jsCode: "GENERIC",
    message: r"""Expected '('.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedComment = messageUnterminatedComment;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedComment = const MessageCode(
    "UnterminatedComment",
    analyzerCode: "UNTERMINATED_MULTI_LINE_COMMENT",
    dart2jsCode: "UNTERMINATED_COMMENT",
    message: r"""Comment starting with '/*' must end with '*/'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeCatchSyntax = messageCatchSyntax;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageCatchSyntax = const MessageCode("CatchSyntax",
    dart2jsCode: "*ignored*",
    message:
        r"""'catch' must be followed by '(identifier)' or '(identifier, identifier)'.""",
    tip:
        r"""No types are needed, the first is given by 'on', the second is always 'StackTrace'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedClassBody =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a class body, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedClassBody);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedClassBody =
    const Code<Message Function(Token token)>(
        "ExpectedClassBody", templateExpectedClassBody,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedClassBody(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedClassBody,
      message: """Expected a class body, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateNotAType =
    const Template<Message Function(String name)>(
        messageTemplate: r"""'#name' isn't a type.""",
        withArguments: _withArgumentsNotAType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeNotAType =
    const Code<Message Function(String name)>(
  "NotAType",
  templateNotAType,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNotAType(String name) {
  return new Message(codeNotAType,
      message: """'$name' isn't a type.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedExpression =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected an expression, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedExpression);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedExpression =
    const Code<Message Function(Token token)>(
        "ExpectedExpression", templateExpectedExpression,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedExpression(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedExpression,
      message: """Expected an expression, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidAwaitFor = messageInvalidAwaitFor;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidAwaitFor = const MessageCode("InvalidAwaitFor",
    dart2jsCode: "INVALID_AWAIT_FOR",
    message:
        r"""'await' is only supported in methods with an 'async' or 'async*' body modifier.""",
    tip:
        r"""Try adding 'async' or 'async*' to the method body or removing the 'await' keyword.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string, String string2)>
    templateInternalProblemUnexpected =
    const Template<Message Function(String string, String string2)>(
        messageTemplate: r"""Expected '#string', but got '#string2'.""",
        withArguments: _withArgumentsInternalProblemUnexpected);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string, String string2)>
    codeInternalProblemUnexpected =
    const Code<Message Function(String string, String string2)>(
  "InternalProblemUnexpected",
  templateInternalProblemUnexpected,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsInternalProblemUnexpected(String string, String string2) {
  return new Message(codeInternalProblemUnexpected,
      message: """Expected '$string', but got '$string2'.""",
      arguments: {'string': string, 'string2': string2});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateExpectedType =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Expected a type, but got '#lexeme'.""",
        withArguments: _withArgumentsExpectedType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeExpectedType =
    const Code<Message Function(Token token)>(
        "ExpectedType", templateExpectedType,
        dart2jsCode: "*fatal*");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeExpectedType,
      message: """Expected a type, but got '$lexeme'.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeUnterminatedToken = messageUnterminatedToken;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageUnterminatedToken = const MessageCode(
    "UnterminatedToken",
    dart2jsCode: "UNTERMINATED_TOKEN",
    message: r"""Incomplete token.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateSetterNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Setter not found: '#name'.""",
        withArguments: _withArgumentsSetterNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeSetterNotFound =
    const Code<Message Function(String name)>(
  "SetterNotFound",
  templateSetterNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsSetterNotFound(String name) {
  return new Message(codeSetterNotFound,
      message: """Setter not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String string)> templateExpectedButGot =
    const Template<Message Function(String string)>(
        messageTemplate: r"""Expected '#string' before this.""",
        tipTemplate: r"""DONT_KNOW_HOW_TO_FIX,""",
        withArguments: _withArgumentsExpectedButGot);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String string)> codeExpectedButGot =
    const Code<Message Function(String string)>(
        "ExpectedButGot", templateExpectedButGot,
        dart2jsCode: "MISSING_TOKEN_BEFORE_THIS");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsExpectedButGot(String string) {
  return new Message(codeExpectedButGot,
      message: """Expected '$string' before this.""",
      tip: """DONT_KNOW_HOW_TO_FIX,""",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeNamedFunctionExpression = messageNamedFunctionExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageNamedFunctionExpression = const MessageCode(
    "NamedFunctionExpression",
    dart2jsCode: "*ignored*",
    message: r"""A function expression can't have a name.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeConstFieldWithoutInitializer =
    messageConstFieldWithoutInitializer;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageConstFieldWithoutInitializer = const MessageCode(
    "ConstFieldWithoutInitializer",
    dart2jsCode: "*ignored*",
    message: r"""A 'const' field must be initialized.""",
    tip: r"""Try adding '= <initializer>'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeFastaUsageLong = messageFastaUsageLong;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageFastaUsageLong =
    const MessageCode("FastaUsageLong", message: r"""Supported options:

  -o <file>, --output=<file>
    Generate the output into <file>.

  -h, /h, /?, --help
    Display this message (add -v for information about all options).

  -v, --verbose
    Display verbose information.

  --
    Stop option parsing, the rest of the command line is assumed to be
    file names or arguments to the Dart program.

  --packages=<file>
    Use package resolution configuration <file>, which should contain a mapping
    of package names to paths.

  --platform=<file>
    Read the SDK platform from <file>, which should be in Dill/Kernel IR format
    and contain the Dart SDK.

  --target=none|vm|vmcc|vmreify|flutter
    Specify the target configuration.

  --verify
    Check that the generated output is free of various problems. This is mostly
    useful for developers of this compiler or Kernel transformations.

  --dump-ir
    Print compiled libraries in Kernel source notation.

  --exclude-source
    Do not include source code in the dill file.

  --compile-sdk=<patched_sdk>
    Compile the SDK from scratch instead of reading it from 'platform.dill'.

  --sdk=<patched_sdk>
    Location of the SDK sources for use when compiling additional platform
    libraries.

  --fatal=errors
  --fatal=warnings
  --fatal=nits
    Makes messages of the given kinds fatal, that is, immediately stop the
    compiler with a non-zero exit-code. In --verbose mode, also display an
    internal stack trace from the compiler. Multiple kinds can be separated by
    commas, for example, --fatal=errors,warnings.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAwaitForNotAsync = messageAwaitForNotAsync;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAwaitForNotAsync = const MessageCode(
    "AwaitForNotAsync",
    dart2jsCode: "*ignored*",
    message:
        r"""Asynchronous for-loop can only be used in 'async' or 'async*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeEncoding = messageEncoding;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageEncoding = const MessageCode("Encoding",
    dart2jsCode: "*fatal*", message: r"""Unable to decode bytes as UTF-8.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAsyncAsIdentifier = messageAsyncAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAsyncAsIdentifier = const MessageCode(
    "AsyncAsIdentifier",
    analyzerCode: "ASYNC_KEYWORD_USED_AS_IDENTIFIER",
    dart2jsCode: "GENERIC",
    message:
        r"""'async' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeYieldAsIdentifier = messageYieldAsIdentifier;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageYieldAsIdentifier = const MessageCode(
    "YieldAsIdentifier",
    dart2jsCode: "*ignored*",
    message:
        r"""'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeAssertAsExpression = messageAssertAsExpression;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageAssertAsExpression = const MessageCode(
    "AssertAsExpression",
    dart2jsCode: "*fatal*",
    message: r"""`assert` can't be used as an expression.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeOnlyTry = messageOnlyTry;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageOnlyTry = const MessageCode("OnlyTry",
    dart2jsCode: "*ignored*",
    message:
        r"""Try block should be followed by 'on', 'catch', or 'finally' block.""",
    tip: r"""Did you forget to add a 'finally' block?""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidInlineFunctionType =
    messageInvalidInlineFunctionType;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidInlineFunctionType = const MessageCode(
    "InvalidInlineFunctionType",
    dart2jsCode: "INVALID_INLINE_FUNCTION_TYPE",
    message: r"""Invalid inline function type.""",
    tip:
        r"""Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeMetadataTypeArguments = messageMetadataTypeArguments;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageMetadataTypeArguments = const MessageCode(
    "MetadataTypeArguments",
    dart2jsCode: "*ignored*",
    message: r"""An annotation (metadata) can't use type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeExpectedBody = messageExpectedBody;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageExpectedBody = const MessageCode("ExpectedBody",
    dart2jsCode: "BODY_EXPECTED",
    message: r"""Expected a function body or '=>'.""",
    tip: r"""Try adding {}.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeTypeRequired = messageTypeRequired;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageTypeRequired = const MessageCode("TypeRequired",
    message: r"""A type or modifier is required here.""",
    tip: r"""Try adding a type, 'var', 'const', or 'final'.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemAlreadyInitialized =
    messageInternalProblemAlreadyInitialized;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemAlreadyInitialized = const MessageCode(
    "InternalProblemAlreadyInitialized",
    message: r"""Attempt to set initializer on field without initializer.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInvalidVoid = messageInvalidVoid;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInvalidVoid = const MessageCode("InvalidVoid",
    dart2jsCode: "VOID_NOT_ALLOWED",
    message:
        r"""Type 'void' can't be used here because it isn't a return type.""",
    tip:
        r"""Try removing 'void' keyword or replace it with 'var', 'final', or a type.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)> templateBuiltInIdentifierAsType =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't use '#lexeme' as a type.""",
        withArguments: _withArgumentsBuiltInIdentifierAsType);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierAsType =
    const Code<Message Function(Token token)>(
        "BuiltInIdentifierAsType", templateBuiltInIdentifierAsType,
        analyzerCode: "EXPECTED_TYPE_NAME", dart2jsCode: "EXTRANEOUS_MODIFIER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierAsType(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierAsType,
      message: """Can't use '$lexeme' as a type.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeGeneratorReturnsValue = messageGeneratorReturnsValue;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageGeneratorReturnsValue = const MessageCode(
    "GeneratorReturnsValue",
    dart2jsCode: "*ignored*",
    message: r"""'sync*' and 'async*' can't return a value.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeListLiteralTypeArgumentMismatch =
    messageListLiteralTypeArgumentMismatch;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageListLiteralTypeArgumentMismatch = const MessageCode(
    "ListLiteralTypeArgumentMismatch",
    message: r"""Map literal requires two type arguments.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)> templateMethodNotFound =
    const Template<Message Function(String name)>(
        messageTemplate: r"""Method not found: '#name'.""",
        withArguments: _withArgumentsMethodNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeMethodNotFound =
    const Code<Message Function(String name)>(
  "MethodNotFound",
  templateMethodNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsMethodNotFound(String name) {
  return new Message(codeMethodNotFound,
      message: """Method not found: '$name'.""", arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Null> codeInternalProblemExtendingUnmodifiableScope =
    messageInternalProblemExtendingUnmodifiableScope;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const MessageCode messageInternalProblemExtendingUnmodifiableScope =
    const MessageCode("InternalProblemExtendingUnmodifiableScope",
        message: r"""Can't extend an unmodifiable scope.""");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(Token token)>
    templateBuiltInIdentifierInDeclaration =
    const Template<Message Function(Token token)>(
        messageTemplate: r"""Can't use '#lexeme' as a name here.""",
        withArguments: _withArgumentsBuiltInIdentifierInDeclaration);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(Token token)> codeBuiltInIdentifierInDeclaration =
    const Code<Message Function(Token token)>("BuiltInIdentifierInDeclaration",
        templateBuiltInIdentifierInDeclaration,
        dart2jsCode: "GENERIC");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsBuiltInIdentifierInDeclaration(Token token) {
  String lexeme = token.lexeme;
  return new Message(codeBuiltInIdentifierInDeclaration,
      message: """Can't use '$lexeme' as a name here.""",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<Message Function(String name)>
    templateRedirectionTargetNotFound =
    const Template<Message Function(String name)>(
        messageTemplate:
            r"""Redirection constructor target not found: '#name'""",
        withArguments: _withArgumentsRedirectionTargetNotFound);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String name)> codeRedirectionTargetNotFound =
    const Code<Message Function(String name)>(
  "RedirectionTargetNotFound",
  templateRedirectionTargetNotFound,
);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsRedirectionTargetNotFound(String name) {
  return new Message(codeRedirectionTargetNotFound,
      message: """Redirection constructor target not found: '$name'""",
      arguments: {'name': name});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Template<
    Message Function(
        String character,
        int
            codePoint)> templateNonAsciiIdentifier = const Template<
        Message Function(String character, int codePoint)>(
    messageTemplate:
        r"""The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.""",
    tipTemplate:
        r"""Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).""",
    withArguments: _withArgumentsNonAsciiIdentifier);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const Code<Message Function(String character, int codePoint)>
    codeNonAsciiIdentifier =
    const Code<Message Function(String character, int codePoint)>(
        "NonAsciiIdentifier", templateNonAsciiIdentifier,
        analyzerCode: "ILLEGAL_CHARACTER", dart2jsCode: "BAD_INPUT_CHARACTER");

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
Message _withArgumentsNonAsciiIdentifier(String character, int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new Message(codeNonAsciiIdentifier,
      message:
          """The non-ASCII character '$character' ($unicode) can't be used in identifiers, only in strings and comments.""",
      tip: """Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).""",
      arguments: {'character': character, 'codePoint': codePoint});
}
