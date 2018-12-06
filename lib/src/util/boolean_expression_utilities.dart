// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/token.dart';

class BooleanExpressionUtilities {
  static HashSet<TokenType> BOOLEAN_OPERATIONS = new HashSet.from(
      const [TokenType.AMPERSAND_AMPERSAND, TokenType.BAR_BAR]);

  static HashSet<TokenType> EQUALITY_OPERATIONS =
      new HashSet.from(const [TokenType.EQ_EQ, TokenType.BANG_EQ]);

  static HashMap<TokenType, TokenType> IMPLICATIONS = new HashMap.from(const {
    TokenType.GT: TokenType.GT_EQ,
    TokenType.LT: TokenType.LT_EQ,
  });

  static HashMap<TokenType, TokenType> NEGATIONS = new HashMap.from(const {
    TokenType.EQ_EQ: TokenType.BANG_EQ,
    TokenType.BANG_EQ: TokenType.EQ_EQ,
    TokenType.GT: TokenType.LT_EQ,
    TokenType.GT_EQ: TokenType.LT,
    TokenType.LT: TokenType.GT_EQ,
    TokenType.LT_EQ: TokenType.GT,
  });

  static HashSet<TokenType> TRICHOTOMY_OPERATORS =
      new HashSet.from(const [TokenType.EQ_EQ, TokenType.LT, TokenType.GT]);

  static final HashSet<TokenType> COMPARISONS =
      new HashSet.from(NEGATIONS.keys);
}
