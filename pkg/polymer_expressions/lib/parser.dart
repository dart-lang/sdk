// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.parser;

import 'tokenizer.dart';
export 'tokenizer.dart' show ParseException;
import 'expression.dart';

const _UNARY_OPERATORS = const <String>['+', '-', '!'];
const _BINARY_OPERATORS = const <String>['+', '-', '*', '/', '%', '^', '==',
    '!=', '>', '<', '>=', '<=', '||', '&&', '&', '===', '!==', '|'];

Expression parse(String expr) => new Parser(expr).parse();

class Parser {
  final AstFactory _astFactory;
  final Tokenizer _tokenizer;
  List<Token> _tokens;
  Iterator _iterator;
  Token get _token => _iterator.current;

  Parser(String input, {AstFactory astFactory})
      : _tokenizer = new Tokenizer(input),
        _astFactory = (astFactory == null) ? new AstFactory() : astFactory;

  Expression parse() {
    _tokens = _tokenizer.tokenize();
    _iterator = _tokens.iterator;
    _advance();
    return _parseExpression();
  }

  _advance([int kind, String value]) {
    if ((kind != null && (_token == null || _token.kind != kind))
        || (value != null && (_token == null || _token.value != value))) {
      throw new ParseException("Expected kind $kind ($value): $_token");
    }
    _iterator.moveNext();
  }

  Expression _parseExpression() {
    if (_token == null) return _astFactory.empty();
    var expr = _parseUnary();
    return (expr == null) ? null : _parsePrecedence(expr, 0);
  }

  // _parsePrecedence and _parseBinary implement the precedence climbing
  // algorithm as described in:
  // http://en.wikipedia.org/wiki/Operator-precedence_parser#Precedence_climbing_method
  Expression _parsePrecedence(Expression left, int precedence) {
    assert(left != null);
    while (_token != null) {
      if (_token.kind == GROUPER_TOKEN) {
        if (_token.value == '(') {
          var args = _parseArguments();
          assert(args != null);
          left = _astFactory.invoke(left, null, args);
        } else if (_token.value == '[') {
          var indexExpr = _parseIndex();
          left = _astFactory.index(left, indexExpr);
        } else {
          break;
        }
      } else if (_token.kind == DOT_TOKEN) {
        _advance();
        var right = _parseUnary();
        left = _makeInvokeOrGetter(left, right);
      } else if (_token.kind == KEYWORD_TOKEN) {
        if (_token.value == 'in') {
          left = _parseInExpression(left);
        } else if (_token.value == 'as') {
          left = _parseAsExpression(left);
        } else {
          break;
        }
      } else if (_token.kind == OPERATOR_TOKEN
          && _token.precedence >= precedence) {
        left = _token.value == '?' ? _parseTernary(left) : _parseBinary(left);
      } else {
        break;
      }
    }
    return left;
  }

  // invoke or getter
  Expression _makeInvokeOrGetter(left, right) {
    if (right is Identifier) {
      return _astFactory.getter(left, right.value);
    } else if (right is Invoke && right.receiver is Identifier) {
      Identifier method = right.receiver;
      return _astFactory.invoke(left, method.value, right.arguments);
    } else {
      throw new ParseException("expected identifier: $right");
    }
  }

  Expression _parseBinary(left) {
    var op = _token;
    if (!_BINARY_OPERATORS.contains(op.value)) {
      throw new ParseException("unknown operator: ${op.value}");
    }
    _advance();
    var right = _parseUnary();
    while (_token != null
        && (_token.kind == OPERATOR_TOKEN
        || _token.kind == DOT_TOKEN
        || _token.kind == GROUPER_TOKEN)
        && _token.precedence > op.precedence) {
      right = _parsePrecedence(right, _token.precedence);
    }
    return _astFactory.binary(left, op.value, right);
  }

  Expression _parseUnary() {
    if (_token.kind == OPERATOR_TOKEN) {
      var value = _token.value;
      if (value == '+' || value == '-') {
        _advance();
        if (_token.kind == INTEGER_TOKEN) {
          return _parseInteger(value);
        } else if (_token.kind == DECIMAL_TOKEN) {
          return _parseDecimal(value);
        } else {
          var expr = _parsePrecedence(_parsePrimary(), POSTFIX_PRECEDENCE);
          return _astFactory.unary(value, expr);
        }
      } else if (value == '!') {
        _advance();
        var expr = _parsePrecedence(_parsePrimary(), POSTFIX_PRECEDENCE);
        return _astFactory.unary(value, expr);
      } else {
        throw new ParseException("unexpected token: $value");
      }
    }
    return _parsePrimary();
  }

  Expression _parseTernary(condition) {
    _advance(OPERATOR_TOKEN, '?');
    var trueExpr = _parseExpression();
    _advance(COLON_TOKEN);
    var falseExpr = _parseExpression();
    return _astFactory.ternary(condition, trueExpr, falseExpr);
  }

  Expression _parsePrimary() {
    var kind = _token.kind;
    switch (kind) {
      case KEYWORD_TOKEN:
        var keyword = _token.value;
        if (keyword == 'this') {
          _advance();
          // TODO(justin): return keyword node
          return _astFactory.identifier('this');
        } else if (KEYWORDS.contains(keyword)) {
          throw new ParseException('unexpected keyword: $keyword');
        }
        throw new ParseException('unrecognized keyword: $keyword');
      case IDENTIFIER_TOKEN:
        return _parseInvokeOrIdentifier();
      case STRING_TOKEN:
        return _parseString();
      case INTEGER_TOKEN:
        return _parseInteger();
      case DECIMAL_TOKEN:
        return _parseDecimal();
      case GROUPER_TOKEN:
        if (_token.value == '(') {
          return _parseParenthesized();
        } else if (_token.value == '{') {
          return _parseMapLiteral();
        } else if (_token.value == '[') {
          return _parseListLiteral();
        }
        return null;
      case COLON_TOKEN:
        throw new ParseException('unexpected token ":"');
      default:
        return null;
    }
  }

  ListLiteral _parseListLiteral() {
    var items = [];
    do {
      _advance();
      if (_token.kind == GROUPER_TOKEN && _token.value == ']') {
        break;
      }
      items.add(_parseExpression());
    } while(_token != null && _token.value == ',');
    _advance(GROUPER_TOKEN, ']');
    return new ListLiteral(items);
  }

  MapLiteral _parseMapLiteral() {
    var entries = [];
    do {
      _advance();
      if (_token.kind == GROUPER_TOKEN && _token.value == '}') {
        break;
      }
      entries.add(_parseMapLiteralEntry());
    } while(_token != null && _token.value == ',');
    _advance(GROUPER_TOKEN, '}');
    return new MapLiteral(entries);
  }

  MapLiteralEntry _parseMapLiteralEntry() {
    var key = _parseString();
    _advance(COLON_TOKEN, ':');
    var value = _parseExpression();
    return _astFactory.mapLiteralEntry(key, value);
  }

  InExpression _parseInExpression(Expression left) {
    assert(_token.value == 'in');
    if (left is! Identifier) {
      throw new ParseException(
          "in... statements must start with an identifier");
    }
    _advance();
    var right = _parseExpression();
    return _astFactory.inExpr(left, right);
  }

  AsExpression _parseAsExpression(Expression left) {
    assert(_token.value == 'as');
    _advance();
    var right = _parseExpression();
    if (right is! Identifier) {
      throw new ParseException(
          "'as' statements must end with an identifier");
    }
    return _astFactory.asExpr(left, right);
  }

  Expression _parseInvokeOrIdentifier() {
    if (_token.value == 'true') {
      _advance();
      return _astFactory.literal(true);
    }
    if (_token.value == 'false') {
      _advance();
      return _astFactory.literal(false);
    }
    if (_token.value == 'null') {
      _advance();
      return _astFactory.literal(null);
    }
    var identifier = _parseIdentifier();
    var args = _parseArguments();
    if (args == null) {
      return identifier;
    } else {
      return _astFactory.invoke(identifier, null, args);
    }
  }

  Identifier _parseIdentifier() {
    if (_token.kind != IDENTIFIER_TOKEN) {
      throw new ParseException("expected identifier: $_token.value");
    }
    var value = _token.value;
    _advance();
    return _astFactory.identifier(value);
  }

  List<Expression> _parseArguments() {
    if (_token != null && _token.kind == GROUPER_TOKEN && _token.value == '(') {
      var args = [];
      do {
        _advance();
        if (_token.kind == GROUPER_TOKEN && _token.value == ')') {
          break;
        }
        var expr = _parseExpression();
        args.add(expr);
      } while(_token != null && _token.value == ',');
      _advance(GROUPER_TOKEN, ')');
      return args;
    }
    return null;
  }

  Expression _parseIndex() {
    if (_token != null && _token.kind == GROUPER_TOKEN && _token.value == '[') {
      _advance();
      var expr = _parseExpression();
      _advance(GROUPER_TOKEN, ']');
      return expr;
    }
    return null;
  }

  ParenthesizedExpression _parseParenthesized() {
    _advance();
    var expr = _parseExpression();
    _advance(GROUPER_TOKEN, ')');
    return _astFactory.parenthesized(expr);
  }

  Literal<String> _parseString() {
    var value = _astFactory.literal(_token.value);
    _advance();
    return value;
  }

  Literal<int> _parseInteger([String prefix = '']) {
    var value = _astFactory.literal(int.parse('$prefix${_token.value}'));
    _advance();
    return value;
  }

  Literal<double> _parseDecimal([String prefix = '']) {
    var value = _astFactory.literal(double.parse('$prefix${_token.value}'));
    _advance();
    return value;
  }

}
