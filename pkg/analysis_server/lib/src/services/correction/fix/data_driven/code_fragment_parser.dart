// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/expression.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/variable_scope.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

// Several "report" functions intentionally return a `Null`-typed value.

/// A parser for the textual representation of a code fragment.
class CodeFragmentParser {
  /// The diagnostic reporter to which diagnostics will be reported.
  final DiagnosticReporter diagnosticReporter;

  /// The scope in which variables can be looked up.
  VariableScope variableScope;

  /// The amount to be added to translate from offsets within the content to
  /// offsets within the file.
  int delta = 0;

  /// The tokens being parsed.
  late List<_Token> _tokens;

  /// The index in the [_tokens] of the next token to be consumed.
  int currentIndex = 0;

  /// Initialize a newly created parser to report errors to the [diagnosticReporter].
  CodeFragmentParser(this.diagnosticReporter, {VariableScope? scope})
    : variableScope = scope ?? VariableScope(null, {});

  /// Return the current token, or `null` if the end of the tokens has been
  /// reached.
  _Token? get _currentToken =>
      currentIndex < _tokens.length ? _tokens[currentIndex] : null;

  /// Advance to the next token.
  void advance() {
    if (currentIndex < _tokens.length) {
      currentIndex++;
    }
  }

  /// Parse the [content] into a list of accessors. Add the [delta] to translate
  /// from offsets within the content to offsets within the file.
  ///
  /// <content> ::=
  ///   <accessor> ('.' <accessor>)*
  List<Accessor>? parseAccessors(String content, int delta) {
    this.delta = delta;
    var scannedTokens =
        _CodeFragmentScanner(content, delta, diagnosticReporter).scan();
    if (scannedTokens == null) {
      // The error has already been reported.
      return null;
    }
    _tokens = scannedTokens;
    currentIndex = 0;
    var accessors = <Accessor>[];
    var accessor = _parseAccessor();
    if (accessor == null) {
      return accessors;
    }
    accessors.add(accessor);
    while (currentIndex < _tokens.length) {
      var token = _currentToken;
      if (token == null) {
        return accessors;
      }
      if (token.kind == _TokenKind.period) {
        advance();
        accessor = _parseAccessor();
        if (accessor == null) {
          return accessors;
        }
        accessors.add(accessor);
      } else {
        diagnosticReporter.atOffset(
          offset: token.offset + delta,
          length: token.length,
          diagnosticCode: TransformSetErrorCode.wrongToken,
          arguments: ['.', token.kind.displayName],
        );
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
  Expression? parseCondition(String content, int delta) {
    this.delta = delta;
    var scannedTokens =
        _CodeFragmentScanner(content, delta, diagnosticReporter).scan();
    if (scannedTokens == null) {
      // The error has already been reported.
      return null;
    }
    _tokens = scannedTokens;
    currentIndex = 0;
    var expression = _parseLogicalAndExpression();
    if (currentIndex < _tokens.length) {
      var token = _tokens[currentIndex];
      diagnosticReporter.atOffset(
        offset: token.offset + delta,
        length: token.length,
        diagnosticCode: TransformSetErrorCode.unexpectedToken,
        arguments: [token.kind.displayName],
      );
      return null;
    }
    return expression;
  }

  /// Return the current token if it exists and has one of the [validKinds].
  /// Report an error and return `null` if those conditions aren't met.
  _Token? _expect(List<_TokenKind> validKinds) {
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

    var token = _currentToken;
    if (token == null) {
      var offset = 0;
      var length = 0;
      if (_tokens.isNotEmpty) {
        var last = _tokens.last;
        offset = last.offset;
        length = last.length;
      }
      diagnosticReporter.atOffset(
        offset: offset + delta,
        length: length,
        diagnosticCode: TransformSetErrorCode.missingToken,
        arguments: [validKindsDisplayString()],
      );
      return null;
    }
    if (!validKinds.contains(token.kind)) {
      diagnosticReporter.atOffset(
        offset: token.offset + delta,
        length: token.length,
        diagnosticCode: TransformSetErrorCode.wrongToken,
        arguments: [validKindsDisplayString(), token.kind.displayName],
      );
      return null;
    }
    return token;
  }

  /// Parse an accessor.
  ///
  /// <accessor> ::=
  ///   <identifier> '[' (<integer> | <identifier>) ']'
  Accessor? _parseAccessor() {
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
      FormalParameterReference reference;
      if (token.kind == _TokenKind.identifier) {
        reference = NamedFormalParameterReference(token.lexeme);
      } else {
        var argumentIndex = int.parse(token.lexeme);
        reference = PositionalFormalParameterReference(argumentIndex);
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
      diagnosticReporter.atOffset(
        offset: token.offset + delta,
        length: token.length,
        diagnosticCode: TransformSetErrorCode.unknownAccessor,
        arguments: [identifier],
      );
      return null;
    }
  }

  /// Parse a logical expression.
  ///
  /// <equalityExpression> ::=
  ///   <primaryExpression> (<comparisonOperator> <primaryExpression>)?
  /// <comparisonOperator> ::=
  ///   '==' | '!='
  Expression? _parseEqualityExpression() {
    var expression = _parsePrimaryExpression();
    if (expression == null) {
      return null;
    }
    if (currentIndex >= _tokens.length) {
      return expression;
    }
    var kind = _currentToken?.kind;
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
  Expression? _parseLogicalAndExpression() {
    var leftOperand = _parseEqualityExpression();
    if (leftOperand == null) {
      return null;
    }
    if (currentIndex >= _tokens.length) {
      return leftOperand;
    }
    var expression = leftOperand;
    var kind = _currentToken?.kind;
    while (kind == _TokenKind.and) {
      advance();
      var rightOperand = _parseEqualityExpression();
      if (rightOperand == null) {
        return null;
      }
      expression = BinaryExpression(expression, Operator.and, rightOperand);
      if (currentIndex >= _tokens.length) {
        return expression;
      }
      kind = _currentToken?.kind;
    }
    return expression;
  }

  /// Parse a logical expression.
  ///
  /// <primaryExpression> ::=
  ///   <identifier> | <string>
  Expression? _parsePrimaryExpression() {
    var token = _currentToken;
    if (token != null) {
      var kind = token.kind;
      if (kind == _TokenKind.identifier) {
        advance();
        var variableName = token.lexeme;
        var generator = variableScope.lookup(variableName);
        if (generator == null) {
          diagnosticReporter.atOffset(
            offset: token.offset + delta,
            length: token.length,
            diagnosticCode: TransformSetErrorCode.undefinedVariable,
            arguments: [variableName],
          );
          return null;
        }
        return VariableReference(generator);
      } else if (kind == _TokenKind.string) {
        advance();
        var lexeme = token.lexeme;
        var value = lexeme.substring(1, lexeme.length - 1);
        return LiteralString(value);
      }
    }
    int offset;
    int length;
    if (token == null) {
      if (_tokens.isNotEmpty) {
        token = _tokens[_tokens.length - 1];
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
    diagnosticReporter.atOffset(
      offset: offset,
      length: length,
      diagnosticCode: TransformSetErrorCode.expectedPrimary,
    );
    return null;
  }
}

/// A scanner for the textual representation of a code fragment.
class _CodeFragmentScanner {
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

  /// The diagnostic reporter to which diagnostics will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// Initialize a newly created scanner to scan the given [content].
  _CodeFragmentScanner(this.content, this.delta, this._diagnosticReporter)
    : length = content.length;

  /// Return the tokens in the content, or `null` if there is an error in the
  /// content that prevents it from being scanned.
  List<_Token>? scan() {
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
          _Token(start, _TokenKind.string, content.substring(start, offset)),
        );
      } else if (char.isLetter) {
        var start = offset;
        offset++;
        while (offset < length && content.codeUnitAt(offset).isLetter) {
          offset++;
        }
        tokens.add(
          _Token(
            start,
            _TokenKind.identifier,
            content.substring(start, offset),
          ),
        );
      } else if (char.isDigit) {
        var start = offset;
        offset++;
        while (offset < length && content.codeUnitAt(offset).isDigit) {
          offset++;
        }
        tokens.add(
          _Token(start, _TokenKind.integer, content.substring(start, offset)),
        );
      } else {
        return _reportInvalidCharacter(offset);
      }
      offset = _skipWhitespace(offset);
    }
    return tokens;
  }

  /// Return `true` if the [char] is a whitespace character.
  bool _isWhitespace(int char) =>
      char == space || char == newline || char == carriageReturn;

  /// Report the presence of an invalid character at the given [offset].
  Null _reportInvalidCharacter(int offset) {
    _diagnosticReporter.atOffset(
      offset: offset + delta,
      length: 1,
      diagnosticCode: TransformSetErrorCode.invalidCharacter,
      arguments: [content.substring(offset, offset + 1)],
    );
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
    return switch (this) {
      _TokenKind.and => "'&&'",
      _TokenKind.closeSquareBracket => "']'",
      _TokenKind.equal => "'=='",
      _TokenKind.identifier => 'an identifier',
      _TokenKind.integer => 'an integer',
      _TokenKind.notEqual => "'!='",
      _TokenKind.openSquareBracket => "'['",
      _TokenKind.period => "'.'",
      _TokenKind.string => 'a string',
    };
  }
}
