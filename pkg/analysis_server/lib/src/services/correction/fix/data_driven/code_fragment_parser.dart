// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analyzer/error/listener.dart';

/// A parser for the textual representation of a code fragment.
class CodeFragmentParser {
  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// The amount to be added to translate from offsets within the content to
  /// offsets within the file.
  int delta;

  /// The tokens being parsed.
  List<_Token> tokens;

  /// The accessors that have been parsed.
  List<Accessor> accessors = [];

  /// Initialize a newly created parser to report errors to the [errorReporter].
  CodeFragmentParser(this.errorReporter);

  /// Parse the [content] into a list of accessors. Add the [delta] to translate
  /// from offsets within the content to offsets within the file.
  ///
  /// <content> ::=
  ///   <accessor> ('.' <accessor>)*
  List<Accessor> parse(String content, int delta) {
    this.delta = delta;
    tokens = _CodeFragmentScanner(content, delta, errorReporter).scan();
    if (tokens == null) {
      // The error has already been reported.
      return null;
    }
    var index = _parseAccessor(0);
    while (index < tokens.length) {
      var token = tokens[index];
      if (token.kind == _TokenKind.period) {
        index = _parseAccessor(index + 1);
      } else {
        errorReporter.reportErrorForOffset(TransformSetErrorCode.wrongToken,
            token.offset + delta, token.length, ['.', token.kind.displayName]);
        return null;
      }
    }
    return accessors;
  }

  /// Return the token at the given [index] if it exists and if it has one of
  /// the [validKinds]. Report an error and return `null` if those conditions
  /// aren't met.
  _Token _expect(int index, List<_TokenKind> validKinds) {
    String validKindsDisplayString() {
      var buffer = StringBuffer();
      for (var i = 0; i < validKinds.length; i++) {
        if (i > 0) {
          if (i == validKinds.length - 1) {
            buffer.write(' or ');
          } else {
            buffer.write(', ');
          }
        }
        buffer.write(validKinds[i].displayName);
      }
      return buffer.toString();
    }

    if (index >= tokens.length) {
      var offset = 0;
      var length = 0;
      if (tokens.isNotEmpty) {
        var last = tokens.last;
        offset = last.offset;
        length = last.length;
      }
      errorReporter.reportErrorForOffset(TransformSetErrorCode.missingToken,
          offset + delta, length, [validKindsDisplayString()]);
      return null;
    }
    var token = tokens[index];
    if (!validKinds.contains(token.kind)) {
      errorReporter.reportErrorForOffset(
          TransformSetErrorCode.wrongToken,
          token.offset + delta,
          token.length,
          [validKindsDisplayString(), token.kind.displayName]);
      return null;
    }
    return token;
  }

  /// Parse an accessor.
  ///
  /// <accessor> ::=
  ///   <identifier> '[' (<integer> | <identifier>) ']'
  int _parseAccessor(int index) {
    var token = _expect(index, const [_TokenKind.identifier]);
    if (token == null) {
      // The error has already been reported.
      return tokens.length;
    }
    var identifier = token.lexeme;
    if (identifier == 'arguments') {
      token = _expect(index + 1, const [_TokenKind.openSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      token = _expect(index + 2, [_TokenKind.identifier, _TokenKind.integer]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      ParameterReference reference;
      if (token.kind == _TokenKind.identifier) {
        reference = NamedParameterReference(token.lexeme);
      } else {
        var argumentIndex = int.parse(token.lexeme);
        reference = PositionalParameterReference(argumentIndex);
      }
      token = _expect(index + 3, [_TokenKind.closeSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      accessors.add(ArgumentAccessor(reference));
      return index + 4;
    } else if (identifier == 'typeArguments') {
      token = _expect(index + 1, const [_TokenKind.openSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      token = _expect(index + 2, [_TokenKind.integer]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      var argumentIndex = int.parse(token.lexeme);
      token = _expect(index + 3, [_TokenKind.closeSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return tokens.length;
      }
      accessors.add(TypeArgumentAccessor(argumentIndex));
      return index + 4;
    } else {
      errorReporter.reportErrorForOffset(TransformSetErrorCode.unknownAccessor,
          token.offset, token.length, [identifier]);
      return tokens.length;
    }
  }
}

/// A scanner for the textual representation of a code fragment.
class _CodeFragmentScanner {
  static final int $0 = '0'.codeUnitAt(0);

  static final int $9 = '9'.codeUnitAt(0);

  static final int $a = 'a'.codeUnitAt(0);

  static final int $z = 'z'.codeUnitAt(0);

  static final int $A = 'A'.codeUnitAt(0);
  static final int $Z = 'Z'.codeUnitAt(0);
  static final int closeSquareBracket = ']'.codeUnitAt(0);
  static final int carriageReturn = '\r'.codeUnitAt(0);
  static final int newline = '\n'.codeUnitAt(0);
  static final int openSquareBracket = '['.codeUnitAt(0);
  static final int period = '.'.codeUnitAt(0);
  static final int space = ' '.codeUnitAt(0);

  /// The string being scanned.
  final String content;

  /// The length of the string being scanned.
  final int length;

  /// The offset in the file of the first character in the string being scanned.
  final int delta;

  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// Initialize a newly created scanner to scan the given [content].
  _CodeFragmentScanner(this.content, this.delta, this.errorReporter)
      : length = content.length;

  /// Return the tokens in the content, or `null` if there is an error in the
  /// content that prevents it from being scanned.
  List<_Token> scan() {
    if (content.isEmpty) {}
    var length = content.length;
    var offset = _skipWhitespace(0);
    var tokens = <_Token>[];
    while (offset < length) {
      var char = content.codeUnitAt(offset);
      if (char == closeSquareBracket) {
        tokens.add(_Token(offset, _TokenKind.closeSquareBracket, ']'));
        offset++;
      } else if (char == openSquareBracket) {
        tokens.add(_Token(offset, _TokenKind.openSquareBracket, '['));
        offset++;
      } else if (char == period) {
        tokens.add(_Token(offset, _TokenKind.period, '.'));
        offset++;
      } else if (_isLetter(char)) {
        var start = offset;
        offset++;
        while (offset < length && _isLetter(content.codeUnitAt(offset))) {
          offset++;
        }
        tokens.add(_Token(
            start, _TokenKind.identifier, content.substring(start, offset)));
      } else if (_isDigit(char)) {
        var start = offset;
        offset++;
        while (offset < length && _isDigit(content.codeUnitAt(offset))) {
          offset++;
        }
        tokens.add(_Token(
            start, _TokenKind.integer, content.substring(start, offset)));
      } else {
        errorReporter.reportErrorForOffset(
            TransformSetErrorCode.invalidCharacter,
            offset + delta,
            1,
            [content.substring(offset, offset + 1)]);
        return null;
      }
      offset = _skipWhitespace(offset);
    }
    return tokens;
  }

  /// Return `true` if the [char] is a digit.
  bool _isDigit(int char) => (char >= $0 && char <= $9);

  /// Return `true` if the [char] is a letter.
  bool _isLetter(int char) =>
      (char >= $a && char <= $z) || (char >= $A && char <= $Z);

  /// Return `true` if the [char] is a whitespace character.
  bool _isWhitespace(int char) =>
      char == space || char == newline || char == carriageReturn;

  /// Return the index of the first character at or after the given [offset]
  /// that isn't a whitespace character.
  int _skipWhitespace(int offset) {
    while (offset < length) {
      var char = content.codeUnitAt(offset);
      if (!_isWhitespace(char)) {
        return offset;
      }
      offset++;
    }
    return offset;
  }
}

/// A token in a code fragment's string representation.
class _Token {
  /// The offset of the token.
  final int offset;

  /// The kind of the token.
  final _TokenKind kind;

  /// The lexeme of the token.
  final String lexeme;

  /// Initialize a newly created token.
  _Token(this.offset, this.kind, this.lexeme);

  /// Return the length of this token.
  int get length => lexeme.length;
}

/// An indication of the kind of a token.
enum _TokenKind {
  closeSquareBracket,
  identifier,
  integer,
  openSquareBracket,
  period,
}

extension on _TokenKind {
  String get displayName {
    switch (this) {
      case _TokenKind.closeSquareBracket:
        return "']'";
      case _TokenKind.identifier:
        return 'an identifier';
      case _TokenKind.integer:
        return 'an integer';
      case _TokenKind.openSquareBracket:
        return "'['";
      case _TokenKind.period:
        return "'.'";
    }
    return '';
  }
}
