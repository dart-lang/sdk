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

/// See [IdentifierContext].classOrNamedMixin
class ClassOrNamedMixinIdentifierContext extends IdentifierContext {
  const ClassOrNamedMixinIdentifierContext()
      : super('classOrNamedMixinDeclaration',
            inDeclaration: true, isBuiltInIdentifierAllowed: false);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.type.isPseudo) {
      return identifier;
    }

    if (looksLikeStartOfNextTopLevelDeclaration(identifier) ||
        isOneOfOrEof(
            identifier, const ['<', '{', 'extends', 'with', 'implements'])) {
      identifier = parser.insertSyntheticIdentifier(token, this,
          message: fasta.templateExpectedIdentifier.withArguments(identifier));
    } else if (identifier.type.isBuiltIn) {
      parser.reportRecoverableErrorWithToken(
          identifier, fasta.templateBuiltInIdentifierAsType);
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
}

/// See [IdentifierContext].dottedName
class DottedNameIdentifierContext extends IdentifierContext {
  const DottedNameIdentifierContext() : super('dottedName');

  const DottedNameIdentifierContext.continuation()
      : super('dottedNameContinuation', isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    const followingValues = const ['.', '==', ')'];

    if (identifier.isIdentifier) {
      // DottedNameIdentifierContext are only used in conditional import
      // expressions. Although some top level keywords such as `import` can be
      // used as identifiers, they are more likely the start of the next
      // directive or declaration.
      if (!identifier.isTopLevelKeyword ||
          isOneOfOrEof(identifier.next, followingValues)) {
        return identifier;
      }
    }

    if (looksLikeStartOfNextTopLevelDeclaration(identifier) ||
        isOneOfOrEof(identifier, followingValues)) {
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
}

/// See [IdentifierContext].expression
class ExpressionIdentifierContext extends IdentifierContext {
  const ExpressionIdentifierContext()
      : super('expression', isScopeReference: true);

  const ExpressionIdentifierContext.continuation()
      : super('expressionContinuation', isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      if (optional('await', identifier) && identifier.next.isIdentifier) {
        // Although the `await` can be used in an expression,
        // it is followed by another identifier which does not form
        // a valid expression. Report an error on the `await` token
        // rather than the token following it.
        parser.reportRecoverableErrorWithToken(
            identifier, fasta.templateUnexpectedToken);

        // TODO(danrubel) Consider a new listener event so that analyzer
        // can represent this as an await expression in a context that does
        // not allow await.
        return identifier.next;
      } else {
        checkAsyncAwaitYieldAsIdentifier(identifier, parser);
      }
      return identifier;
    }
    parser.reportRecoverableErrorWithToken(
        identifier, fasta.templateExpectedIdentifier);
    if (identifier.isKeywordOrIdentifier) {
      if (!isOneOfOrEof(identifier, const ['as', 'is'])) {
        return identifier;
      }
    } else if (!identifier.isOperator &&
        !isOneOfOrEof(identifier,
            const ['.', ',', '(', ')', '[', ']', '}', '?', ':', ';'])) {
      // When in doubt, consume the token to ensure we make progress
      token = identifier;
      identifier = token.next;
    }
    // Insert a synthetic identifier to satisfy listeners.
    return insertSyntheticIdentifierAfter(token, parser);
  }
}

class FieldDeclarationIdentifierContext extends IdentifierContext {
  const FieldDeclarationIdentifierContext()
      : super('fieldDeclaration', inDeclaration: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      return identifier;
    }
    // Recovery
    if (isOneOfOrEof(identifier, const [';', '=', ',', '}']) ||
        looksLikeStartOfNextClassMember(identifier)) {
      return parser.insertSyntheticIdentifier(token, this);
    } else if (!identifier.isKeywordOrIdentifier) {
      // When in doubt, consume the token to ensure we make progress
      // but insert a synthetic identifier to satisfy listeners.
      return parser.insertSyntheticIdentifier(identifier, this,
          message: fasta.templateExpectedIdentifier.withArguments(identifier),
          messageOnToken: identifier);
    } else {
      parser.reportRecoverableErrorWithToken(
          identifier, fasta.templateExpectedIdentifier);
      return identifier;
    }
  }
}

/// See [IdentifierContext].fieldInitializer
class FieldInitializerIdentifierContext extends IdentifierContext {
  const FieldInitializerIdentifierContext()
      : super('fieldInitializer', isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    assert(optional('.', token));
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      return identifier;
    }
    parser.reportRecoverableErrorWithToken(
        identifier, fasta.templateExpectedIdentifier);
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
          !looksLikeStartOfNextTopLevelDeclaration(identifier)) {
        return identifier;
      }
      // Although this is a valid library name, the library declaration
      // is invalid and this looks like the start of the next declaration.
      // In this situation, fall through to insert a synthetic library name.
    }
    if (isOneOfOrEof(identifier, const ['.', ';']) ||
        looksLikeStartOfNextTopLevelDeclaration(identifier)) {
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
}

/// See [IdentifierContext].localVariableDeclaration
class LocalVariableDeclarationIdentifierContext extends IdentifierContext {
  const LocalVariableDeclarationIdentifierContext()
      : super('localVariableDeclaration', inDeclaration: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      checkAsyncAwaitYieldAsIdentifier(identifier, parser);
      return identifier;
    }
    if (isOneOfOrEof(identifier, const [';', '=', ',', '{', '}']) ||
        looksLikeStartOfNextStatement(identifier)) {
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
}

class MethodDeclarationIdentifierContext extends IdentifierContext {
  const MethodDeclarationIdentifierContext()
      : super('methodDeclaration', inDeclaration: true);

  const MethodDeclarationIdentifierContext.continuation()
      : super('methodDeclarationContinuation',
            inDeclaration: true, isContinuation: true);

  @override
  Token ensureIdentifier(Token token, Parser parser) {
    Token identifier = token.next;
    assert(identifier.kind != IDENTIFIER_TOKEN);
    if (identifier.isIdentifier) {
      return identifier;
    }
    // Recovery
    if (identifier.isUserDefinableOperator && !isContinuation) {
      return parser.insertSyntheticIdentifier(identifier, this,
          message: fasta.messageMissingOperatorKeyword,
          messageOnToken: identifier);
    } else if (isOneOfOrEof(identifier, const ['.', '(', '{', '=>']) ||
        looksLikeStartOfNextClassMember(identifier)) {
      return parser.insertSyntheticIdentifier(token, this);
    } else if (!identifier.isKeywordOrIdentifier) {
      // When in doubt, consume the token to ensure we make progress
      // but insert a synthetic identifier to satisfy listeners.
      return parser.insertSyntheticIdentifier(identifier, this,
          message: fasta.templateExpectedIdentifier.withArguments(identifier),
          messageOnToken: identifier);
    } else {
      parser.reportRecoverableErrorWithToken(
          identifier, fasta.templateExpectedIdentifier);
      return identifier;
    }
  }
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
      token = skipMetadata(next);
      next = token.next;
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

void checkAsyncAwaitYieldAsIdentifier(Token identifier, Parser parser) {
  if (!parser.inPlainSync && identifier.type.isPseudo) {
    if (optional('await', identifier)) {
      parser.reportRecoverableError(identifier, fasta.messageAwaitAsIdentifier);
    } else if (optional('yield', identifier)) {
      parser.reportRecoverableError(identifier, fasta.messageYieldAsIdentifier);
    } else if (optional('async', identifier)) {
      parser.reportRecoverableError(identifier, fasta.messageAsyncAsIdentifier);
    }
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

bool looksLikeStartOfNextClassMember(Token token) =>
    token.isModifier || isOneOfOrEof(token, const ['get', 'set', 'void']);

bool looksLikeStartOfNextStatement(Token token) => isOneOfOrEof(token, const [
      'assert',
      'break',
      'const',
      'continue',
      'do',
      'final',
      'for',
      'if',
      'return',
      'switch',
      'try',
      'var',
      'void',
      'while'
    ]);

bool looksLikeStartOfNextTopLevelDeclaration(Token token) =>
    token.isTopLevelKeyword ||
    isOneOfOrEof(token, const ['const', 'get', 'final', 'set', 'var', 'void']);

Token skipMetadata(Token token) {
  assert(optional('@', token));
  Token next = token.next;
  if (next.isIdentifier) {
    token = next;
    next = token.next;
    while (optional('.', next)) {
      token = next;
      next = token.next;
      if (next.isIdentifier) {
        token = next;
        next = token.next;
      }
    }
    if (optional('(', next)) {
      token = next.endGroup;
      next = token.next;
    }
  }
  return token;
}
