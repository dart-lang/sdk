// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../environment.dart';

/// A parsed Boolean expression AST.
abstract class Expression {
  /// Parses Boolean expressions in a .status file for Dart.
  ///
  /// The grammar is:
  ///
  ///     expression := or
  ///     or         := and ( "||" and )*
  ///     and        := primary ( "&&" primary )*
  ///     primary    := "$" identifier ( "==" | "!=" ) identifier |
  ///                   "!"? "$" identifier |
  ///                   "(" expression ")"
  ///     identifier := regex "\w+"
  ///
  /// Expressions evaluate as expected, with values of variables found in an
  /// environment passed to the evaluator.
  static Expression parse(String expression) =>
      new _ExpressionParser(expression).parse();

  /// Validates that this expression does not contain any invalid uses of
  /// variables.
  ///
  /// Ensures that any variable names are known and that any literal values are
  /// allowed for their corresponding variable. If an invalid variable or value
  /// is found, adds appropriate error messages to [errors].
  void validate(Environment environment, List<String> errors);

  /// Evaluates the expression where all variables are defined by the given
  /// [environment].
  bool evaluate(Environment environment);
}

/// Keyword token strings.
class _Token {
  static const leftParen = "(";
  static const rightParen = ")";
  static const dollar = r"$";
  static const equals = "==";
  static const notEqual = "!=";
  static const and = "&&";
  static const or = "||";
  static const not = "!";
}

/// A reference to a variable.
class _Variable {
  final String name;

  _Variable(this.name);

  String lookup(Environment environment) {
    var value = environment.lookUp(name);
    if (value == null) {
      throw new Exception("Could not find '$name' in environment "
          "while evaluating status file expression.");
    }

    // Explicitly stringify all values so that things like:
    //
    //     $strong == true
    //
    // work correctly even though "true" is treated as a string here.
    // TODO(rnystrom): Is there a cleaner/safer way to do this?
    return value.toString();
  }
}

/// Tests whether a given variable is or is not equal some literal value, as in:
/// ```
/// $variable == someValue
/// ```
/// Negate the result if [negate] is true.
class _ComparisonExpression implements Expression {
  final _Variable left;
  final String right;
  final bool negate;

  _ComparisonExpression(this.left, this.right, this.negate);

  void validate(Environment environment, List<String> errors) {
    environment.validate(left.name, right, errors);
  }

  bool evaluate(Environment environment) {
    return negate != (left.lookup(environment) == right);
  }

  String toString() => "(\$${left.name} ${negate ? '!=' : '=='} $right)";
}

/// A reference to a variable defined in the environment. The expression
/// evaluates to true if the variable's stringified value is "true".
/// ```
///     $variable
/// ```
/// is equivalent to
/// ```
///     $variable == true
/// ```
/// Negates result if [negate] is true, so
/// ```
///     !$variable
/// ```
/// is equivalent to
/// ```
///     $variable != true
/// ```
class _VariableExpression implements Expression {
  final _Variable variable;
  final bool negate;

  _VariableExpression(this.variable, {this.negate = false});

  void validate(Environment environment, List<String> errors) {
    // It must be a Boolean, so it should allow either Boolean value.
    environment.validate(variable.name, "true", errors);
  }

  bool evaluate(Environment environment) =>
      negate != (variable.lookup(environment) == "true");

  String toString() => "(bool ${negate ? "! " : ""}\$${variable.name})";
}

/// A logical `||` or `&&` expression.
class _LogicExpression implements Expression {
  /// The operator, `||` or `&&`.
  final String op;

  final Expression left;
  final Expression right;

  _LogicExpression(this.op, this.left, this.right);

  void validate(Environment environment, List<String> errors) {
    left.validate(environment, errors);
    right.validate(environment, errors);
  }

  bool evaluate(Environment environment) => (op == _Token.and)
      ? left.evaluate(environment) && right.evaluate(environment)
      : left.evaluate(environment) || right.evaluate(environment);

  String toString() => "($left $op $right)";
}

/// Parser for Boolean expressions in a .status file for Dart.
class _ExpressionParser {
  final _Scanner _scanner;

  _ExpressionParser(String expression) : _scanner = new _Scanner(expression);

  Expression parse() {
    var expression = _parseOr();

    // Should consume entire string.
    if (_scanner.hasMore) {
      throw new FormatException("Unexpected input after expression");
    }

    return expression;
  }

  Expression _parseOr() {
    var left = _parseAnd();
    while (_scanner.match(_Token.or)) {
      var right = _parseAnd();
      left = new _LogicExpression(_Token.or, left, right);
    }

    return left;
  }

  Expression _parseAnd() {
    var left = _parsePrimary();
    while (_scanner.match(_Token.and)) {
      var right = _parsePrimary();
      left = new _LogicExpression(_Token.and, left, right);
    }

    return left;
  }

  Expression _parsePrimary() {
    if (_scanner.match(_Token.leftParen)) {
      var value = _parseOr();
      if (!_scanner.match(_Token.rightParen)) {
        throw new FormatException("Missing right parenthesis in expression");
      }

      return value;
    }

    var negate = false;
    if (_scanner.match(_Token.not)) {
      negate = true;
    }

    // The only atomic booleans are of the form $variable == value or
    // of the form $variable.
    if (!_scanner.match(_Token.dollar)) {
      throw new FormatException(
          "Expected \$ in expression, got ${_scanner.current}");
    }

    if (!_scanner.isIdentifier) {
      throw new FormatException(
          "Expected identifier in expression, got ${_scanner.current}");
    }

    var left = new _Variable(_scanner.current);
    _scanner.advance();

    if (!negate &&
        (_scanner.current == _Token.equals ||
            _scanner.current == _Token.notEqual)) {
      var isNotEquals = _scanner.advance() == _Token.notEqual;

      if (!_scanner.isIdentifier) {
        throw new FormatException(
            "Expected value in expression, got ${_scanner.current}");
      }

      var right = _scanner.advance();
      return new _ComparisonExpression(left, right, isNotEquals);
    } else {
      return new _VariableExpression(left, negate: negate);
    }
  }
}

/// An iterator that allows peeking at the current token.
class _Scanner {
  /// Tokens are "(", ")", "$", "&&", "||", "!", ==", "!=", and (maximal) \w+.
  static final _testPattern = new RegExp(r"^(?:[()$\w\s]|&&|\|\||==|!=?)+$");
  static final _tokenPattern = new RegExp(r"[()$]|&&|\|\||==|!=?|\w+");

  /// Pattern that recognizes identifier tokens.
  ///
  /// Only checks the first character, since no non-identifier token can start
  /// with a word character.
  static final _identifierPattern = new RegExp(r"^\w");

  /// The token strings being iterated.
  final Iterator<String> tokenIterator;

  String current;

  _Scanner(String expression) : tokenIterator = tokenize(expression).iterator {
    advance();
  }

  static List<String> tokenize(String expression) {
    if (!_testPattern.hasMatch(expression)) {
      throw new FormatException("Syntax error in '$expression'");
    }

    return _tokenPattern
        .allMatches(expression)
        .map((match) => match[0])
        .toList();
  }

  bool get hasMore => current != null;

  /// Returns `true` if the current token is an identifier.
  // All non-identifier tokens are one or two characters,
  // so a longer token must be an identifier.
  bool get isIdentifier =>
      current.length > 2 || _identifierPattern.hasMatch(current);

  /// If the current token is [token], consumes it and returns `true`.
  bool match(String token) {
    if (!hasMore || current != token) return false;

    advance();
    return true;
  }

  /// Consumes the current token and returns it.
  String advance() {
    var previous = current;
    current = tokenIterator.moveNext() ? tokenIterator.current : null;
    return previous;
  }
}
