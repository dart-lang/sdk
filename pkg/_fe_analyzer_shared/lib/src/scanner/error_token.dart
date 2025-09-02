// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_scanner.error_token;

import '../messages/codes.dart'
    show
        Code,
        Message,
        codeEncoding,
        codeAsciiControlCharacter,
        codeNonAsciiIdentifier,
        codeNonAsciiWhitespace,
        codeUnmatchedToken,
        codeUnsupportedOperator,
        codeUnterminatedString;

import 'recover.dart' show closeBraceFor, closeQuoteFor;

import 'scanner.dart' show Token, unicodeReplacementCharacter;

import 'token.dart' show BeginToken, SimpleToken, TokenType;

ErrorToken buildUnexpectedCharacterToken(int character, int charOffset) {
  if (character < 0x1f) {
    return new AsciiControlCharacterToken(character, charOffset);
  }
  switch (character) {
    case unicodeReplacementCharacter:
      return new EncodingErrorToken(charOffset);

    /// See [General Punctuation]
    /// (http://www.unicode.org/charts/PDF/U2000.pdf).
    case 0x00A0: // No-break space.
    case 0x1680: // Ogham space mark.
    case 0x180E: // Mongolian vowel separator.
    case 0x2000: // En quad.
    case 0x2001: // Em quad.
    case 0x2002: // En space.
    case 0x2003: // Em space.
    case 0x2004: // Three-per-em space.
    case 0x2005: // Four-per-em space.
    case 0x2006: // Six-per-em space.
    case 0x2007: // Figure space.
    case 0x2008: // Punctuation space.
    case 0x2009: // Thin space.
    case 0x200A: // Hair space.
    case 0x200B: // Zero width space.
    case 0x2028: // Line separator.
    case 0x2029: // Paragraph separator.
    case 0x202F: // Narrow no-break space.
    case 0x205F: // Medium mathematical space.
    case 0x3000: // Ideographic space.
    case 0xFEFF: // Zero width no-break space.
      return new NonAsciiWhitespaceToken(character, charOffset);

    default:
      return new NonAsciiIdentifierToken(character, charOffset);
  }
}

/// Common superclass for all error tokens.
///
/// It's considered an implementation error to access [lexeme] of an
/// [ErrorToken].
abstract class ErrorToken extends SimpleToken {
  ErrorToken(int offset) : super(TokenType.BAD_INPUT, offset, null);

  /// This is a token that wraps around an error message. Return 1
  /// instead of the size of the length of the error message.
  @override
  int get length => 1;

  @override
  String get lexeme {
    String errorMsg = assertionMessage.problemMessage;

    // Attempt to include the location which is calling the parser
    // in an effort to debug https://github.com/dart-lang/sdk/issues/37528
    RegExp pattern = new RegExp('^#[0-9]* *Parser');
    List<String> traceLines = StackTrace.current.toString().split('\n');
    for (int index = traceLines.length - 2; index >= 0; --index) {
      String line = traceLines[index];
      if (line.startsWith(pattern)) {
        errorMsg = '$errorMsg - ${traceLines[index + 1]}';
        break;
      }
    }

    throw errorMsg;
  }

  Message get assertionMessage;

  Code get errorCode => assertionMessage.code;

  int? get character => null;

  String? get start => null;

  int? get endOffset => null;

  BeginToken? get begin => null;
}

/// Represents an encoding error.
class EncodingErrorToken extends ErrorToken {
  EncodingErrorToken(super.charOffset);

  @override
  String toString() => "EncodingErrorToken()";

  @override
  Message get assertionMessage => codeEncoding;
}

/// Represents a non-ASCII character outside a string or comment.
class NonAsciiIdentifierToken extends ErrorToken {
  @override
  final int character;

  NonAsciiIdentifierToken(this.character, int charOffset) : super(charOffset);

  @override
  String toString() => "NonAsciiIdentifierToken($character)";

  @override
  Message get assertionMessage => codeNonAsciiIdentifier.withArguments(
    new String.fromCharCodes([character]),
    character,
  );
}

/// Represents a non-ASCII whitespace outside a string or comment.
class NonAsciiWhitespaceToken extends ErrorToken {
  @override
  final int character;

  NonAsciiWhitespaceToken(this.character, int charOffset) : super(charOffset);

  @override
  String toString() => "NonAsciiWhitespaceToken($character)";

  @override
  Message get assertionMessage =>
      codeNonAsciiWhitespace.withArguments(character);
}

/// Represents an ASCII control character outside a string or comment.
class AsciiControlCharacterToken extends ErrorToken {
  @override
  final int character;

  AsciiControlCharacterToken(this.character, int charOffset)
    : super(charOffset);

  @override
  String toString() => "AsciiControlCharacterToken($character)";

  @override
  Message get assertionMessage =>
      codeAsciiControlCharacter.withArguments(character);
}

/// Denotes an operator that is not supported in the Dart language.
class UnsupportedOperator extends ErrorToken {
  Token token;

  UnsupportedOperator(this.token, int charOffset) : super(charOffset);

  @override
  Message get assertionMessage => codeUnsupportedOperator.withArguments(token);

  @override
  String toString() => "UnsupportedOperator(${token.lexeme})";
}

/// Represents an unterminated string.
class UnterminatedString extends ErrorToken {
  @override
  final String start;
  @override
  final int endOffset;

  UnterminatedString(this.start, int charOffset, this.endOffset)
    : super(charOffset);

  @override
  String toString() => "UnterminatedString($start)";

  @override
  int get charCount => endOffset - charOffset;

  @override
  int get length => charCount;

  @override
  Message get assertionMessage =>
      codeUnterminatedString.withArguments(start, closeQuoteFor(start));
}

/// Represents an unterminated token.
class UnterminatedToken extends ErrorToken {
  @override
  final Message assertionMessage;
  @override
  final int endOffset;

  UnterminatedToken(this.assertionMessage, int charOffset, this.endOffset)
    : super(charOffset);

  @override
  String toString() => "UnterminatedToken(${assertionMessage.code.name})";

  @override
  int get charCount => endOffset - charOffset;
}

/// Represents an open brace without a matching close brace.
///
/// In this case, brace means any of `(`, `{`, `[`, and `<`, parenthesis, curly
/// brace, square brace, and angle brace, respectively.
class UnmatchedToken extends ErrorToken {
  @override
  final BeginToken begin;

  UnmatchedToken(BeginToken begin)
    : this.begin = begin,
      super(begin.charOffset);

  @override
  String toString() => "UnmatchedToken(${begin.lexeme})";

  @override
  Message get assertionMessage =>
      codeUnmatchedToken.withArguments(closeBraceFor(begin.lexeme), begin);
}
