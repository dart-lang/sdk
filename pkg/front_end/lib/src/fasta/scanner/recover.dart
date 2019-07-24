// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style licenset hat can be found in the LICENSE file.

library fasta.scanner.recover;

import '../../scanner/token.dart' show TokenType;

import '../fasta_codes.dart'
    show
        Code,
        codeAsciiControlCharacter,
        codeEncoding,
        codeExpectedHexDigit,
        codeMissingExponent,
        codeNonAsciiIdentifier,
        codeNonAsciiWhitespace,
        codeUnexpectedDollarInString,
        codeUnmatchedToken,
        codeUnterminatedComment,
        codeUnterminatedString;

import '../../scanner/token.dart' show Token;

import 'token.dart' show StringToken;

import 'error_token.dart' show NonAsciiIdentifierToken, ErrorToken;

/// Recover from errors in [tokens]. The original sources are provided as
/// [bytes]. [lineStarts] are the beginning character offsets of lines, and
/// must be updated if recovery is performed rewriting the original source
/// code.
Token scannerRecovery(List<int> bytes, Token tokens, List<int> lineStarts) {
  // See [Parser.reportErrorToken](../parser/src/parser.dart) for how
  // it currently handles lexical errors. In addition, notice how the parser
  // calls [handleInvalidExpression], [handleInvalidFunctionBody], and
  // [handleInvalidTypeReference] to allow the listener to recover its internal
  // state. See [package:compiler/src/parser/element_listener.dart] for an
  // example of how these events are used.
  //
  // In addition, the scanner will attempt a bit of recovery when braces don't
  // match up during brace grouping. For more details on brace grouping see
  // [AbstractScanner.discardBeginGroupUntil] and
  // [AbstractScanner.unmatchedBeginGroup].

  /// Tokens with errors.
  ErrorToken error;

  /// Used for appending to [error].
  ErrorToken errorTail;

  /// Tokens without errors.
  Token good;

  /// Used for appending to [good].
  Token goodTail;

  recoverIdentifier(NonAsciiIdentifierToken first) {
    throw "Internal error: Identifier error token should have been prepended";
  }

  recoverExponent() {
    throw "Internal error: Exponent error token should have been prepended";
  }

  recoverString() {
    throw "Internal error: String error token should have been prepended";
  }

  recoverHexDigit() {
    throw "Internal error: Hex digit error token should have been prepended";
  }

  recoverStringInterpolation() {
    throw "Internal error: Interpolation error token should have been prepended";
  }

  recoverComment() {
    throw "Internal error: Comment error token should have been prepended";
  }

  recoverUnmatched() {
    // TODO(ahe): Try to use top-level keywords (such as `class`, `typedef`,
    // and `enum`) and indentation to recover.
    throw "Internal error: Unmatched error token should have been prepended";
  }

  // All unmatched error tokens should have been prepended
  Token current = tokens;
  while (current is ErrorToken) {
    if (errorTail == null) {
      error = current;
    }
    errorTail = current;
    current = current.next;
  }

  for (; !current.isEof; current = current.next) {
    while (current is ErrorToken) {
      ErrorToken first = current;
      Token next = current;
      do {
        current = next;
        if (errorTail == null) {
          error = next;
        } else {
          errorTail.setNext(next);
        }
        errorTail = next;
        next = next.next;
      } while (next is ErrorToken && first.errorCode == next.errorCode);

      Code code = first.errorCode;
      if (code == codeEncoding ||
          code == codeNonAsciiWhitespace ||
          code == codeAsciiControlCharacter) {
        current = errorTail.next;
      } else if (code == codeNonAsciiIdentifier) {
        current = recoverIdentifier(first);
        assert(current.next != null);
      } else if (code == codeMissingExponent) {
        current = recoverExponent();
        assert(current.next != null);
      } else if (code == codeUnterminatedString) {
        current = recoverString();
        assert(current.next != null);
      } else if (code == codeExpectedHexDigit) {
        current = recoverHexDigit();
        assert(current.next != null);
      } else if (code == codeUnexpectedDollarInString) {
        current = recoverStringInterpolation();
        assert(current.next != null);
      } else if (code == codeUnterminatedComment) {
        current = recoverComment();
        assert(current.next != null);
      } else if (code == codeUnmatchedToken) {
        current = recoverUnmatched();
        assert(current.next != null);
      } else {
        current = errorTail.next;
      }
    }
    if (goodTail == null) {
      good = current;
    } else {
      goodTail.setNext(current);
    }
    goodTail = current;
  }

  if (error == null) {
    // All of the errors are in the scanner's error list.
    return tokens;
  }
  new Token.eof(-1).setNext(error);
  Token tail;
  if (good != null) {
    errorTail.setNext(good);
    tail = goodTail;
  } else {
    tail = errorTail;
  }
  if (!tail.isEof) tail.setNext(new Token.eof(tail.end));
  return error;
}

Token synthesizeToken(int charOffset, String value, TokenType type) {
  return new StringToken.fromString(type, value, charOffset);
}

Token skipToEof(Token token) {
  while (!token.isEof) {
    token = token.next;
  }
  return token;
}

String closeBraceFor(String openBrace) {
  return const {
    '(': ')',
    '[': ']',
    '{': '}',
    '<': '>',
    r'${': '}',
    '?.[': ']',
  }[openBrace];
}

String closeQuoteFor(String openQuote) {
  return const {
    '"': '"',
    "'": "'",
    '"""': '"""',
    "'''": "'''",
    'r"': '"',
    "r'": "'",
    'r"""': '"""',
    "r'''": "'''",
  }[openQuote];
}
