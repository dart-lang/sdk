// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokensTest);
  });
}

@reflectiveTest
class TokensTest {
  /// Names in serialized ASTs keep their token types, and in recovered code
  /// any token can be a name, so every token type must be serializable.
  void test_tokenType_roundTrip() {
    var tokenTypes = <TokenType>[
      ...TokenType.all,
      ...Keyword.values,
      TokenType.BAD_INPUT,
      TokenType.RECOVERY,
    ];
    for (var tokenType in tokenTypes) {
      var binaryType = TokensWriter.astToBinaryTokenType(tokenType);
      expect(
        TokensContext.binaryToAstTokenType(binaryType),
        same(tokenType),
        reason: tokenType.name,
      );
    }
  }
}
