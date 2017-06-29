// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style licenset hat can be found in the LICENSE file.

library fasta.scanner.recover;

import '../../scanner/token.dart' show TokenType;

import '../fasta_codes.dart'
    show
        FastaCode,
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
Token defaultRecoveryStrategy(
    List<int> bytes, Token tokens, List<int> lineStarts) {
  // See [Parser.reportErrorToken](../parser/src/parser.dart) for how
  // it currently handles lexical errors. In addition, notice how the parser
  // calls [handleInvalidExpression], [handleInvalidFunctionBody], and
  // [handleInvalidTypeReference] to allow the listener to recover its internal
  // state. See [package:compiler/src/parser/element_listener.dart] for an
  // example of how these events are used.
  //
  // In addition, the scanner will attempt a bit of recovery when braces don't
  // match up during brace grouping. See
  // [ArrayBasedScanner.discardBeginGroupUntil](array_based_scanner.dart). For
  // more details on brace grouping see
  // [AbstractScanner.unmatchedBeginGroup](abstract_scanner.dart).

  /// Tokens with errors.
  ErrorToken error;

  /// Used for appending to [error].
  ErrorToken errorTail;

  /// Tokens without errors.
  Token good;

  /// Used for appending to [good].
  Token goodTail;

  /// The previous token appended to [good]. Since tokens are single linked
  /// lists, this allows us to rewrite the current token without scanning all
  /// of [good]. This is supposed to be the token immediately before
  /// [goodTail], that is, `beforeGoodTail.next == goodTail`.
  Token beforeGoodTail;

  recoverIdentifier(NonAsciiIdentifierToken first) {
    List<int> codeUnits = <int>[];

    // True if the previous good token is an identifier and ends right where
    // [first] starts. This is the case for input like `blåbærgrød`. In this
    // case, the scanner produces this sequence of tokens:
    //
    //     [
    //        StringToken("bl"),
    //        NonAsciiIdentifierToken("å"),
    //        StringToken("b"),
    //        NonAsciiIdentifierToken("æ"),
    //        StringToken("rgr"),
    //        NonAsciiIdentifierToken("ø"),
    //        StringToken("d"),
    //        EOF,
    //     ]
    bool prepend = false;

    // True if following token is also an identifier that starts right where
    // [errorTail] ends. This is the case for "b" above.
    bool append = false;
    if (goodTail != null) {
      if (goodTail.type == TokenType.IDENTIFIER &&
          goodTail.charEnd == first.charOffset) {
        prepend = true;
      }
    }
    Token next = errorTail.next;
    if (next.type == TokenType.IDENTIFIER &&
        errorTail.charOffset + 1 == next.charOffset) {
      append = true;
    }
    if (prepend) {
      codeUnits.addAll(goodTail.lexeme.codeUnits);
    }
    NonAsciiIdentifierToken current = first;
    while (current != errorTail) {
      codeUnits.add(current.character);
      current = current.next;
    }
    codeUnits.add(errorTail.character);
    int charOffset = first.charOffset;
    if (prepend) {
      charOffset = goodTail.charOffset;
      if (beforeGoodTail == null) {
        // We're prepending the first good token, so the new token will become
        // the first good token.
        good = null;
        goodTail = null;
        beforeGoodTail = null;
      } else {
        goodTail = beforeGoodTail;
      }
    }
    if (append) {
      codeUnits.addAll(next.lexeme.codeUnits);
      next = next.next;
    }
    String value = new String.fromCharCodes(codeUnits);
    return synthesizeToken(charOffset, value, TokenType.IDENTIFIER)
      ..next = next;
  }

  recoverExponent() {
    return synthesizeToken(errorTail.charOffset, "NaN", TokenType.DOUBLE)
      ..next = errorTail.next;
  }

  recoverString() {
    return errorTail.next;
  }

  recoverHexDigit() {
    return synthesizeToken(errorTail.charOffset, "0", TokenType.INT)
      ..next = errorTail.next;
  }

  recoverStringInterpolation() {
    return errorTail.next;
  }

  recoverComment() {
    // TODO(ahe): Improve this.
    return skipToEof(errorTail);
  }

  recoverUnmatched() {
    // TODO(ahe): Try to use top-level keywords (such as `class`, `typedef`,
    // and `enum`) and indentation to recover.
    return errorTail.next;
  }

  for (Token current = tokens; !current.isEof; current = current.next) {
    while (current is ErrorToken) {
      ErrorToken first = current;
      Token next = current;
      do {
        current = next;
        if (errorTail == null) {
          error = next;
        } else {
          errorTail.next = next;
          next.previous = errorTail;
        }
        errorTail = next;
        next = next.next;
      } while (next is ErrorToken && first.errorCode == next.errorCode);

      FastaCode code = first.errorCode;
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
      goodTail.next = current;
      current.previous = goodTail;
    }
    beforeGoodTail = goodTail;
    goodTail = current;
  }

  error.previous = new Token.eof(-1)..next = error;
  Token tail;
  if (good != null) {
    errorTail.next = good;
    good.previous = errorTail;
    tail = goodTail;
  } else {
    tail = errorTail;
  }
  if (!tail.isEof) tail.next = new Token.eof(tail.end)..previous = tail;
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
  }[openBrace];
}
