// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/expression.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/variable_scope.dart';
import 'package:analyzer/error/listener.dart';

/// A parser for the textual representation of a code fragment.
class CodeFragmentParser {
  /// The error reporter to which diagnostics will be reported.
  final ErrorReporter errorReporter;

  /// The scope in which variables can be looked up.
  VariableScope variableScope;

  /// The amount to be added to translate from offsets within the content to
  /// offsets within the file.
  int delta;

  /// The tokens being parsed.
  /* late */ List<_Token> tokens;

  /// The index in the [tokens] of the next token to be consumed.
  int currentIndex = 0;

  /// Initialize a newly created parser to report errors to the [errorReporter].
  CodeFragmentParser(this.errorReporter, {VariableScope scope})
      : variableScope = scope ?? VariableScope(null, {});

  /// Return the current token, or `null` if the end of the tokens has been
  /// reached.
  _Token get currentToken =>
      currentIndex < tokens.length ? tokens[currentIndex] : null;

  /// Advance to the next token.
  void advance() {
    if (currentIndex < tokens.length) {
      currentIndex++;
    }
  }

  /// Parse the [content] into a list of accessors. Add the [delta] to translate
  /// from offsets within the content to offsets within the file.
  ///
  /// <content> ::=
  ///   <accessor> ('.' <accessor>)*
  List<Accessor> parseAccessors(String content, int delta) {
    this.delta = delta;
    tokens = _CodeFragmentScanner(content, delta, errorReporter).scan();
    if (tokens == null) {
      // The error has already been reported.
      return null;
    }
    currentIndex = 0;
    var accessors = <Accessor>[];
    var accessor = _parseAccessor();
    if (accessor == null) {
      return accessors;
    }
    accessors.add(accessor);
    while (currentIndex < tokens.length) {
      var token = currentToken;
      if (token.kind == _TokenKind.period) {
        advance();
        accessor = _parseAccessor();
        if (accessor == null) {
          return accessors;
        }
        accessors.add(accessor);
      } else {
        errorReporter.reportErrorForOffset(TransformSetErrorCode.wrongToken,
            token.offset + delta, token.length, ['.', token.kind.displayName]);
        return null;
      }
    }
    return accessors;
  }

  /// Parse the [content] into a condition. Add the [delta] to translate
  /// from offsets within the content to offsets within the file.
  ///
  /// <content> ::=
  ///   <logicalExpression>
  Expression parseCondition(String content, int delta) {
    this.delta = delta;
    tokens = _CodeFragmentScanner(content, delta, errorReporter).scan();
    if (tokens == null) {
      // The error has already been reported.
      return null;
    }
    currentIndex = 0;
    var expression = _parseLogicalAndExpression();
    if (currentIndex < tokens.length) {
      var token = tokens[currentIndex];
      errorReporter.reportErrorForOffset(TransformSetErrorCode.unexpectedToken,
          token.offset + delta, token.length, [token.kind.displayName]);
      return null;
    }
    return expression;
  }

  /// Return the current token if it exists and has one of the [validKinds].
  /// Report an error and return `null` if those conditions aren't met.
  _Token _expect(List<_TokenKind> validKinds) {
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

    var token = currentToken;
    if (token == null) {
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
  Accessor _parseAccessor() {
    var token = _expect(const [_TokenKind.identifier]);
    if (token == null) {
      // The error has already been reported.
      return null;
    }
    var identifier = token.lexeme;
    if (identifier == 'arguments') {
      advance();
      token = _expect(const [_TokenKind.openSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      advance();
      token = _expect(const [_TokenKind.identifier, _TokenKind.integer]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      ParameterReference reference;
      if (token.kind == _TokenKind.identifier) {
        reference = NamedParameterReference(token.lexeme);
      } else {
        var argumentIndex = int.parse(token.lexeme);
        reference = PositionalParameterReference(argumentIndex);
      }
      advance();
      token = _expect(const [_TokenKind.closeSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      advance();
      return ArgumentAccessor(reference);
    } else if (identifier == 'typeArguments') {
      advance();
      token = _expect(const [_TokenKind.openSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      advance();
      token = _expect(const [_TokenKind.integer]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      advance();
      var argumentIndex = int.parse(token.lexeme);
      token = _expect(const [_TokenKind.closeSquareBracket]);
      if (token == null) {
        // The error has already been reported.
        return null;
      }
      advance();
      return TypeArgumentAccessor(argumentIndex);
    } else {
      errorReporter.reportErrorForOffset(TransformSetErrorCode.unknownAccessor,
          token.offset + delta, token.length, [identifier]);
      return null;
    }
  }

  /// Parse a logical expression.
  ///
  /// <equalityExpression> ::=
  ///   <primaryExpression> (<comparisonOperator> <primaryExpression>)?
  /// <comparisonOperator> ::=
  ///   '==' | '!='
  Expression _parseEqualityExpression() {
    var expression = _parsePrimaryExpression();
    if (expression == null) {
      return null;
    }
    if (currentIndex >= tokens.length) {
      return expression;
    }
    var kind = currentToken.kind;
    if (kind == _TokenKind.equal || kind == _TokenKind.notEqual) {
      advance();
      var operator =
          kind == _TokenKind.equal ? Operator.equal : Operator.notEqual;
      var rightOperand = _parsePrimaryExpression();
      if (rightOperand == null) {
        return null;
      }
      expression = BinaryExpression(expression, operator, rightOperand);
    }
    return expression;
  }

  /// Parse a logical expression.
  ///
  /// <logicalExpression> ::=
  ///   <equalityExpression> ('&&' <equalityExpression>)*
  Expression _parseLogicalAndExpression() {
    var expression = _parseEqualityExpression();
    if (expression == null) {
      return null;
    }
    if (currentIndex >= tokens.length) {
      return expression;
    }
    var kind = currentToken.kind;
    while (kind == _TokenKind.and) {
      advance();
      var rightOperand = _parseEqualityExpression();
      if (rightOperand == null) {
        return null;
      }
      expression = BinaryExpression(expression, Operator.and, rightOperand);
      if (currentIndex >= tokens.length) {
        return expression;
      }
      kind = currentToken.kind;
    }
    return expression;
  }

  /// Parse a logical expression.
  ///
  /// <primaryExpression> ::=
  ///   <identifier> | <string>
  Expression _parsePrimaryExpression() {
    var token = currentToken;
    var kind = token?.kind;
    if (kind == _TokenKind.identifier) {
      advance();
      var variableName = token.lexeme;
      var generator = variableScope.lookup(variableName);
      if (generator == null) {
        errorReporter.reportErrorForOffset(
            TransformSetErrorCode.undefinedVariable,
            token.offset + delta,
            token.length,
            [variableName]);
        return null;
      }
      return VariableReference(generator);
    } else if (kind == _TokenKind.string) {
      advance();
      var lexeme = token.lexeme;
      var value = lexeme.substring(1, lexeme.length - 1);
      return LiteralString(value);
    }
    int offset;
    int length;
    if (token == null) {
      if (tokens.isNotEmpty) {
        token = tokens[tokens.length - 1];
        offset = token.offset + delta;
        length = token.length;
      } else {
        offset = delta;
        length = 0;
      }
    } else {
      offset = token.offset + delta;
      length = token.length;
    }
    errorReporter.reportErrorForOffset(
        TransformSetErrorCode.expectedPrimary, offset, length);
    return null;
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

  static final int ampersand = '&'.codeUnitAt(0);
  static final int bang = '!'.codeUnitAt(0);
  static final int closeSquareBracket = ']'.codeUnitAt(0);
  static final int carriageReturn = '\r'.codeUnitAt(0);
  static final int equal = '='.codeUnitAt(0);
  static final int newline = '\n'.codeUnitAt(0);
  static final int openSquareBracket = '['.codeUnitAt(0);
  static final int period = '.'.codeUnitAt(0);
  static final int singleQuote = "'".codeUnitAt(0);
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
    var length = content.length;

    int peekAt(int offset) {
      if (offset > length) {
        return -1;
      }
      return content.codeUnitAt(offset);
    }

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
      } else if (char == ampersand) {
        if (peekAt(offset + 1) != ampersand) {
          return _reportInvalidCharacter(offset);
        }
        tokens.add(_Token(offset, _TokenKind.and, '&&'));
        offset += 2;
      } else if (char == bang) {
        if (peekAt(offset + 1) != equal) {
          return _reportInvalidCharacter(offset);
        }
        tokens.add(_Token(offset, _TokenKind.notEqual, '!='));
        offset += 2;
      } else if (char == equal) {
        if (peekAt(offset + 1) != equal) {
          return _reportInvalidCharacter(offset);
        }
        tokens.add(_Token(offset, _TokenKind.equal, '=='));
        offset += 2;
      } else if (char == singleQuote) {
        var start = offset;
        offset++;
        while (offset < length && content.codeUnitAt(offset) != singleQuote) {
          offset++;
        }
        offset++;
        tokens.add(
            _Token(start, _TokenKind.string, content.substring(start, offset)));
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
        return _reportInvalidCharacter(offset);
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

  /// Report the presence of an invalid character at the given [offset].
  Null _reportInvalidCharacter(int offset) {
    errorReporter.reportErrorForOffset(TransformSetErrorCode.invalidCharacter,
        offset + delta, 1, [content.substring(offset, offset + 1)]);
    return null;
  }

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
  and,
  closeSquareBracket,
  equal,
  identifier,
  integer,
  notEqual,
  openSquareBracket,
  period,
  string,
}

extension on _TokenKind {
  String get displayName {
    switch (this) {
      case _TokenKind.and:
        return "'&&'";
      case _TokenKind.closeSquareBracket:
        return "']'";
      case _TokenKind.equal:
        return "'=='";
      case _TokenKind.identifier:
        return 'an identifier';
      case _TokenKind.integer:
        return 'an integer';
      case _TokenKind.notEqual:
        return "'!='";
      case _TokenKind.openSquareBracket:
        return "'['";
      case _TokenKind.period:
        return "'.'";
      case _TokenKind.string:
        return 'a string';
    }
    return '';
  }
}
