// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.error_kind;

enum ErrorKind {
  EmptyNamedParameterList,
  EmptyOptionalParameterList,
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
  InvalidInputCharacter,
  InvalidSyncModifier,
  InvalidVoid,
  MalformedStringLiteral,
  MissingExponent,
  PositionalParameterWithEquals,
  RequiredParameterWithDefault,
  UnexpectedToken,
  UnmatchedToken,
  UnsupportedPrefixPlus,
  UnterminatedComment,
  UnterminatedString,
  UnterminatedToken,

  Unspecified,
}
