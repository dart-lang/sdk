// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/front_end/messages.yaml' and run
// 'pkg/front_end/tool/_fasta/generate_messages.dart' to update.

library fasta.problems;

import 'package:front_end/src/fasta/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/parser/error_kind.dart' show ErrorKind;

problemExpectedClassBodyToSkip(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a class body, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedClassBodyToSkip,
    'arguments': {
      'token': token,
    },
  };
}

problemStackOverflow() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Stack overflow.",
  
    'code': ErrorKind.StackOverflow,
    'arguments': {
      
    },
  };
}

problemUnexpectedToken(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Unexpected token '$lexeme'.",
  
    'code': ErrorKind.UnexpectedToken,
    'arguments': {
      'token': token,
    },
  };
}

problemAwaitAsIdentifier() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
  
    'code': ErrorKind.AwaitAsIdentifier,
    'arguments': {
      
    },
  };
}

problemFactoryNotSync() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Factories can't use 'async', 'async*', or 'sync*'.",
  
    'code': ErrorKind.FactoryNotSync,
    'arguments': {
      
    },
  };
}

problemYieldNotGenerator() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'yield' can only be used in 'sync*' or 'async*' methods.",
  
    'code': ErrorKind.YieldNotGenerator,
    'arguments': {
      
    },
  };
}

problemSetterNotSync() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Setters can't use 'async', 'async*', or 'sync*'.",
  
    'code': ErrorKind.SetterNotSync,
    'arguments': {
      
    },
  };
}

problemNonAsciiWhitespace(int codePoint) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return {
    'message': "The non-ASCII space character $unicode can only be used in strings and comments.",
  
    'code': ErrorKind.NonAsciiWhitespace,
    'arguments': {
      'codePoint': codePoint,
    },
  };
}

problemExpectedIdentifier(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "'$lexeme' is a reserved word and can't be used here.",
    'tip': "Try using a different name.",
    'code': ErrorKind.ExpectedIdentifier,
    'arguments': {
      'token': token,
    },
  };
}

problemExpectedBlockToSkip() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Expected a function body or '=>'.",
    'tip': "Try adding {}.",
    'code': ErrorKind.ExpectedBlockToSkip,
    'arguments': {
      
    },
  };
}

problemRequiredParameterWithDefault() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Non-optional parameters can't have a default value.",
    'tip': "Try removing the default value or making the parameter optional.",
    'code': ErrorKind.RequiredParameterWithDefault,
    'arguments': {
      
    },
  };
}

problemUnspecified() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "$string",
  
    'code': ErrorKind.Unspecified,
    'arguments': {
      
    },
  };
}

problemMissingExponent() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Numbers in exponential notation should always contain an exponent (an integer number with an optional sign).",
    'tip': "Make sure there is an exponent, and remove any whitespace before it.",
    'code': ErrorKind.MissingExponent,
    'arguments': {
      
    },
  };
}

problemPositionalParameterWithEquals() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Positional optional parameters can't use ':' to specify a default value.",
    'tip': "Try replacing ':' with '='.",
    'code': ErrorKind.PositionalParameterWithEquals,
    'arguments': {
      
    },
  };
}

problemUnexpectedDollarInString() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "A '\$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).",
    'tip': "Try adding a backslash (\) to escape the '\$'.",
    'code': ErrorKind.UnexpectedDollarInString,
    'arguments': {
      
    },
  };
}

problemExtraneousModifier(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Can't have modifier '$lexeme' here.",
    'tip': "Try removing '$lexeme'.",
    'code': ErrorKind.ExtraneousModifier,
    'arguments': {
      'token': token,
    },
  };
}

problemEmptyOptionalParameterList() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Optional parameter lists cannot be empty.",
    'tip': "Try adding an optional parameter to the list.",
    'code': ErrorKind.EmptyOptionalParameterList,
    'arguments': {
      
    },
  };
}

problemUnterminatedString(String string) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "String must end with $string.",
  
    'code': ErrorKind.UnterminatedString,
    'arguments': {
      'string': string,
    },
  };
}

problemAwaitNotAsync() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'await' can only be used in 'async' or 'async*' methods.",
  
    'code': ErrorKind.AwaitNotAsync,
    'arguments': {
      
    },
  };
}

problemExpectedFunctionBody(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a function body, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedFunctionBody,
    'arguments': {
      'token': token,
    },
  };
}

problemExpectedHexDigit() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "A hex digit (0-9 or A-F) must follow '0x'.",
  
    'code': ErrorKind.ExpectedHexDigit,
    'arguments': {
      
    },
  };
}

problemEmptyNamedParameterList() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Named parameter lists cannot be empty.",
    'tip': "Try adding a named parameter to the list.",
    'code': ErrorKind.EmptyNamedParameterList,
    'arguments': {
      
    },
  };
}

problemUnsupportedPrefixPlus() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'+' is not a prefix operator. ",
    'tip': "Try removing '+'.",
    'code': ErrorKind.UnsupportedPrefixPlus,
    'arguments': {
      
    },
  };
}

problemExpectedString(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a String, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedString,
    'arguments': {
      'token': token,
    },
  };
}

problemAbstractNotSync() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Abstract methods can't use 'async', 'async*', or 'sync*'.",
  
    'code': ErrorKind.AbstractNotSync,
    'arguments': {
      
    },
  };
}

problemExpectedDeclaration(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a declaration, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedDeclaration,
    'arguments': {
      'token': token,
    },
  };
}

problemAsciiControlCharacter(int codePoint) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return {
    'message': "The control character $unicode can only be used in strings and comments.",
  
    'code': ErrorKind.AsciiControlCharacter,
    'arguments': {
      'codePoint': codePoint,
    },
  };
}

problemUnmatchedToken(String string, Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Can't find '$string' to match '$lexeme'.",
  
    'code': ErrorKind.UnmatchedToken,
    'arguments': {
      'string': string,
      'token': token,
    },
  };
}

problemInvalidSyncModifier() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Invalid modifier 'sync'.",
    'tip': "Try replacing 'sync' with 'sync*'.",
    'code': ErrorKind.InvalidSyncModifier,
    'arguments': {
      
    },
  };
}

problemExpectedOpenParens() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Expected '('.",
  
    'code': ErrorKind.ExpectedOpenParens,
    'arguments': {
      
    },
  };
}

problemUnterminatedComment() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Comment starting with '/*' must end with '*/'.",
  
    'code': ErrorKind.UnterminatedComment,
    'arguments': {
      
    },
  };
}

problemExpectedClassBody(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a class body, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedClassBody,
    'arguments': {
      'token': token,
    },
  };
}

problemExpectedExpression(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected an expression, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedExpression,
    'arguments': {
      'token': token,
    },
  };
}

problemInvalidAwaitFor() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'await' is only supported in methods with an 'async' or 'async*' body modifier.",
    'tip': "Try adding 'async' or 'async*' to the method body or removing the 'await' keyword.",
    'code': ErrorKind.InvalidAwaitFor,
    'arguments': {
      
    },
  };
}

problemExpectedType(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected a type, but got '$lexeme'.",
  
    'code': ErrorKind.ExpectedType,
    'arguments': {
      'token': token,
    },
  };
}

problemUnterminatedToken() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Incomplete token.",
  
    'code': ErrorKind.UnterminatedToken,
    'arguments': {
      
    },
  };
}

problemExpectedButGot(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Expected '$lexeme' before this.",
    'tip': "DONT_KNOW_HOW_TO_FIX,",
    'code': ErrorKind.ExpectedButGot,
    'arguments': {
      'token': token,
    },
  };
}

problemAwaitForNotAsync() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Asynchronous for-loop can only be used in 'async' or 'async*' methods.",
  
    'code': ErrorKind.AwaitForNotAsync,
    'arguments': {
      
    },
  };
}

problemEncoding() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Unable to decode bytes as UTF-8.",
  
    'code': ErrorKind.Encoding,
    'arguments': {
      
    },
  };
}

problemAsyncAsIdentifier() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'async' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
  
    'code': ErrorKind.AsyncAsIdentifier,
    'arguments': {
      
    },
  };
}

problemYieldAsIdentifier() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'yield' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.",
  
    'code': ErrorKind.YieldAsIdentifier,
    'arguments': {
      
    },
  };
}

problemInvalidInlineFunctionType() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Invalid inline function type.",
    'tip': "Try changing the inline function type (as in 'int f()') to a prefixed function type using the `Function` keyword (as in 'int Function() f').",
    'code': ErrorKind.InvalidInlineFunctionType,
    'arguments': {
      
    },
  };
}

problemExpectedBody() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Expected a function body or '=>'.",
    'tip': "Try adding {}.",
    'code': ErrorKind.ExpectedBody,
    'arguments': {
      
    },
  };
}

problemInvalidVoid() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "Type 'void' can't be used here because it isn't a return type.",
    'tip': "Try removing 'void' keyword or replace it with 'var', 'final', or a type.",
    'code': ErrorKind.InvalidVoid,
    'arguments': {
      
    },
  };
}

problemBuiltInIdentifierAsType(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Can't use '$lexeme' as a type.",
  
    'code': ErrorKind.BuiltInIdentifierAsType,
    'arguments': {
      'token': token,
    },
  };
}

problemGeneratorReturnsValue() {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  
  return {
    'message': "'sync*' and 'async*' can't return a value.",
  
    'code': ErrorKind.GeneratorReturnsValue,
    'arguments': {
      
    },
  };
}

problemBuiltInIdentifierInDeclaration(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Can't use '$lexeme' as a name here.",
  
    'code': ErrorKind.BuiltInIdentifierInDeclaration,
    'arguments': {
      'token': token,
    },
  };
}

problemNonAsciiIdentifier(String character, int codePoint) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String unicode = "(U+${codePoint.toRadixString(16).padLeft(4, '0')})";
  return {
    'message': "The non-ASCII character '$character' ($unicode) can't be used in identifiers, only in strings and comments.",
    'tip': "Try using an US-ASCII letter, a digit, '_' (an underscore), or '\$' (a dollar sign).",
    'code': ErrorKind.NonAsciiIdentifier,
    'arguments': {
      'character': character,
      'codePoint': codePoint,
    },
  };
}

problemExtraneousModifierReplace(Token token) {
  // DO NOT EDIT. THIS FILE IS GENERATED. SEE TOP OF FILE.
  String lexeme = token.lexeme;
  return {
    'message': "Can't have modifier '$lexeme' here.",
    'tip': "Try replacing modifier '$lexeme' with 'var', 'final', or a type.",
    'code': ErrorKind.ExtraneousModifierReplace,
    'arguments': {
      'token': token,
    },
  };
}

