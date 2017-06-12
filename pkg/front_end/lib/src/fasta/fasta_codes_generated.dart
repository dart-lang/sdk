// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/_fasta/generate_messages.dart' to update.

part of fasta.codes;

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedClassBodyToSkip> codeExpectedClassBodyToSkip =
    const FastaCode<_ExpectedClassBodyToSkip>("ExpectedClassBodyToSkip",
        template: r"Expected a class body, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedClassBodyToSkip);

typedef FastaMessage _ExpectedClassBodyToSkip(
    Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedClassBodyToSkip(
    Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedClassBodyToSkip,
      message: "Expected a class body, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_StackOverflow> codeStackOverflow =
    const FastaCode<_StackOverflow>("StackOverflow",
        template: r"Stack overflow.",
        dart2jsCode: "GENERIC",
        format: _formatStackOverflow);

typedef FastaMessage _StackOverflow(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatStackOverflow(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeStackOverflow,
      message: "Stack overflow.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnexpectedToken> codeUnexpectedToken =
    const FastaCode<_UnexpectedToken>("UnexpectedToken",
        template: r"Unexpected token '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatUnexpectedToken);

typedef FastaMessage _UnexpectedToken(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnexpectedToken(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeUnexpectedToken,
      message: "Unexpected token '$lexeme'.", arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_AwaitAsIdentifier> codeAwaitAsIdentifier = const FastaCode<
        _AwaitAsIdentifier>("AwaitAsIdentifier",
    template:
        r"'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
    dart2jsCode: "FASTA_IGNORED",
    format: _formatAwaitAsIdentifier);

typedef FastaMessage _AwaitAsIdentifier(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAwaitAsIdentifier(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeAwaitAsIdentifier,
      message:
          "'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_FactoryNotSync> codeFactoryNotSync =
    const FastaCode<_FactoryNotSync>("FactoryNotSync",
        template: r"Factories can't use 'async', 'async*', or 'sync*'.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatFactoryNotSync);

typedef FastaMessage _FactoryNotSync(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatFactoryNotSync(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeFactoryNotSync,
      message: "Factories can't use 'async', 'async*', or 'sync*'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_YieldNotGenerator> codeYieldNotGenerator =
    const FastaCode<_YieldNotGenerator>("YieldNotGenerator",
        template: r"'yield' can only be used in 'sync*' or 'async*' methods.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatYieldNotGenerator);

typedef FastaMessage _YieldNotGenerator(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatYieldNotGenerator(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeYieldNotGenerator,
      message: "'yield' can only be used in 'sync*' or 'async*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_SetterNotSync> codeSetterNotSync =
    const FastaCode<_SetterNotSync>("SetterNotSync",
        template: r"Setters can't use 'async', 'async*', or 'sync*'.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatSetterNotSync);

typedef FastaMessage _SetterNotSync(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatSetterNotSync(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeSetterNotSync,
      message: "Setters can't use 'async', 'async*', or 'sync*'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_NonAsciiWhitespace> codeNonAsciiWhitespace = const FastaCode<
        _NonAsciiWhitespace>("NonAsciiWhitespace",
    template:
        r"The non-ASCII space character #unicode can only be used in strings and comments.",
    analyzerCode: "ILLEGAL_CHARACTER",
    dart2jsCode: "BAD_INPUT_CHARACTER",
    format: _formatNonAsciiWhitespace);

typedef FastaMessage _NonAsciiWhitespace(
    Uri uri, int charOffset, int codePoint);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatNonAsciiWhitespace(Uri uri, int charOffset, int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new FastaMessage(uri, charOffset, codeNonAsciiWhitespace,
      message:
          "The non-ASCII space character $unicode can only be used in strings and comments.",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedIdentifier> codeExpectedIdentifier =
    const FastaCode<_ExpectedIdentifier>("ExpectedIdentifier",
        template: r"'#lexeme' is a reserved word and can't be used here.",
        tip: r"Try using a different name.",
        dart2jsCode: "EXPECTED_IDENTIFIER",
        format: _formatExpectedIdentifier);

typedef FastaMessage _ExpectedIdentifier(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedIdentifier(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedIdentifier,
      message: "'$lexeme' is a reserved word and can't be used here.",
      tip: "Try using a different name.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedBlockToSkip> codeExpectedBlockToSkip =
    const FastaCode<_ExpectedBlockToSkip>("ExpectedBlockToSkip",
        template: r"Expected a function body or '=>'.",
        tip: r"Try adding {}.",
        dart2jsCode: "NATIVE_OR_BODY_EXPECTED",
        format: _formatExpectedBlockToSkip);

typedef FastaMessage _ExpectedBlockToSkip(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedBlockToSkip(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeExpectedBlockToSkip,
      message: "Expected a function body or '=>'.",
      tip: "Try adding {}.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<
        _RequiredParameterWithDefault> codeRequiredParameterWithDefault =
    const FastaCode<_RequiredParameterWithDefault>(
        "RequiredParameterWithDefault",
        template: r"Non-optional parameters can't have a default value.",
        tip:
            r"Try removing the default value or making the parameter optional.",
        dart2jsCode: "REQUIRED_PARAMETER_WITH_DEFAULT",
        format: _formatRequiredParameterWithDefault);

typedef FastaMessage _RequiredParameterWithDefault(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatRequiredParameterWithDefault(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeRequiredParameterWithDefault,
      message: "Non-optional parameters can't have a default value.",
      tip: "Try removing the default value or making the parameter optional.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_Unspecified> codeUnspecified = const FastaCode<_Unspecified>(
    "Unspecified",
    template: r"#string",
    dart2jsCode: "GENERIC",
    format: _formatUnspecified);

typedef FastaMessage _Unspecified(Uri uri, int charOffset, String string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnspecified(Uri uri, int charOffset, String string) {
  return new FastaMessage(uri, charOffset, codeUnspecified,
      message: "$string", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_MissingExponent> codeMissingExponent = const FastaCode<
        _MissingExponent>("MissingExponent",
    template:
        r"Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).",
    tip:
        r"Make sure there is an exponent, and remove any whitespace before it.",
    analyzerCode: "MISSING_DIGIT",
    dart2jsCode: "EXPONENT_MISSING",
    format: _formatMissingExponent);

typedef FastaMessage _MissingExponent(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatMissingExponent(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeMissingExponent,
      message:
          "Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).",
      tip:
          "Make sure there is an exponent, and remove any whitespace before it.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_PositionalParameterWithEquals>
    codePositionalParameterWithEquals =
    const FastaCode<_PositionalParameterWithEquals>(
        "PositionalParameterWithEquals",
        template:
            r"Positional optional parameters can't use ':' to specify a default value.",
        tip: r"Try replacing ':' with '='.",
        dart2jsCode: "POSITIONAL_PARAMETER_WITH_EQUALS",
        format: _formatPositionalParameterWithEquals);

typedef FastaMessage _PositionalParameterWithEquals(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatPositionalParameterWithEquals(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codePositionalParameterWithEquals,
      message:
          "Positional optional parameters can't use ':' to specify a default value.",
      tip: "Try replacing ':' with '='.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<
    _UnexpectedDollarInString> codeUnexpectedDollarInString = const FastaCode<
        _UnexpectedDollarInString>("UnexpectedDollarInString",
    template:
        r"A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).",
    tip: r"Try adding a backslash (\) to escape the '$'.",
    dart2jsCode: "MALFORMED_STRING_LITERAL",
    format: _formatUnexpectedDollarInString);

typedef FastaMessage _UnexpectedDollarInString(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnexpectedDollarInString(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeUnexpectedDollarInString,
      message:
          "A '\$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).",
      tip: "Try adding a backslash (\) to escape the '\$'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExtraneousModifier> codeExtraneousModifier =
    const FastaCode<_ExtraneousModifier>("ExtraneousModifier",
        template: r"Can't have modifier '#lexeme' here.",
        tip: r"Try removing '#lexeme'.",
        dart2jsCode: "EXTRANEOUS_MODIFIER",
        format: _formatExtraneousModifier);

typedef FastaMessage _ExtraneousModifier(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExtraneousModifier(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExtraneousModifier,
      message: "Can't have modifier '$lexeme' here.",
      tip: "Try removing '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_EmptyOptionalParameterList> codeEmptyOptionalParameterList =
    const FastaCode<_EmptyOptionalParameterList>("EmptyOptionalParameterList",
        template: r"Optional parameter lists cannot be empty.",
        tip: r"Try adding an optional parameter to the list.",
        dart2jsCode: "EMPTY_OPTIONAL_PARAMETER_LIST",
        format: _formatEmptyOptionalParameterList);

typedef FastaMessage _EmptyOptionalParameterList(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatEmptyOptionalParameterList(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeEmptyOptionalParameterList,
      message: "Optional parameter lists cannot be empty.",
      tip: "Try adding an optional parameter to the list.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnterminatedString> codeUnterminatedString =
    const FastaCode<_UnterminatedString>("UnterminatedString",
        template: r"String must end with #string.",
        analyzerCode: "UNTERMINATED_STRING_LITERAL",
        dart2jsCode: "UNTERMINATED_STRING",
        format: _formatUnterminatedString);

typedef FastaMessage _UnterminatedString(
    Uri uri, int charOffset, String string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnterminatedString(Uri uri, int charOffset, String string) {
  return new FastaMessage(uri, charOffset, codeUnterminatedString,
      message: "String must end with $string.", arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_AwaitNotAsync> codeAwaitNotAsync =
    const FastaCode<_AwaitNotAsync>("AwaitNotAsync",
        template: r"'await' can only be used in 'async' or 'async*' methods.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatAwaitNotAsync);

typedef FastaMessage _AwaitNotAsync(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAwaitNotAsync(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeAwaitNotAsync,
      message: "'await' can only be used in 'async' or 'async*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedFunctionBody> codeExpectedFunctionBody =
    const FastaCode<_ExpectedFunctionBody>("ExpectedFunctionBody",
        template: r"Expected a function body, but got '#lexeme'.",
        dart2jsCode: "NATIVE_OR_FATAL",
        format: _formatExpectedFunctionBody);

typedef FastaMessage _ExpectedFunctionBody(
    Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedFunctionBody(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedFunctionBody,
      message: "Expected a function body, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedHexDigit> codeExpectedHexDigit =
    const FastaCode<_ExpectedHexDigit>("ExpectedHexDigit",
        template: r"A hex digit (0-9 or A-F) must follow '0x'.",
        analyzerCode: "MISSING_HEX_DIGIT",
        dart2jsCode: "HEX_DIGIT_EXPECTED",
        format: _formatExpectedHexDigit);

typedef FastaMessage _ExpectedHexDigit(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedHexDigit(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeExpectedHexDigit,
      message: "A hex digit (0-9 or A-F) must follow '0x'.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_EmptyNamedParameterList> codeEmptyNamedParameterList =
    const FastaCode<_EmptyNamedParameterList>("EmptyNamedParameterList",
        template: r"Named parameter lists cannot be empty.",
        tip: r"Try adding a named parameter to the list.",
        dart2jsCode: "EMPTY_NAMED_PARAMETER_LIST",
        format: _formatEmptyNamedParameterList);

typedef FastaMessage _EmptyNamedParameterList(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatEmptyNamedParameterList(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeEmptyNamedParameterList,
      message: "Named parameter lists cannot be empty.",
      tip: "Try adding a named parameter to the list.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnsupportedPrefixPlus> codeUnsupportedPrefixPlus =
    const FastaCode<_UnsupportedPrefixPlus>("UnsupportedPrefixPlus",
        template: r"'+' is not a prefix operator. ",
        tip: r"Try removing '+'.",
        dart2jsCode: "UNSUPPORTED_PREFIX_PLUS",
        format: _formatUnsupportedPrefixPlus);

typedef FastaMessage _UnsupportedPrefixPlus(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnsupportedPrefixPlus(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeUnsupportedPrefixPlus,
      message: "'+' is not a prefix operator. ",
      tip: "Try removing '+'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedString> codeExpectedString =
    const FastaCode<_ExpectedString>("ExpectedString",
        template: r"Expected a String, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedString);

typedef FastaMessage _ExpectedString(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedString(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedString,
      message: "Expected a String, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_TypeAfterVar> codeTypeAfterVar =
    const FastaCode<_TypeAfterVar>("TypeAfterVar",
        template: r"Can't have both a type and 'var'.",
        tip: r"Try removing 'var.'",
        dart2jsCode: "EXTRANEOUS_MODIFIER",
        format: _formatTypeAfterVar);

typedef FastaMessage _TypeAfterVar(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatTypeAfterVar(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeTypeAfterVar,
      message: "Can't have both a type and 'var'.",
      tip: "Try removing 'var.'",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_AbstractNotSync> codeAbstractNotSync =
    const FastaCode<_AbstractNotSync>("AbstractNotSync",
        template: r"Abstract methods can't use 'async', 'async*', or 'sync*'.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatAbstractNotSync);

typedef FastaMessage _AbstractNotSync(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAbstractNotSync(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeAbstractNotSync,
      message: "Abstract methods can't use 'async', 'async*', or 'sync*'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedDeclaration> codeExpectedDeclaration =
    const FastaCode<_ExpectedDeclaration>("ExpectedDeclaration",
        template: r"Expected a declaration, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedDeclaration);

typedef FastaMessage _ExpectedDeclaration(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedDeclaration(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedDeclaration,
      message: "Expected a declaration, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<
    _AsciiControlCharacter> codeAsciiControlCharacter = const FastaCode<
        _AsciiControlCharacter>("AsciiControlCharacter",
    template:
        r"The control character #unicode can only be used in strings and comments.",
    dart2jsCode: "BAD_INPUT_CHARACTER",
    format: _formatAsciiControlCharacter);

typedef FastaMessage _AsciiControlCharacter(
    Uri uri, int charOffset, int codePoint);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAsciiControlCharacter(
    Uri uri, int charOffset, int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new FastaMessage(uri, charOffset, codeAsciiControlCharacter,
      message:
          "The control character $unicode can only be used in strings and comments.",
      arguments: {'codePoint': codePoint});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnmatchedToken> codeUnmatchedToken =
    const FastaCode<_UnmatchedToken>("UnmatchedToken",
        template: r"Can't find '#string' to match '#lexeme'.",
        dart2jsCode: "UNMATCHED_TOKEN",
        format: _formatUnmatchedToken);

typedef FastaMessage _UnmatchedToken(
    Uri uri, int charOffset, String string, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnmatchedToken(
    Uri uri, int charOffset, String string, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeUnmatchedToken,
      message: "Can't find '$string' to match '$lexeme'.",
      arguments: {'string': string, 'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_InvalidSyncModifier> codeInvalidSyncModifier =
    const FastaCode<_InvalidSyncModifier>("InvalidSyncModifier",
        template: r"Invalid modifier 'sync'.",
        tip: r"Try replacing 'sync' with 'sync*'.",
        dart2jsCode: "INVALID_SYNC_MODIFIER",
        format: _formatInvalidSyncModifier);

typedef FastaMessage _InvalidSyncModifier(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatInvalidSyncModifier(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeInvalidSyncModifier,
      message: "Invalid modifier 'sync'.",
      tip: "Try replacing 'sync' with 'sync*'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedOpenParens> codeExpectedOpenParens =
    const FastaCode<_ExpectedOpenParens>("ExpectedOpenParens",
        template: r"Expected '('.",
        dart2jsCode: "GENERIC",
        format: _formatExpectedOpenParens);

typedef FastaMessage _ExpectedOpenParens(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedOpenParens(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeExpectedOpenParens,
      message: "Expected '('.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnterminatedComment> codeUnterminatedComment =
    const FastaCode<_UnterminatedComment>("UnterminatedComment",
        template: r"Comment starting with '/*' must end with '*/'.",
        analyzerCode: "UNTERMINATED_MULTI_LINE_COMMENT",
        dart2jsCode: "UNTERMINATED_COMMENT",
        format: _formatUnterminatedComment);

typedef FastaMessage _UnterminatedComment(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnterminatedComment(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeUnterminatedComment,
      message: "Comment starting with '/*' must end with '*/'.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedClassBody> codeExpectedClassBody =
    const FastaCode<_ExpectedClassBody>("ExpectedClassBody",
        template: r"Expected a class body, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedClassBody);

typedef FastaMessage _ExpectedClassBody(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedClassBody(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedClassBody,
      message: "Expected a class body, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedExpression> codeExpectedExpression =
    const FastaCode<_ExpectedExpression>("ExpectedExpression",
        template: r"Expected an expression, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedExpression);

typedef FastaMessage _ExpectedExpression(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedExpression(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedExpression,
      message: "Expected an expression, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_InvalidAwaitFor> codeInvalidAwaitFor = const FastaCode<
        _InvalidAwaitFor>("InvalidAwaitFor",
    template:
        r"'await' is only supported in methods with an 'async' or 'async*' body modifier.",
    tip:
        r"Try adding 'async' or 'async*' to the method body or removing the 'await' keyword.",
    dart2jsCode: "INVALID_AWAIT_FOR",
    format: _formatInvalidAwaitFor);

typedef FastaMessage _InvalidAwaitFor(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatInvalidAwaitFor(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeInvalidAwaitFor,
      message:
          "'await' is only supported in methods with an 'async' or 'async*' body modifier.",
      tip:
          "Try adding 'async' or 'async*' to the method body or removing the 'await' keyword.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedType> codeExpectedType =
    const FastaCode<_ExpectedType>("ExpectedType",
        template: r"Expected a type, but got '#lexeme'.",
        dart2jsCode: "FASTA_FATAL",
        format: _formatExpectedType);

typedef FastaMessage _ExpectedType(Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedType(Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeExpectedType,
      message: "Expected a type, but got '$lexeme'.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_UnterminatedToken> codeUnterminatedToken =
    const FastaCode<_UnterminatedToken>("UnterminatedToken",
        template: r"Incomplete token.",
        dart2jsCode: "UNTERMINATED_TOKEN",
        format: _formatUnterminatedToken);

typedef FastaMessage _UnterminatedToken(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatUnterminatedToken(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeUnterminatedToken,
      message: "Incomplete token.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedButGot> codeExpectedButGot =
    const FastaCode<_ExpectedButGot>("ExpectedButGot",
        template: r"Expected '#string' before this.",
        tip: r"DONT_KNOW_HOW_TO_FIX,",
        dart2jsCode: "MISSING_TOKEN_BEFORE_THIS",
        format: _formatExpectedButGot);

typedef FastaMessage _ExpectedButGot(Uri uri, int charOffset, String string);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedButGot(Uri uri, int charOffset, String string) {
  return new FastaMessage(uri, charOffset, codeExpectedButGot,
      message: "Expected '$string' before this.",
      tip: "DONT_KNOW_HOW_TO_FIX,",
      arguments: {'string': string});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_AwaitForNotAsync> codeAwaitForNotAsync = const FastaCode<
        _AwaitForNotAsync>("AwaitForNotAsync",
    template:
        r"Asynchronous for-loop can only be used in 'async' or 'async*' methods.",
    dart2jsCode: "FASTA_IGNORED",
    format: _formatAwaitForNotAsync);

typedef FastaMessage _AwaitForNotAsync(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAwaitForNotAsync(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeAwaitForNotAsync,
      message:
          "Asynchronous for-loop can only be used in 'async' or 'async*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_Encoding> codeEncoding = const FastaCode<_Encoding>("Encoding",
    template: r"Unable to decode bytes as UTF-8.",
    dart2jsCode: "FASTA_FATAL",
    format: _formatEncoding);

typedef FastaMessage _Encoding(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatEncoding(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeEncoding,
      message: "Unable to decode bytes as UTF-8.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_AsyncAsIdentifier> codeAsyncAsIdentifier = const FastaCode<
        _AsyncAsIdentifier>("AsyncAsIdentifier",
    template:
        r"'async' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
    analyzerCode: "ASYNC_KEYWORD_USED_AS_IDENTIFIER",
    dart2jsCode: "GENERIC",
    format: _formatAsyncAsIdentifier);

typedef FastaMessage _AsyncAsIdentifier(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatAsyncAsIdentifier(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeAsyncAsIdentifier,
      message:
          "'async' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_YieldAsIdentifier> codeYieldAsIdentifier = const FastaCode<
        _YieldAsIdentifier>("YieldAsIdentifier",
    template:
        r"'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
    dart2jsCode: "FASTA_IGNORED",
    format: _formatYieldAsIdentifier);

typedef FastaMessage _YieldAsIdentifier(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatYieldAsIdentifier(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeYieldAsIdentifier,
      message:
          "'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_OnlyTry> codeOnlyTry = const FastaCode<_OnlyTry>("OnlyTry",
    template:
        r"Try block should be followed by 'on', 'catch', or 'finally' block.",
    tip: r"Did you forget to add a 'finally' block?",
    dart2jsCode: "FASTA_IGNORED",
    format: _formatOnlyTry);

typedef FastaMessage _OnlyTry(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatOnlyTry(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeOnlyTry,
      message:
          "Try block should be followed by 'on', 'catch', or 'finally' block.",
      tip: "Did you forget to add a 'finally' block?",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<
    _InvalidInlineFunctionType> codeInvalidInlineFunctionType = const FastaCode<
        _InvalidInlineFunctionType>("InvalidInlineFunctionType",
    template: r"Invalid inline function type.",
    tip:
        r"Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').",
    dart2jsCode: "INVALID_INLINE_FUNCTION_TYPE",
    format: _formatInvalidInlineFunctionType);

typedef FastaMessage _InvalidInlineFunctionType(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatInvalidInlineFunctionType(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeInvalidInlineFunctionType,
      message: "Invalid inline function type.",
      tip:
          "Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_ExpectedBody> codeExpectedBody =
    const FastaCode<_ExpectedBody>("ExpectedBody",
        template: r"Expected a function body or '=>'.",
        tip: r"Try adding {}.",
        dart2jsCode: "BODY_EXPECTED",
        format: _formatExpectedBody);

typedef FastaMessage _ExpectedBody(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatExpectedBody(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeExpectedBody,
      message: "Expected a function body or '=>'.",
      tip: "Try adding {}.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_TypeRequired> codeTypeRequired =
    const FastaCode<_TypeRequired>("TypeRequired",
        template: r"A type or modifier is required here.",
        tip: r"Try adding a type, 'var', 'const', or 'final'.",
        format: _formatTypeRequired);

typedef FastaMessage _TypeRequired(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatTypeRequired(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeTypeRequired,
      message: "A type or modifier is required here.",
      tip: "Try adding a type, 'var', 'const', or 'final'.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_InvalidVoid> codeInvalidVoid = const FastaCode<_InvalidVoid>(
    "InvalidVoid",
    template: r"Type 'void' can't be used here because it isn't a return type.",
    tip:
        r"Try removing 'void' keyword or replace it with 'var', 'final', or a type.",
    dart2jsCode: "VOID_NOT_ALLOWED",
    format: _formatInvalidVoid);

typedef FastaMessage _InvalidVoid(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatInvalidVoid(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeInvalidVoid,
      message: "Type 'void' can't be used here because it isn't a return type.",
      tip:
          "Try removing 'void' keyword or replace it with 'var', 'final', or a type.",
      arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_BuiltInIdentifierAsType> codeBuiltInIdentifierAsType =
    const FastaCode<_BuiltInIdentifierAsType>("BuiltInIdentifierAsType",
        template: r"Can't use '#lexeme' as a type.",
        dart2jsCode: "EXTRANEOUS_MODIFIER",
        format: _formatBuiltInIdentifierAsType);

typedef FastaMessage _BuiltInIdentifierAsType(
    Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatBuiltInIdentifierAsType(
    Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeBuiltInIdentifierAsType,
      message: "Can't use '$lexeme' as a type.", arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_GeneratorReturnsValue> codeGeneratorReturnsValue =
    const FastaCode<_GeneratorReturnsValue>("GeneratorReturnsValue",
        template: r"'sync*' and 'async*' can't return a value.",
        dart2jsCode: "FASTA_IGNORED",
        format: _formatGeneratorReturnsValue);

typedef FastaMessage _GeneratorReturnsValue(Uri uri, int charOffset);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatGeneratorReturnsValue(Uri uri, int charOffset) {
  return new FastaMessage(uri, charOffset, codeGeneratorReturnsValue,
      message: "'sync*' and 'async*' can't return a value.", arguments: {});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_BuiltInIdentifierInDeclaration>
    codeBuiltInIdentifierInDeclaration =
    const FastaCode<_BuiltInIdentifierInDeclaration>(
        "BuiltInIdentifierInDeclaration",
        template: r"Can't use '#lexeme' as a name here.",
        dart2jsCode: "GENERIC",
        format: _formatBuiltInIdentifierInDeclaration);

typedef FastaMessage _BuiltInIdentifierInDeclaration(
    Uri uri, int charOffset, Token token);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatBuiltInIdentifierInDeclaration(
    Uri uri, int charOffset, Token token) {
  String lexeme = token.lexeme;
  return new FastaMessage(uri, charOffset, codeBuiltInIdentifierInDeclaration,
      message: "Can't use '$lexeme' as a name here.",
      arguments: {'token': token});
}

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
const FastaCode<_NonAsciiIdentifier> codeNonAsciiIdentifier = const FastaCode<
        _NonAsciiIdentifier>("NonAsciiIdentifier",
    template:
        r"The non-ASCII character '#character' (#unicode) can't be used in identifiers, only in strings and comments.",
    tip:
        r"Try using an US-ASCII letter, a digit, '_' (an underscore), or '$' (a dollar sign).",
    analyzerCode: "ILLEGAL_CHARACTER",
    dart2jsCode: "BAD_INPUT_CHARACTER",
    format: _formatNonAsciiIdentifier);

typedef FastaMessage _NonAsciiIdentifier(
    Uri uri, int charOffset, String character, int codePoint);

// DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
FastaMessage _formatNonAsciiIdentifier(
    Uri uri, int charOffset, String character, int codePoint) {
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return new FastaMessage(uri, charOffset, codeNonAsciiIdentifier,
      message:
          "The non-ASCII character '$character' ($unicode) can't be used in identifiers, only in strings and comments.",
      tip: "Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).",
      arguments: {'character': character, 'codePoint': codePoint});
}
