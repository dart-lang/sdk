// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style licenset hat can be found in the LICENSE file.

library dart_scanner.error_token;

import '../../scanner/token.dart' show BeginToken, TokenType, TokenWithComment;

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
        codeUnterminatedString,
        codeUnterminatedToken;

import '../scanner.dart' show Token, unicodeReplacementCharacter;

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
abstract class ErrorToken extends TokenWithComment {
  ErrorToken(int offset) : super(TokenType.BAD_INPUT, offset, null);

  /// This is a token that wraps around an error message. Return 1
  /// instead of the size of the length of the error message.
  @override
  int get length => 1;

  String get lexeme => throw assertionMessage;

  String get assertionMessage;

  FastaCode get errorCode;

  int get character => null;

  String get start => null;

  int get endOffset => null;

  BeginToken get begin => null;

  @override
  Token copy() {
    throw 'unsupported operation';
  }
}

/// Represents an encoding error.
class EncodingErrorToken extends ErrorToken {
  EncodingErrorToken(int charOffset) : super(charOffset);

  String toString() => "EncodingErrorToken()";

  String get assertionMessage => "Unable to decode bytes as UTF-8.";

  FastaCode get errorCode => codeEncoding;
}

/// Represents a non-ASCII character outside a string or comment.
class NonAsciiIdentifierToken extends ErrorToken {
  final int character;

  NonAsciiIdentifierToken(this.character, int charOffset) : super(charOffset);

  String toString() => "NonAsciiIdentifierToken($character)";

  String get assertionMessage {
    String c = new String.fromCharCodes([character]);
    String hex = character.toRadixString(16);
    String padding = "0000".substring(hex.length);
    hex = "$padding$hex";
    return "The non-ASCII character '$c' (U+$hex) can't be used in identifiers,"
        " only in strings and comments.\n"
        "Try using an US-ASCII letter, a digit, '_' (an underscore),"
        " or '\$' (a dollar sign).";
  }

  FastaCode get errorCode => codeNonAsciiIdentifier;
}

/// Represents a non-ASCII whitespace outside a string or comment.
class NonAsciiWhitespaceToken extends ErrorToken {
  final int character;

  NonAsciiWhitespaceToken(this.character, int charOffset) : super(charOffset);

  String toString() => "NonAsciiWhitespaceToken($character)";

  String get assertionMessage {
    String hex = character.toRadixString(16);
    return "The non-ASCII space character U+$hex can only be used in strings "
        "and comments.";
  }

  FastaCode get errorCode => codeNonAsciiWhitespace;
}

/// Represents an ASCII control character outside a string or comment.
class AsciiControlCharacterToken extends ErrorToken {
  final int character;

  AsciiControlCharacterToken(this.character, int charOffset)
      : super(charOffset);

  String toString() => "AsciiControlCharacterToken($character)";

  String get assertionMessage {
    String hex = character.toRadixString(16);
    return "The control character U+$hex can only be used in strings and "
        "comments.";
  }

  FastaCode get errorCode => codeAsciiControlCharacter;
}

/// Represents an unterminated string.
class UnterminatedToken extends ErrorToken {
  final String start;
  final int endOffset;

  UnterminatedToken(this.start, int charOffset, this.endOffset)
      : super(charOffset);

  String toString() => "UnterminatedToken($start)";

  String get assertionMessage => "'$start' isn't terminated.";

  int get charCount => endOffset - charOffset;

  FastaCode get errorCode {
    switch (start) {
      case '1e':
        return codeMissingExponent;

      case '"':
      case "'":
      case '"""':
      case "'''":
      case 'r"':
      case "r'":
      case 'r"""':
      case "r'''":
        return codeUnterminatedString;

      case '0x':
        return codeExpectedHexDigit;

      case r'$':
        return codeUnexpectedDollarInString;

      case '/*':
        return codeUnterminatedComment;

      default:
        return codeUnterminatedToken;
    }
  }
}

/// Represents an open brace without a matching close brace.
///
/// In this case, brace means any of `(`, `{`, `[`, and `<`, parenthesis, curly
/// brace, square brace, and angle brace, respectively.
class UnmatchedToken extends ErrorToken {
  final BeginToken begin;

  UnmatchedToken(BeginToken begin)
      : this.begin = begin,
        super(begin.charOffset);

  String toString() => "UnmatchedToken(${begin.lexeme})";

  String get assertionMessage => "'$begin' isn't closed.";

  FastaCode get errorCode => codeUnmatchedToken;
}
