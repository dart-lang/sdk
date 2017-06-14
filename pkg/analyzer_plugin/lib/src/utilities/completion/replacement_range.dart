// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/**
 * Utility class for computing the code completion replacement range
 */
class ReplacementRange {
  int offset;
  int length;

  ReplacementRange(this.offset, this.length);

  factory ReplacementRange.compute(int requestOffset, CompletionTarget target) {
    bool isKeywordOrIdentifier(Token token) =>
        token.type.isKeyword || token.type == TokenType.IDENTIFIER;

    //TODO(danrubel) Ideally this needs to be pushed down into the contributors
    // but that implies that each suggestion can have a different
    // replacement offsent/length which would mean an API change

    var entity = target.entity;
    Token token = entity is AstNode ? entity.beginToken : entity;
    if (token != null && requestOffset < token.offset) {
      token = token.previous;
    }
    if (token != null) {
      if (requestOffset == token.offset && !isKeywordOrIdentifier(token)) {
        // If the insertion point is at the beginning of the current token
        // and the current token is not an identifier
        // then check the previous token to see if it should be replaced
        token = token.previous;
      }
      if (token != null && isKeywordOrIdentifier(token)) {
        if (token.offset <= requestOffset && requestOffset <= token.end) {
          // Replacement range for typical identifier completion
          return new ReplacementRange(token.offset, token.length);
        }
      }
      if (token is StringToken) {
        SimpleStringLiteral uri =
            astFactory.simpleStringLiteral(token, token.lexeme);
        Keyword keyword = token.previous?.keyword;
        if (keyword == Keyword.IMPORT ||
            keyword == Keyword.EXPORT ||
            keyword == Keyword.PART) {
          int start = uri.contentsOffset;
          var end = uri.contentsEnd;
          if (start <= requestOffset && requestOffset <= end) {
            // Replacement range for import URI
            return new ReplacementRange(start, end - start);
          }
        }
      }
    }
    return new ReplacementRange(requestOffset, 0);
  }
}
