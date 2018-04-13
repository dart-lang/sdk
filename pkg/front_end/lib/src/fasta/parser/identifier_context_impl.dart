// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart' as fasta;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import 'identifier_context.dart';

import 'parser.dart' show Parser;

import 'type_info.dart'
    show insertSyntheticIdentifierAfter, isValidTypeReference;

import 'util.dart' show optional;

/// See [IdentifierContext].expression
class ExpressionIdentifierContext extends IdentifierContext {
  const ExpressionIdentifierContext()
      : super('expression', isScopeReference: true);

  const ExpressionIdentifierContext.continuation()
      : super('expressionContinuation', isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token next = token.next;
    assert(next.kind != IDENTIFIER_TOKEN);
    if (next.isIdentifier) {
      if (optional('await', next) && next.next.isIdentifier) {
        // Although the `await` can be used in an expression,
        // it is followed by another identifier which does not form
        // a valid expression. Report an error on the `await` token
        // rather than the token following it.
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateUnexpectedToken);

        // TODO(danrubel) Consider a new listener event so that analyzer
        // can represent this as an await expression in a context that does
        // not allow await.
        return next.next;
      } else if (!parser.inPlainSync && next.type.isPseudo) {
        if (optional('await', next)) {
          parser.reportRecoverableError(next, fasta.messageAwaitAsIdentifier);
        } else if (optional('yield', next)) {
          parser.reportRecoverableError(next, fasta.messageYieldAsIdentifier);
        } else if (optional('async', next)) {
          parser.reportRecoverableError(next, fasta.messageAsyncAsIdentifier);
        }
      }
      return next;
    }
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateExpectedIdentifier);
    if (next.isKeywordOrIdentifier) {
      if (!isOneOfOrEof(next, ['as', 'is'])) {
        return next;
      }
    } else if (!next.isOperator &&
        !isOneOfOrEof(
            next, const ['.', ',', '(', ')', '[', ']', '}', '?', ':', ';'])) {
      // When in doubt, consume the token to ensure we make progress
      token = next;
      next = token.next;
    }
    // Insert a synthetic identifier to satisfy listeners.
    return insertSyntheticIdentifierAfter(token, parser);
  }
}

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
      if (isOneOfOrEof(next, const ['.', ';']) ||
          !looksLikeStartOfNextDeclaration(identifier)) {
        return identifier;
      }
      // Although this is a valid library name, the library declaration
      // is invalid and this looks like the start of the next declaration.
      // In this situation, fall through to insert a synthetic library name.
    }
    if (isOneOfOrEof(identifier, const ['.', ';']) ||
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

/// See [IdentifierContext].typeReference
class TypeReferenceIdentifierContext extends IdentifierContext {
  const TypeReferenceIdentifierContext()
      : super('typeReference',
            isScopeReference: true,
            isBuiltInIdentifierAllowed: false,
            recoveryTemplate: fasta.templateExpectedType);

  const TypeReferenceIdentifierContext.continuation()
      : super('typeReferenceContinuation',
            isContinuation: true, isBuiltInIdentifierAllowed: false);

  const TypeReferenceIdentifierContext.prefixed()
      : super('prefixedTypeReference',
            isScopeReference: true,
            isBuiltInIdentifierAllowed: true,
            recoveryTemplate: fasta.templateExpectedType);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token next = token.next;
    assert(next.kind != IDENTIFIER_TOKEN);
    if (isValidTypeReference(next)) {
      return next;
    }

    // Recovery: skip over any annotations
    while (optional('@', next)) {
      // TODO(danrubel): Improve this error message to indicate that an
      // annotation is not allowed before type arguments.
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateUnexpectedToken);

      Token annotation = next.next;
      if (annotation.isIdentifier) {
        if (optional('(', annotation.next)) {
          if (annotation.next.endGroup.next.isIdentifier) {
            token = annotation.next.endGroup;
            next = token.next;
          }
        } else if (annotation.next.isIdentifier) {
          token = annotation;
          next = token.next;
        }
      }
    }
    if (isValidTypeReference(next)) {
      return next;
    } else if (next.isKeywordOrIdentifier) {
      if (optional("void", next)) {
        parser.reportRecoverableError(next, fasta.messageInvalidVoid);
      } else if (next.type.isBuiltIn) {
        if (!isBuiltInIdentifierAllowed) {
          parser.reportRecoverableErrorWithToken(
              next, fasta.templateBuiltInIdentifierAsType);
        }
      } else {
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExpectedType);
      }
      return next;
    }
    parser.reportRecoverableErrorWithToken(next, fasta.templateExpectedType);
    if (!isOneOfOrEof(next, const ['>', ')', ']', '{', '}', ',', ';'])) {
      // When in doubt, consume the token to ensure we make progress
      token = next;
      next = token.next;
    }
    // Insert a synthetic identifier to satisfy listeners.
    return insertSyntheticIdentifierAfter(token, parser);
  }
}

bool isOneOfOrEof(Token token, Iterable<String> followingValues) {
  for (String tokenValue in followingValues) {
    if (optional(tokenValue, token)) {
      return true;
    }
  }
  return token.isEof;
}
