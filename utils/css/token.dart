// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A single token in the Dart language.
 */
class Token {
  /** A member of [TokenKind] specifying what kind of token this is. */
  final int kind;

  /** The [SourceFile] this token came from. */
  final SourceFile source;

  /** The start and end indexes into the [SourceFile] of this [Token]. */
  final int start, end;

  Token(this.kind, this.source, this.start, this.end) {}

  Token.fake(this.kind, span)
    : this.source = span.file, this.start = span.start, this.end = span.end;

  /** Returns the source text corresponding to this [Token]. */
  String get text() {
    return source.text.substring(start, end);
  }

  /** Returns a pretty representation of this token for error messages. **/
  String toString() {
    var kindText = TokenKind.kindToString(kind);
    var actualText = text;
    if (kindText != actualText) {
      if (actualText.length > 10) {
        actualText = actualText.substring(0, 8) + '...';
      }
      return '$kindText($actualText)';
    } else {
      return kindText;
    }
  }

  /** Returns a [SourceSpan] representing the source location. */
  SourceSpan get span() {
    return new SourceSpan(source, start, end);
  }
}

/** A token containing a parsed literal value. */
class LiteralToken extends Token {
  var value;
  LiteralToken(kind, source, start, end, this.value)
      : super(kind, source, start, end);
}

/** A token containing error information. */
class ErrorToken extends Token {
  String message;
  ErrorToken(kind, source, start, end, this.message)
      : super(kind, source, start, end);
}
