// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constants and predicates used for encoding and decoding type recipes.
///
/// This library is shared between the compiler and the runtime system.
library dart2js._recipe_syntax;

abstract class Recipe {
  Recipe._();

  // Operators.

  static const int separator = _comma;

  static const int toType = _semicolon;

  static const int pushDynamic = _at;
  static const int pushVoid = _tilde;

  static const int wrapStar = _asterisk;
  static const int wrapQuestion = _question;
  static const int wrapFutureOr = _slash;

  static const int startTypeArguments = _lessThan;
  static const int endTypeArguments = _greaterThan;

  static const int startFunctionArguments = _leftParen;
  static const int endFunctionArguments = _rightParen;
  static const int startOptionalGroup = _leftBracket;
  static const int endOptionalGroup = _rightBracket;
  static const int startNamedGroup = _leftBrace;
  static const int endNamedGroup = _rightBrace;
  static const int nameSeparator = _colon;

  static const int genericFunctionTypeParameterIndex = _circumflex;

  static const int extensionOp = _ampersand;
  static const int pushNeverExtension = 0;
  static const int pushAnyExtension = 1;

  // Number and name components.

  static bool isDigit(int code) => code >= _digit0 && code <= _digit9;
  static int digitValue(int code) => code - _digit0;

  static bool isIdentifierStart(int ch) =>
      (((ch | 32) - _lowercaseA) & 0xffff) < 26 ||
      (ch == _underscore) ||
      (ch == _dollar);

  static const int period = _period;

  // Private names.

  static const int _formfeed = 0x0C; // '\f' in string literal.

  static const int _space = 0x20;
  static const int _exclamation = 0x21;
  static const int _hash = 0x23;
  static const int _dollar = 0x24;
  static const int _percent = 0x25;
  static const int _ampersand = 0x26;
  static const int _apostrophe = 0x27;
  static const int _leftParen = 0x28;
  static const int _rightParen = 0x29;
  static const int _asterisk = 0x2A;
  static const int _plus = 0x2B;
  static const int _comma = 0x2C;
  static const int _minus = 0x2D;
  static const int _period = 0x2E;
  static const int _slash = 0x2F;

  static const int _digit0 = 0x30;
  static const int _digit9 = 0x39;

  static const int _colon = 0x3A;
  static const int _semicolon = 0x3B;
  static const int _lessThan = 0x3C;
  static const int _equals = 0x3D;
  static const int _greaterThan = 0x3E;
  static const int _question = 0x3F;
  static const int _at = 0x40;

  static const int _uppercaseA = 0x41;
  static const int _uppercaseZ = 0x5A;

  static const int _leftBracket = 0x5B;
  static const int _backslash = 0x5C;
  static const int _rightBracket = 0x5D;
  static const int _circumflex = 0x5E;
  static const int _underscore = 0x5F;
  static const int _backtick = 0x60;

  static const int _lowercaseA = 0x61;
  static const int _lowercaseZ = 0x7A;

  static const int _leftBrace = 0x7B;
  static const int _vertical = 0x7C;
  static const int _rightBrace = 0x7D;
  static const int _tilde = 0x7E;
}
