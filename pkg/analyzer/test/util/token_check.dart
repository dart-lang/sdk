// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';

extension KeywordTokenExtension on CheckTarget<KeywordToken> {
  CheckTarget<Keyword> get keyword {
    return nest(
      value.keyword,
      (selected) => 'has keyword ${valueStr(selected)}',
    );
  }
}

extension TokenExtension on CheckTarget<Token> {
  void get isCloseParenthesis {
    type.isEqualTo(TokenType.CLOSE_PAREN);
  }

  void get isOpenParenthesis {
    type.isEqualTo(TokenType.OPEN_PAREN);
  }

  void get isSemicolon {
    type.isEqualTo(TokenType.SEMICOLON);
  }

  void get isSynthetic {
    if (value.isSynthetic) return;
    fail('Not synthetic');
  }

  CheckTarget<TokenType> get type {
    return nest(
      value.type,
      (selected) => 'has type ${valueStr(selected)}',
    );
  }
}

extension TokenQuestionExtension on CheckTarget<Token?> {
  CheckTarget<KeywordToken> get isKeyword {
    return isA<KeywordToken>();
  }

  void get isKeywordConst {
    isKeyword.keyword.isEqualTo(Keyword.CONST);
  }

  void get isKeywordSuper {
    isKeyword.keyword.isEqualTo(Keyword.SUPER);
  }

  void get isKeywordVar {
    isKeyword.keyword.isEqualTo(Keyword.VAR);
  }
}
