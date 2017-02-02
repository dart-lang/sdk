// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.error_kind;

enum ErrorKind {
  AsciiControlCharacter,
  EmptyNamedParameterList,
  EmptyOptionalParameterList,
  Encoding,
  ExpectedBlockToSkip,
  ExpectedBody,
  ExpectedButGot,
  ExpectedClassBody,
  ExpectedClassBodyToSkip,
  ExpectedDeclaration,
  ExpectedExpression,
  ExpectedFunctionBody,
  ExpectedHexDigit,
  ExpectedIdentifier,
  ExpectedOpenParens,
  ExpectedString,
  ExpectedType,
  ExtraneousModifier,
  ExtraneousModifierReplace,
  InvalidAwaitFor,
  InvalidSyncModifier,
  InvalidVoid,
  MissingExponent,
  NonAsciiIdentifier,
  NonAsciiWhitespace,
  PositionalParameterWithEquals,
  RequiredParameterWithDefault,
  StackOverflow,
  UnexpectedDollarInString,
  UnexpectedToken,
  UnmatchedToken,
  UnsupportedPrefixPlus,
  UnterminatedComment,
  UnterminatedString,
  UnterminatedToken,

  Unspecified,
}
