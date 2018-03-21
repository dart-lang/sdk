// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show SyntheticStringToken, Token, TokenType;

import '../fasta_codes.dart' as fasta;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import 'identifier_context.dart';

import 'parser.dart' show Parser;

import 'util.dart' show optional;

/// See [IdentifierContext].libraryName
class LibraryIdentifierContext extends IdentifierContext {
  const LibraryIdentifierContext()
      : super('libraryName', inLibraryOrPartOfDeclaration: true);

  const LibraryIdentifierContext.continuation()
      : super('libraryNameContinuation',
            inLibraryOrPartOfDeclaration: true, isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      Token next = identifier.next;
      if (optional('.', next) ||
          optional(';', next) ||
          !looksLikeStartOfNextDeclaration(identifier)) {
        return identifier;
      }
      // Although this is a valid library name, the library declaration
      // is invalid and this looks like the start of the next declaration.
      // In this situation, fall through to insert a synthetic library name.
    }
    if (optional('.', identifier) ||
        optional(';', identifier) ||
        looksLikeStartOfNextDeclaration(identifier)) {
      identifier = parser.insertSyntheticIdentifier(token, this,
          message: fasta.templateExpectedIdentifier.withArguments(identifier));
    } else {
      parser.reportRecoverableErrorWithToken(
          identifier, fasta.templateExpectedIdentifier);
      if (!identifier.isKeywordOrIdentifier) {
        // When in doubt, consume the token to ensure we make progress
        // but insert a synthetic identifier to satisfy listeners.
        identifier = insertSyntheticIdentifierAfter(identifier, parser);
      }
    }
    return identifier;
  }

  bool looksLikeStartOfNextDeclaration(Token token) =>
      token.isTopLevelKeyword ||
      optional('const', token) ||
      optional('get', token) ||
      optional('final', token) ||
      optional('set', token) ||
      optional('var', token) ||
      optional('void', token);
}

Token insertSyntheticIdentifierAfter(Token token, Parser parser) {
  Token identifier =
      new SyntheticStringToken(TokenType.IDENTIFIER, '', token.charOffset, 0);
  parser.rewriter.insertTokenAfter(token, identifier);
  return identifier;
}
