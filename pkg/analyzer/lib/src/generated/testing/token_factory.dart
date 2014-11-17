// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.testing.token_factory;

import 'package:analyzer/src/generated/scanner.dart';

/**
 * The class `TokenFactory` defines utility methods that can be used to create tokens.
 */
class TokenFactory {
  static Token tokenFromKeyword(Keyword keyword) =>
      new KeywordToken(keyword, 0);

  static Token tokenFromString(String lexeme) =>
      new StringToken(TokenType.STRING, lexeme, 0);

  static Token tokenFromType(TokenType type) => new Token(type, 0);

  static Token tokenFromTypeAndString(TokenType type, String lexeme) =>
      new StringToken(type, lexeme, 0);
}
